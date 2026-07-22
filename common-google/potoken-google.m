// this stuff has things for auth.
#import "potoken-google.h"
#import "common/YoutubeClientType.h"
#import "common/jsanalyzer.h"

@implementation TRPOTokenSolver (Google)


// async
- (void)fetchJNNPOChallengeWithMethod:(NSString *)method 
                                body:(NSDictionary *)body 
                                callback:(void (^)(NSDictionary *response, NSError *error))callback 
                                 auth:(GTMOAuth2Authentication *)auth {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/api/jnn/v1/%@?noauth=1", method]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]]; // does requestKey ever change?
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"AIzaSyDyT5W0Jh49F30Pqqtyfdf7pDLFKLJoAnw" forHTTPHeaderField:@"x-goog-api-key"];
    [request setValue:@"grpc-web-javascript/0.1" forHTTPHeaderField:@"x-user-agent"];

    // GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    // [fetcher setAuthorizer:auth];
    // [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
            if (error) {
                NSLog(@"[TubeReplacer] POToken challenge fetch failed!");
                callback(nil, error);
                return;
            } 
            NSDictionary *json = [NSJSONSerialization
                        JSONObjectWithData:response
                        options:0
                        error:&error];
            if (error) {
                NSLog(@"[TubeReplacer] POToken challenge json decode failed!");
                callback(nil, error);
                return;
            }

            if (![json isKindOfClass:[NSDictionary class]]) {
                NSLog(@"[TubeReplacer] POToken challenge json not a dictionary");
                callback(nil, [NSError errorWithDomain:@"dev.preloading.tubereplacer.botguard" code:1 userInfo:nil]);
                return;
            }

            callback(json, nil);
    }];
}

- (void)fetchBotguardChallengeWithCallback:(void (^)(NSError *error))callback 
                                 auth:(GTMOAuth2Authentication *)auth 
                                 isStudio:(BOOL)isStudio {

    NSURL *url = [NSURL URLWithString:isStudio ? @"https://studio.youtube.com/youtubei/v1/att/get?alt=json" : @"https://www.youtube.com/youtubei/v1/att/get?alt=json"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    
    NSMutableDictionary *body = nil;

    if (isStudio) {
        body = [@{
            @"context":@{
                @"clientScreenNonce":@"]pasdiojggopi", // idk surely thats a good nonce???
                @"user": @{
                    @"delegationContext":@{
                        @"externalChannelId":[auth channelID],
                        @"roleType":@{
                            @"channelRoleType":@"CREATOR_CHANNEL_ROLE_TYPE_OWNER",
                        }
                    }
                },
                @"client":[[YoutubeClientType webStudioClient] makeContext][@"client"],
            },
            @"engagementType":@"ENGAGEMENT_TYPE_UNBOUND",
            @"ids":@[
                @{
                    @"externalChannelId":[auth channelID],
                }
            ]
        } mutableCopy];
    } else {
        body = [@{
            @"context":@{
                @"clientScreenNonce":@"]pasdiojggopi", // idk surely thats a good nonce???
                @"client":[[YoutubeClientType webMobileClient] makeContext][@"client"],
            },
            @"engagementType":@"ENGAGEMENT_TYPE_UNBOUND",
        } mutableCopy];
    }


    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];

    // GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    // if (auth != nil)
    //     [fetcher setAuthorizer:auth];

    NSLog(@"[TubeReplacer] beginning challenge fetch");
    // [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        NSLog(@"[TubeReplacer] challenge fetch done!");
        if (error) {
            NSLog(@"[TubeReplacer] Botguard challenge fetch failed!");
            callback(error);
            return;
        } 
        NSDictionary *json = [NSJSONSerialization
                    JSONObjectWithData:response
                    options:0
                    error:&error];
        if (error) {
            NSLog(@"[TubeReplacer] Botguard challenge json decode failed!");
            callback(error);
            return;
        }

        if (![json isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[TubeReplacer] Botguard challenge json not a dictionary");
            callback([NSError errorWithDomain:@"dev.preloading.tubereplacer.botguard" code:1 userInfo:nil]);
            return;
        }

        self.botguardChallenge = json[@"challenge"];
        self.program = json[@"bgChallenge"][@"program"];
        self.interpreterHash = json[@"bgChallenge"][@"interpreterHash"];
        self.globalName = json[@"bgChallenge"][@"globalName"];
        self.clientExperimentsStateBlob = json[@"bgChallenge"][@"clientExperimentsStateBlob"];

        NSString *vmURL = json[@"bgChallenge"][@"interpreterUrl"][@"privateDoNotAccessOrElseTrustedResourceUrlWrappedValue"];

        NSMutableURLRequest *requestVM = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https:%@", vmURL]]];

        GTMHTTPFetcher *fetcherVM = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:requestVM];
        [fetcherVM beginFetchWithCompletionHandler:^(NSData *response2, NSError *error2){
            if (error2) {
                NSLog(@"[TubeReplacer] Botguard challenge javascript fetch failed!");
                callback(error2);
                return;
            }
            self.safeScript = [[NSString alloc] initWithData:response2 encoding:NSUTF8StringEncoding];
            callback(nil);
        }];
    }];
}

- (void)fetchIntegretyTokenWithCallback:(void (^)(NSError *error))callback 
                                 auth:(GTMOAuth2Authentication *)auth 
                                 isStudio:(BOOL)isStudio {

    NSURL *url = [NSURL URLWithString:isStudio ? @"https://studio.youtube.com/youtubei/v1/att/get?alt=json" : @"https://www.youtube.com/youtubei/v1/att/get?alt=json"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    
    NSMutableDictionary *body = nil;

    if (isStudio) {
        body = [@{
            @"context":@{
                @"clientScreenNonce":@"]pasdiojggopi", // idk surely thats a good nonce???
                @"user": @{
                    @"delegationContext":@{
                        @"externalChannelId":[auth channelID],
                        @"roleType":@{
                            @"channelRoleType":@"CREATOR_CHANNEL_ROLE_TYPE_OWNER",
                        }
                    }
                },
                @"client":[[YoutubeClientType webStudioClient] makeContext][@"client"],
            },
            @"engagementType":@"ENGAGEMENT_TYPE_UNBOUND",
            @"ids":@[
                @{
                    @"externalChannelId":[auth channelID],
                }
            ]
        } mutableCopy];
    } else {
        body = [@{
            @"context":@{
                @"clientScreenNonce":@"]pasdiojggopi", // idk surely thats a good nonce???
                @"client":[[YoutubeClientType webMobileClient] makeContext][@"client"],
            },
            @"engagementType":@"ENGAGEMENT_TYPE_UNBOUND",
        } mutableCopy];
    }


    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];

    // GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    // if (auth != nil)
    //     [fetcher setAuthorizer:auth];

    NSLog(@"[TubeReplacer] beginning challenge fetch");
    // [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        NSLog(@"[TubeReplacer] challenge fetch done!");
        if (error) {
            NSLog(@"[TubeReplacer] Botguard challenge fetch failed!");
            callback(error);
            return;
        } 
        NSDictionary *json = [NSJSONSerialization
                    JSONObjectWithData:response
                    options:0
                    error:&error];
        if (error) {
            NSLog(@"[TubeReplacer] Botguard challenge json decode failed!");
            callback(error);
            return;
        }

        if (![json isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[TubeReplacer] Botguard challenge json not a dictionary");
            callback([NSError errorWithDomain:@"dev.preloading.tubereplacer.botguard" code:1 userInfo:nil]);
            return;
        }

        self.botguardChallenge = json[@"challenge"];
        self.program = json[@"bgChallenge"][@"program"];
        self.interpreterHash = json[@"bgChallenge"][@"interpreterHash"];
        self.globalName = json[@"bgChallenge"][@"globalName"];
        self.clientExperimentsStateBlob = json[@"bgChallenge"][@"clientExperimentsStateBlob"];

        NSString *vmURL = json[@"bgChallenge"][@"interpreterUrl"][@"privateDoNotAccessOrElseTrustedResourceUrlWrappedValue"];

        NSMutableURLRequest *requestVM = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https:%@", vmURL]]];

        GTMHTTPFetcher *fetcherVM = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:requestVM];
        [fetcherVM beginFetchWithCompletionHandler:^(NSData *response2, NSError *error2){
            if (error2) {
                NSLog(@"[TubeReplacer] Botguard challenge javascript fetch failed!");
                callback(error2);
                return;
            }
            self.safeScript = [[NSString alloc] initWithData:response2 encoding:NSUTF8StringEncoding];
            callback(nil);
        }];
    }];
}


-(void)setupPOTokenGenerationWithAuth:(id)authentication {
    NSLog(@"coldstart token -> %@", [TRPOTokenSolver generateColdStartTokenWithContent:@"hello world" clientState:1]);

    [self setupNSig];
    // [self fetchNSigFromServerWithCallback:^{}];

    [self fetchBotguardChallengeWithCallback:^(NSError *error) {
        // if (error) {
        //     NSLog(@"an error has occured in token fetching! %@", error);
        //     return;
        // }

        [self initEngineWithCallback:^{
                [self fetchNSigFromServerWithCallback:^{
                    // [self decipherUrl:@"https://rr5---sn-nx57ynz7.c.youtube.com/videoplayback?expire=1784628640&ei=QPFeapLpNOHHsfIPuZmK4Q4&ip=50.65.201.220&cp=UERUSVVHSDotT3g5allBUDhkZDh2dFNXSV9McXBCaE43aS1ENlVtUTZDYkJSZnBSM1pO&id=o-AF6w3FhoQ2OnYIZVPBnuEma1FW70lAXHczH0SRKiE119&itag=18&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&met=1784607040%2C&mh=SA&mm=32%2C26&mn=sn-nx57ynz7%2Csn-vgqsrnez&ms=su%2Conr&mv=u&mvi=5&pl=22&rms=su%2Csu&sc=yes&bui=AZFlqhNy_dN2opI8HaJnK3euYdhTo36c3j3JWWLGxQFjwz9jFizPzDfSTxMZv0Kn0PaiMU48jg&spc=SQ-ummOQRLl7JQcSWMehrIAi-Vs5bXjTnx0BDOAkQdyyy6XSyztv250&vprv=1&prv=1&svpuc=1&mime=video%2Fmp4&ns=Q6G_vReF4Qutw-hTWHZ0D7UW&rqh=1&gir=yes&clen=3750413&ratebypass=yes&dur=219.196&lmt=1779166548678640&mt=1784606738&fvip=2&fexp=51565116%2C51946838&c=MWEB&sefc=1&txp=6209224&n=aPvXTV_KFt-VTivh&sparams=expire%2Cei%2Cip%2Ccp%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Csiu%2Cbui%2Cspc%2Cvprv%2Cprv%2Csvpuc%2Cmime%2Cns%2Crqh%2Cgir%2Cclen%2Cratebypass%2Cdur%2Clmt&lsparams=met%2Cmh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Crms%2Csc"];
                }];
            // [self getPlayerJSWithCallback:^{
            //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //         NSLog(@"done getting player js");
            //         // TRJSAnalyzer *jsAnalyzer = [[TRJSAnalyzer alloc] init];
            //         // [jsAnalyzer parseScript:self.playerJS];
            //     });
            // }];

            [self startFetchingIntegrityTokenForPOTokenWithCallback:^(NSString *botguardResponse) {
                // - (void)fetchJNNPOChallengeWithMethod:(NSString *)method 
                //                 body:(NSDictionary *)body 
                //                 callback:(void (^)(NSDictionary *response, NSError *error))callback 
                //                  auth:(GTMOAuth2Authentication *)auth {
                [self fetchJNNPOChallengeWithMethod:@"GenerateIT" body:@{
                    @"request_key": @"O43z0dpjhgX20SCx4KAO", // copy paste broke, hope i typed this in right lol
                    @"botguard_response": botguardResponse
                } callback:^(NSDictionary *response, NSError *error) {
                    if (error) {
                        NSLog(@"An error occured while fetching the integrity token -> %@", error);
                        return;
                    }

                    if (response[@"integrityToken"]) {
                        self.integrityToken = response[@"integrityToken"];
                        self.integrityTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:[(NSNumber*)response[@"estimatedTtlSecs"] intValue]];
                        self.integrityTokenShouldProbablyRenew = [NSDate dateWithTimeIntervalSinceNow:[(NSNumber*)response[@"estimatedTtlSecs"] intValue]*0.8];
                        [self startPOTokenMinterWithIntegrityToken:self.integrityToken callback:^{
                            // [self mintPOTokenWithData:@"Hello World!" withCallback:^(NSString *poToken) {
                            //     NSLog(@"We now have a token! POToken => %@", poToken);
                            // }];
                        }];
                    } else {
                        NSLog(@"missing integrity token!!!");
                    }
                } auth:nil];
                NSLog(@"botguard response -> %@", botguardResponse);
            }];
        }];
        
    } auth:authentication isStudio:NO]; 
}

@end
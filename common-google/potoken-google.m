// this stuff has things for auth.
#import "potoken-google.h"
#import "common/YoutubeClientType.h"

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

    GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    [fetcher setAuthorizer:auth];
    [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
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

    if (isStudio && [auth channelID]) { // todo check if authenticated
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
                @"client":isStudio ? [[YoutubeClientType webStudioClient] makeContext][@"client"] : [[YoutubeClientType webMobileClient] makeContext][@"client"],
            },
            @"engagementType":@"ENGAGEMENT_TYPE_CREATOR_STUDIO_ACTION",
            @"ids":@[
                @{
                    @"externalChannelId":[auth channelID],
                }
            ]
        } mutableCopy ];
    }


    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];

    GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    [fetcher setAuthorizer:auth];
    [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
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
        self.program = json[@"botguardData"][@"program"];
        self.interpreterHash = json[@"botguardData"][@"interpreterHash"];
        self.globalName = json[@"botguardData"][@"globalName"];
        self.clientExperimentsStateBlob = json[@"botguardData"][@"clientExperimentsStateBlob"];

        NSString *vmURL = json[@"botguardData"][@"interpreterSafeUrl"][@"privateDoNotAccessOrElseTrustedResourceUrlWrappedValue"];

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

@end
// this stuff has things for auth.
#import "potoken-google.h"
#include <Foundation/NSJSONSerialization.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSData.h>
#include <Foundation/NSArray.h>
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

// https://github.com/LuanRT/BgUtils/pull/44/changes
- (void)fetchYTCfg:(void (^)(NSError *error))callback 
                                 auth:(GTMOAuth2Authentication *)auth 
                                 isStudio:(BOOL)isStudio {

    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setValue:@"hideBrowserUpgradeBox=true" forHTTPHeaderField:@"Cookie"];
    [request setValue:@"Mozilla/5.0 (X11; Linux x86_64; rv:153.0) Gecko/20100101 Firefox/153.0" forHTTPHeaderField:@"OV-User-Agent"];

    // GTMHTTPFetcher *fetcher1 = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    // [fetcher1 beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        if (error) {
            NSLog(@"[TubeReplacer] YtCfg fetch failed!");
            callback(error);
            return;
        } 

        // NSLog(@"resp -> %@", response);
        
        error = nil;
        NSRegularExpression *ytCfgRegex = [NSRegularExpression regularExpressionWithPattern:@"ytcfg\\.set\\((\\{.+?\\})\\);"
                                                                                options:NSRegularExpressionDotMatchesLineSeparators
                                                                                error:&error];

        NSRegularExpression *initalAttestationDataRegex = [NSRegularExpression regularExpressionWithPattern:@"window\\.ytAtN\\(\\s*(\\{[\\s\\S]*?\\})\\s*\\)"
                                                                                options:NSRegularExpressionDotMatchesLineSeparators
                                                                                error:&error];

        if (error) {
            NSLog(@"error -> %@", error);
            callback(error);
            return;
        } 

        NSString *respString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];


        // get YtCfg value
        NSArray *ytCfgMatches = [ytCfgRegex matchesInString:respString
                                        options:0
                                            range:NSMakeRange(0, [respString length])];

        if (ytCfgMatches.count > 0) {
            NSTextCheckingResult *match = ytCfgMatches.firstObject;
            NSRange group1Range = [match rangeAtIndex:1];
            self.ytCfg = [respString substringWithRange:group1Range];
        }

        // get attestation value
        NSArray *attestationDataMatches = [initalAttestationDataRegex matchesInString:respString
                                        options:0
                                            range:NSMakeRange(0, [respString length])];

        if (attestationDataMatches.count > 0) {
            // i think a bunch of this parsing was AI
            NSTextCheckingResult *match = attestationDataMatches.firstObject;
            NSRange group1Range = [match rangeAtIndex:1];

            NSMutableString *parseStep1 = [[respString substringWithRange:group1Range] mutableCopy];

            NSRegularExpression *hexEscapeRegex = [NSRegularExpression regularExpressionWithPattern:@"\\\\x([0-9a-fA-F]{2})" options:0 error:nil];

            NSArray *matches = [hexEscapeRegex matchesInString:parseStep1 options:0 range:NSMakeRange(0, parseStep1.length)];
            for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
                NSString *hex = [parseStep1 substringWithRange:[match rangeAtIndex:1]];
                unsigned int value = 0;
                [[NSScanner scannerWithString:hex] scanHexInt:&value];
                NSString *replacement = [NSString stringWithFormat:@"%C", (unichar)value];
                [parseStep1 replaceCharactersInRange:[match rangeAtIndex:0] withString:replacement];
            }

            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@",\\s*([}\\]])"
                                                                        options:0
                                                                          error:nil];
                                                                          
            NSString *parseStep2 = [regex stringByReplacingMatchesInString:parseStep1
                                                                options:0
                                                                range:NSMakeRange(0, parseStep1.length)
                                                            withTemplate:@"$1"];

            NSScanner *scanner = [NSScanner scannerWithString:parseStep2];
            scanner.charactersToBeSkipped = nil;
            NSMutableString *parseStep3 = [NSMutableString string];
            NSUInteger length = parseStep2.length;

            while (![scanner isAtEnd]) {
                NSUInteger loc = scanner.scanLocation;
                unichar c = [parseStep2 characterAtIndex:loc];

                if (c == '\'') {
                    NSUInteger i = loc + 1;
                    NSMutableString *content = [NSMutableString string];

                    while (i < length) {
                        unichar ch = [parseStep2 characterAtIndex:i];

                        if (ch == '\\' && i + 1 < length) {
                            unichar next = [parseStep2 characterAtIndex:i + 1];
                            if (next == '\'') {
                                [content appendString:@"'"];
                                i += 2;
                                continue;
                            } else {
                                [content appendFormat:@"%C%C", ch, next];
                                i += 2;
                                continue;
                            }
                        } else if (ch == '"') {
                            [content appendString:@"\\\""];
                            i += 1;
                            continue;
                        } else if (ch == '\'') {
                            break;
                        } else {
                            [content appendFormat:@"%C", ch];
                            i += 1;
                        }
                    }

                    [parseStep3 appendString:@"\""];
                    [parseStep3 appendString:content];
                    [parseStep3 appendString:@"\""];

                    scanner.scanLocation = (i < length) ? i + 1 : length;
                } else {
                    [parseStep3 appendFormat:@"%C", c];
                    scanner.scanLocation = loc + 1;
                }
            }

            // end of ai code

            NSDictionary *attestationData = [NSJSONSerialization JSONObjectWithData:[parseStep3 dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[attestationData[@"R"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

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

        }        
    }];
}


-(void)setupPOTokenGenerationWithAuth:(id)authentication {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"StreamType"] isEqualToString:@"web"] || [preferences[@"StreamType"] isEqualToString:@"mweb"] || preferences[@"StreamType"] == nil) {
        [self setupNSig]; // this should be decently fast, and also threaded-ish that we shouldn't need to worry about how long this takes for the crucial webview to start
        [self initWebViewWithCallback:^{
            [self fetchYTCfg:^(NSError *error) {
                if (error) {
                    NSLog(@"an error has occured fetching the botguard challenge! %@", error);
                    return;
                }

                [self startBotguardVM:^{
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
                            @"request_key": @"O43z0dpjhgX20SCx4KAo", // copy paste broke, hope i typed this in right lol
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
                                [self startPOTokenMinterWithIntegrityToken:self.integrityToken callback:^{}];
                            } else {
                                NSLog(@"missing integrity token!!!");
                            }
                        } auth:nil];
                        NSLog(@"botguard response -> %@", botguardResponse);
                    }];
                }];
            } auth:nil isStudio:NO];            
        }];
    };
}

@end
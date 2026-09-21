// this stuff has things for auth.
#import "challengesolver.h"
#import "challengesolver-webview.h"
#import "challengesolver-nsig.h"
#import "challengesolver-requests.h"
#import "challengesolver-potokens.h"

@implementation TRPOTokenSolver (Manager)

-(void)setupPOTokenGenerationWithAuth:(id)authentication {
    self.isPOTokenEngineStarting = YES;
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"StreamType"] isEqualToString:@"web"] || [preferences[@"StreamType"] isEqualToString:@"mweb"] || preferences[@"StreamType"] == nil) {
        [self initWebViewWithCallback:^{
            if (!self.isNSigReady)
                [self setupNSig]; // this should be decently fast, and also threaded-ish that we shouldn't need to worry about how long this takes for the crucial webview to start
            [self fetchYTCfg:^(NSError *error) {
                if (error) {
                    NSLog(@"an error has occured fetching the botguard challenge! %@", error);
                    // self.errorAlert(@"failed to fetch botguard challenge, videos might not play.");
                    self.isPOTokenEngineStarting = NO;
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
                                // self.errorAlert(@"an error occured while fetching integrity token, videos might not play.");
                                self.isPOTokenEngineStarting = NO;
                                return;
                            }

                            if (response[@"integrityToken"]) {
                                self.integrityToken = response[@"integrityToken"];
                                self.integrityTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:[(NSNumber*)response[@"estimatedTtlSecs"] intValue]];
                                self.integrityTokenShouldProbablyRenew = [NSDate dateWithTimeIntervalSinceNow:[(NSNumber*)response[@"estimatedTtlSecs"] intValue]*0.8];
                                [self startPOTokenMinterWithIntegrityToken:self.integrityToken callback:^{}];
                            } else {
                                self.errorAlert(@"botguard challenge failed! videos might not play.");
                                NSLog(@"missing integrity token!!!");
                            }
                        } auth:nil];
                    }];
                }];
            } auth:nil isStudio:NO];            
        }];
    };
}

@end
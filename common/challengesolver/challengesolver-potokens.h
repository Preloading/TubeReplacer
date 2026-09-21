#import "challengesolver.h"

@interface TRPOTokenSolver (POTokens)
// potokens
+(NSString*)generateColdStartTokenWithContent:(NSString*)contentBinding clientState:(int)clientState;
-(NSString*)mintPOTokenWithData:(NSString*)data;
-(NSString*)mintPOTokenOrColdStart:(NSString*)contentBinding;

// potoken internal
-(void)descrambleChallenge:(NSString*)scrambledChallenge;
-(void)startBotguardVM:(void(^)())callback;
-(void)startPOTokenMinterWithIntegrityToken:(NSString*)integrityToken callback:(void (^)())callback;
-(void)recievedBotguardResponse:(NSString*)result webView:(UIWebView*)webView;
-(void)startFetchingIntegrityTokenForPOTokenWithCallback:(void (^)(NSString *))callback;
@end
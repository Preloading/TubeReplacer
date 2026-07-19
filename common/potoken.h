#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// This is a small POToken solver for YouTube, so that we can hopefully do some more things.
// This will probably run blocking
// Huge props to https://github.com/LuanRT/BgUtils as a reference to this :D
@interface TRPOTokenSolver : NSObject <UIWebViewDelegate>
// for solving integrety token
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *safeScript;
@property (nonatomic, strong) NSString *resourceURL;
@property (nonatomic, strong) NSString *interpreterHash;
@property (nonatomic, strong) NSString *program;
@property (nonatomic, strong) NSString *globalName;
@property (nonatomic, strong) NSString *clientExperimentsStateBlob;
@property (nonatomic, strong) UIWebView *webView;

// integrityToken
@property (nonatomic, strong) NSString *integrityToken;
@property (nonatomic, strong) NSDate *integrityTokenExpiration;
@property (nonatomic, strong) NSDate *integrityTokenShouldProbablyRenew;

// poToken
@property (nonatomic, strong) NSString *cachedPOToken;
// botguard
@property (nonatomic, strong) NSString *botguardChallenge;
@property (nonatomic, strong) NSString *botguardResponse;

// callbacks
@property (nonatomic, copy) void (^vmReadyCallback)();
@property (nonatomic, copy) void (^poGenReady)();
@property (nonatomic, copy) void (^botguardResponseCallback)(NSString *);
@property (atomic, strong) NSMutableDictionary *poTokenCallbacks;


// states
@property (atomic, assign) BOOL isWebViewReady;
@property (atomic, assign) BOOL isVMInitalized;


-(NSDictionary*)fetchPOJNNChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body;
// -(BOOL)fetchStudioIntegrityChallenge;
-(void)descrambleChallenge:(NSString*)scrambledChallenge;
-(void)startFetchingChallengeResponseWithCallback:(void (^)(NSString *))callback;
-(void)startFetchingIntegrityTokenForPOTokenWithCallback:(void (^)(NSString *))callback;
-(void)startPOTokenMinterWithIntegrityToken:(NSString*)integrityToken callback:(void (^)())callback;
-(void)initEngineWithCallback:(void(^)())callback;
+(NSString*)generateColdStartTokenWithContent:(NSString*)contentBinding clientState:(int)clientState;
-(void)mintPOTokenWithData:(NSString*)data withCallback:(void (^)(NSString *))callback;
@end
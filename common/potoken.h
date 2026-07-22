#include <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// This does both N/Sig & POToken solving.
// Huge props to https://github.com/LuanRT/BgUtils as a reference to this :D
@interface TRPOTokenSolver : NSObject <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;

// for solving integrety token
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *safeScript;
@property (nonatomic, strong) NSString *resourceURL;
@property (nonatomic, strong) NSString *interpreterHash;
@property (nonatomic, strong) NSString *program;
@property (nonatomic, strong) NSString *globalName;
@property (nonatomic, strong) NSString *clientExperimentsStateBlob;

// integrityToken
@property (nonatomic, strong) NSString *integrityToken;
@property (nonatomic, strong) NSDate *integrityTokenExpiration;
@property (nonatomic, strong) NSDate *integrityTokenShouldProbablyRenew;

// botguard
@property (nonatomic, strong) NSString *botguardChallenge;
@property (nonatomic, strong) NSString *botguardResponse;

// callbacks
@property (nonatomic, copy) void (^vmReadyCallback)();
@property (nonatomic, copy) void (^poGenReady)();
@property (nonatomic, copy) void (^botguardResponseCallback)(NSString *);
@property (nonatomic, strong) NSMutableDictionary *poTokenCallbacks;

// player
// @property (nonatomic, strong) NSString *playerId;
// @property (nonatomic, strong) NSData *playerJS;

// nsig
@property (atomic, strong) NSString *nsigJS;
@property (atomic, assign) int nsigSignatureTimestamp;

// states
@property (atomic, assign) BOOL isWebViewReady;
@property (atomic, assign) BOOL isVMInitalized;
@property (atomic, assign) BOOL isNSigReady;

+(TRPOTokenSolver *)sharedInstance;

-(NSDictionary*)fetchPOJNNChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body;
// -(BOOL)fetchStudioIntegrityChallenge;
-(void)descrambleChallenge:(NSString*)scrambledChallenge;
-(void)startFetchingChallengeResponseWithCallback:(void (^)(NSString *))callback;
-(void)startFetchingIntegrityTokenForPOTokenWithCallback:(void (^)(NSString *))callback;
-(void)startPOTokenMinterWithIntegrityToken:(NSString*)integrityToken callback:(void (^)())callback;
-(void)initEngineWithCallback:(void(^)())callback;
+(NSString*)generateColdStartTokenWithContent:(NSString*)contentBinding clientState:(int)clientState;
-(void)mintPOTokenWithData:(NSString*)data withCallback:(void (^)(NSString *))callback;

// n/sig
// -(void)getPlayerJSWithCallback:(void(^)())callback;
-(void)setupNSig;
-(void)fetchNSigFromServerWithCallback:(void(^)())callback;
-(NSString*)decipherUrl:(NSString*)url signatureCipher:(NSString*)signatureCipher;
@end

@interface TRPOTokenOutput : NSObject
@property (nonatomic, strong) NSString *poToken;
@property (nonatomic, strong) NSString *coldstartToken;
-(instancetype)initWithPoToken:(NSString*)poToken coldStartToken:(NSString*)coldStart;
@end
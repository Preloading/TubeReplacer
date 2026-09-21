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

@property (nonatomic, strong) NSString *ytCfg;

// botguard
@property (nonatomic, strong) NSString *botguardChallenge;
@property (nonatomic, strong) NSString *botguardResponse;

// callbacks
@property (nonatomic, copy) void (^vmReadyCallback)();
@property (nonatomic, copy) void (^poGenReady)();
@property (nonatomic, copy) void (^botguardResponseCallback)(NSString *);
@property (nonatomic, copy) void (^webviewReadyCallback)();
@property (nonatomic, copy) void (^errorAlert)(NSString *);
@property (nonatomic, copy) void (^retryStartup)();


// player
// @property (nonatomic, strong) NSString *playerId;
// @property (nonatomic, strong) NSData *playerJS;

// nsig
@property (atomic, strong) NSString *nsigJS;
@property (atomic, assign) int nsigSignatureTimestamp;

// states
@property (atomic, assign) BOOL isPOTokenEngineStarting;
@property (atomic, assign) BOOL isWebViewReady;
@property (atomic, assign) BOOL isVMInitalized;
@property (atomic, assign) BOOL isReadyToMintTokens;
@property (atomic, assign) BOOL isNSigReady;
@property (atomic, assign) BOOL isStartingPOTokenGen;

// general
+(TRPOTokenSolver *)sharedInstance;
@end
#import <Foundation/Foundation.h>
#import "../lib/quickjs.h"

// This is a small POToken solver for YouTube, so that we can hopefully do some more things.
// This will probably run blocking
// Huge props to https://github.com/LuanRT/BgUtils as a reference to this :D
@interface TRPOTokenSolver : NSObject
// for solving integrety token
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *safeScript;
@property (nonatomic, strong) NSString *resourceURL;
@property (nonatomic, strong) NSString *interpreterHash;
@property (nonatomic, strong) NSString *program;
@property (nonatomic, strong) NSString *globalName;
@property (nonatomic, strong) NSString *clientExperimentsStateBlob;
@property (nonatomic, assign) JSRuntime *jsRuntime;
@property (nonatomic, assign) JSContext *jsCtx;

// integrityToken
@property (nonatomic, strong) NSString *integretyToken;
@property (nonatomic, strong) NSDate *integretyTokenExpiration;
@property (nonatomic, strong) NSDate *integretyTokenShouldProbablyRenew;

-(NSDictionary*)fetchChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body;
-(void)descrambleChallenge:(NSString*)scrambledChallenge;
-(void)obtainPOToken; // temp
@end
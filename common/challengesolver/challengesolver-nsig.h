#import "challengesolver.h"

@interface TRPOTokenSolver (NSig)
-(void)setupNSig;
-(void)fetchNSigFromServerWithCallback:(void(^)())callback;
-(NSString*)decipherUrl:(NSString*)url signatureCipher:(NSString*)signatureCipher;
@end
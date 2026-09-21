#import "challengesolver.h"

@interface TRPOTokenSolver (Network)
-(NSDictionary*)fetchPOJNNChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body;
- (void)fetchJNNPOChallengeWithMethod:(NSString *)method 
                                body:(NSDictionary *)body 
                                callback:(void (^)(NSDictionary *response, NSError *error))callback 
                                 auth:(id)auth;
- (void)fetchYTCfg:(void (^)(NSError *error))callback 
                                 auth:(id)auth 
                                 isStudio:(BOOL)isStudio;
@end
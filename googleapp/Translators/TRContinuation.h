#include <Foundation/Foundation.h>


@interface TRContinuation : NSObject
@property (nonatomic, strong) NSString *token;
+(TRContinuation*)initWithToken:(NSString*)token;
@end
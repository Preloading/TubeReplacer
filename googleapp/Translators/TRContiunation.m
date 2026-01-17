#include <Foundation/Foundation.h>
#include "TRContinuation.h"

@implementation TRContinuation
+(TRContinuation*)initWithToken:(NSString*)token {
    TRContinuation *continuation = [TRContinuation alloc];
    [continuation setToken:token];
    return continuation;
}
@end
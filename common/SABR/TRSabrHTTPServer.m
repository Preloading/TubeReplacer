#include "TRSabrHTTPServer.h"
#import "lib/cocoahttpserver/AsyncSocket.h"

@implementation TRSabrHTTPServer

-(BOOL)isSocketActive {
    return [asyncSocket isConnected];
}
@end
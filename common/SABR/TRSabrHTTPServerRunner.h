// memory management amiright?
// this is here since running the thread for the HTTPServer retains the TRSabrStream, which prevents it from being deallocated ever.
// Shoving it into a runner will allow me to be able to both deallocate TRSabrStream and stop this.
#import "common/SABR/TRSabrHTTPServer.h"
#import <Foundation/Foundation.h>

@interface TRSabrHTTPServerRunner : NSObject {
    NSThread *thread;
    BOOL isHTTPServerReady;
    BOOL isStopping;
}
@property (nonatomic, strong) TRSabrHTTPServer *httpServer;
@property (nonatomic, assign) uint16_t port;

-(void)startWithStream:(id)stream;
-(void)stop;
// -(void)restart;

@end
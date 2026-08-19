#import "lib/cocoahttpserver/HTTPServer.h"
@class TRSabrStream;

@interface TRSabrHTTPServer : HTTPServer
@property (nonatomic, assign) TRSabrStream *stream;

-(BOOL)isSocketActive;
@end
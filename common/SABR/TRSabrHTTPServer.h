#import "lib/cocoahttpserver/HTTPServer.h"
@class TRSabrStream;

@interface TRSabrHTTPServer : TRHTTPServer
@property (nonatomic, assign) TRSabrStream *stream;
@end
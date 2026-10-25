#import "TRSabrHTTPServerRunner.h"
#include "common/SABR/TRSabrHTTPConnection.h"

@implementation TRSabrHTTPServerRunner

-(void)stopHTTPServerOnThread {
    self.httpServer.stream = nil;
    [self.httpServer stop];
    self.httpServer = nil;

    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)stop {
    if (!self.httpServer || !thread || isStopping) return;
    isStopping = YES;

    [self performSelector:@selector(stopHTTPServerOnThread)
            onThread:thread 
            withObject:nil 
            waitUntilDone:YES];

    // [thread release];

    thread = nil;
    isStopping = NO;
}

-(void)startWebServerOnThread {
	NSError *error;
	BOOL success = [self.httpServer start:&error];
	self.port = self.httpServer.port;

	if(!success)
	{
		NSLog(@"Error starting HTTP Server: %@", error);
        isHTTPServerReady = YES;
	}

    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    isHTTPServerReady = YES;
    while (self.httpServer && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        if (!self.httpServer) break;
    }

    // NSLog(@"http server at -> http://%@:%hu/", [self.httpServer [self.httpServer port]);
}

- (void)startWithStream:(id)stream {
    isStopping = NO;
    isHTTPServerReady = NO;
    self.httpServer = [[[TRSabrHTTPServer alloc] init] autorelease];
	
    self.httpServer.stream = stream;
	[self.httpServer setConnectionClass:[TRSabrHTTPConnection class]];
    
    if (self.port != 0) {
        [self.httpServer setPort:self.port];
    }

    thread = [[NSThread alloc] initWithTarget:self selector:@selector(startWebServerOnThread) object:nil];
    [thread start];
    while (!isHTTPServerReady) { // block to prevent handing URL before we have a working HTTP server
        ;;
    }
}

// -(void)restart {
//     [self stop];
//     [self start];
// }

-(void)dealloc {
    [self stop];
    [super dealloc];
}

@end
#include "TRChallengeSolverPolyfillProtocol.h"

@implementation TRChallengeSolverPolyfillProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *path = request.URL.path;

    if ([path isEqualToString:@"/ytscframe"]) {
        return YES;
    }

    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSString *path = @"/Library/Application Support/TubeReplacer/ytscframe.html";

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];

    if (!data || error) {
        NSLog(@"[TRURLProtocol] Failed to load file: %@", error);
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    NSURLResponse *response =
        [[NSURLResponse alloc] initWithURL:self.request.URL
                                   MIMEType:@"text/html"
                      expectedContentLength:data.length
                           textEncodingName:@"utf-8"];

    [self.client URLProtocol:self didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [response release];

    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}

@end
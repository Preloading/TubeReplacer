#include "TRSabrRequest.h"
#include "common/SABR/TRUmpPart.h"
#include "common/SABR/TRUmpReader.h"
#include <Foundation/NSRange.h>

// it's done this way as SABR responses can be quite big, which 
// can be bad if your on a slow cellular connection. This allows
// us to parse the recieved SABR data while it's not quite done
// recieving all segments. Also allows for a potentially faster
// playback start.
@implementation TRSabrRequest

- (void)startRequestWithURL:(NSURL*)requestURL body:(NSData*)body auth:(GTMOAuth2Authentication*)auth 
        partCallback:(void (^)(TRUmpPart *))partHandler completionCallback:(void (^)(NSError*))setCompletionCallback {

    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:requestURL] autorelease];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-protobuf" forHTTPHeaderField:@"content-type"];
    [request setValue:@"identity" forHTTPHeaderField:@"accept-encoding"];
    [request setValue:@"application/vnd.yt-ump" forHTTPHeaderField:@"accept"];
    [request setTimeoutInterval:15.0];
    
    if (auth != nil)
        [auth authorizeNSRequest:&request];
        


    NSURLConnection *connection = [[NSURLConnection alloc]
                                    initWithRequest:request delegate:self];

    sabrBuffer = [[NSMutableData alloc] init];
    partCallback = [partHandler copy];
    completionCallback = [setCompletionCallback copy];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    [sabrBuffer setLength:0];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {
    [sabrBuffer appendData:data];
    NSUInteger readBytes = [TRUmpReader read:sabrBuffer handlePartWith:partCallback];
    if (readBytes != 0)
        [sabrBuffer replaceBytesInRange:NSMakeRange(0, readBytes) withBytes:NULL length:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    completionCallback(nil);
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    completionCallback(error);
}

-(void)dealloc {
    [sabrBuffer release];
    [super dealloc];
}

@end
#import <Foundation/Foundation.h>
#import "appheaders.h"

%hook YTSearchRequest

-(void)searchForVideosWithFeedURLBase:(NSString*)urlBase
    startingAtIndex:(int)startingAtIndex
    maxResults:(int)maxResults
    withTimeQualifier:(id)withTimeQualifier
    withFormatFilter:(BOOL)withFormatFilter
    authenticationRequired:(BOOL)authenticationRequired
    withDelegate:(id)delegate
{
    NSLog(@"search request called!");

    YTMutableURLRequest *request = [%c(YTMutableURLRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] cachePolicy:NO timeoutInterval:1077805056];

    [request setHTTPMethod:@"POST"];

    [self loadRequest:request withDelegate:delegate accountAuthRequired:authenticationRequired];

    // return %orig;
}


%end

// -[YTFeedRequest ]

// %hook YTFeedRequest

// -(id)

// %end
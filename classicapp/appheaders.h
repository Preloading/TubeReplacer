#import <Foundation/Foundation.h>

@interface YTMutableURLRequest : NSMutableURLRequest
+(id)requestWithURL:(NSURL*)url cachePolicy:(BOOL)cachePolicy timeoutInterval:(int)timeout;
@end

@interface YTFeedRequest : NSObject
-(void)loadRequest:(YTMutableURLRequest*)request withDelegate:(id)delegate accountAuthRequired:(BOOL)accountAuthRequired;
@end

@interface YTSearchRequest : YTFeedRequest

@end
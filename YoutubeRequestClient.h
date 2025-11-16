#import <Foundation/Foundation.h>

@interface YoutubeRequestClient : NSObject
+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params;
@end

NSDate *YTTimeAgoToDate(NSString *timeAgo);
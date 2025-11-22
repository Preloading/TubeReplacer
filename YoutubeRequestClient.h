#import <Foundation/Foundation.h>

@interface YoutubeRequestClient : NSObject
+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params;
+(NSData*)getVideoWithID:(NSString*)videoId;
@end

NSDate *YTTimeAgoToDate(NSString *timeAgo);
NSDate *RFC3339toNSDate(NSString *rfc3339DateTimeString);
#import <Foundation/Foundation.h>
#include "YoutubeClientType.h"

@interface YoutubeRequestClient : NSObject
+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params;
+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params withClient:(YoutubeClientType*)client;
+(NSData*)searchBody:(NSString*)query sortBy:(NSString*)sortBy uploadDateFilter:(NSString*)uploadDateFilter duration:(NSString*)duration hasCC:(BOOL)hasCC withClient:(YoutubeClientType*)client isChannelLookup:(BOOL)isChannelLookup;
+(NSData*)clientOnlyWithClient:(YoutubeClientType*)client;
+(NSData*)getVideoWithID:(NSString*)videoId;
@end

NSDate *YTTimeAgoToDate(NSString *timeAgo);
NSDate *RFC3339toNSDate(NSString *rfc3339DateTimeString);
long YTTextToNumber(NSString *string);
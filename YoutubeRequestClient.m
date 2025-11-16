#import "YoutubeRequestClient.h"
#include "YoutubeClientType.h"

@implementation YoutubeRequestClient

+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[[YoutubeClientType webClient] makeContext] forKey:@"context"];
    [body setObject:browseId forKey:@"browse_id"];
    if (params) {
        [body setObject:params forKey:@"params"];
    }


    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
    
    
}

@end

// chatgpt :( dates sux
NSDate *YTTimeAgoToDate(NSString *timeAgo) {
    NSLog(@"time ago is %@", timeAgo);
    // Lowercase for easier parsing
    NSString *lower = [[timeAgo lowercaseString] stringByReplacingOccurrencesOfString:@"streamed " withString:@""];

    // Extract the number
    NSScanner *scanner = [NSScanner scannerWithString:lower];
    NSInteger value = 0;
    [scanner scanInteger:&value];

    // Extract the unit
    NSArray *parts = [lower componentsSeparatedByString:@" "];
    if (parts.count < 2) return nil;

    NSString *unit = parts[1]; // hour(s), day(s), week(s), etc.

    // Current date
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *offset = [[NSDateComponents alloc] init];

    // Match unit
    if ([unit hasPrefix:@"second"]) {
        offset.second = -value;
    } else if ([unit hasPrefix:@"minute"]) {
        offset.minute = -value;
    } else if ([unit hasPrefix:@"hour"]) {
        offset.hour = -value;
    } else if ([unit hasPrefix:@"day"]) {
        offset.day = -value;
    } else if ([unit hasPrefix:@"week"]) {
        offset.weekOfYear = -value;
    } else if ([unit hasPrefix:@"month"]) {
        offset.month = -value;
    } else if ([unit hasPrefix:@"year"]) {
        offset.year = -value;
    } else {
        return nil; // unknown format
    }

    return [cal dateByAddingComponents:offset toDate:now options:0];
}

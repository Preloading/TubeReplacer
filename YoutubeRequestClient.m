#import "YoutubeRequestClient.h"
#import "Protobuf.h"
#import "base64/NSData+Base64.h"

@implementation YoutubeRequestClient

+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params {
    return [YoutubeRequestClient browseBody:browseId params:params withClient:[YoutubeClientType webMobileClient]];
}

+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params withClient:(YoutubeClientType*)client {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];
    [body setObject:browseId forKey:@"browseId"];
    if (params) {
        [body setObject:params forKey:@"params"];
    }


    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}


+(NSData*)getVideoWithID:(NSString*)videoId {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[[YoutubeClientType androidClient] makeContext] forKey:@"context"];
    [body setObject:videoId forKey:@"videoId"];
    // [body setObject:@{
    //     @"video_id":videoId
    //     @"video"
    // } forKey:@"watch_endpoint"];


    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)getVideoWithID:(NSString*)videoId withClient:(YoutubeClientType*)client  {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];
    [body setObject:videoId forKey:@"videoId"];
    // [body setObject:@{
    //     @"video_id":videoId
    //     @"video"
    // } forKey:@"watch_endpoint"];


    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)searchBody:(NSString*)query sortBy:(NSString*)sortBy uploadDateFilter:(NSString*)uploadDateFilter duration:(NSString*)duration hasCC:(BOOL)hasCC withClient:(YoutubeClientType*)client isChannelLookup:(BOOL)isChannelLookup {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];
    [body setObject:query forKey:@"query"];
    if (isChannelLookup) {
        [body setObject:@"EgIQAg%3D%3D" forKey:@"params"]; // filters for channels only
    } else {
        [body setObject:@"EgIQAQ%3D%3D" forKey:@"params"]; // filters for videos only
    }
    

    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)commentsBody:(NSString*)videoId sortBy:(NSString*)sortBy withClient:(YoutubeClientType*)client {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];

    // top, newest
    uint64_t sortByVal = 0;
    if ([sortBy isEqualToString:@"newest"]) {
        sortByVal = 1;
    }

    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    [enc writeMessageField:2 usingBlock:^(ProtobufEncoder *a){
        [a writeStringField:2 string:videoId];
    }];
    [enc writeUInt64Field:3 value:6];
    [enc writeMessageField:6 usingBlock:^(ProtobufEncoder *a){
        // [a writeStringField:1 string:@""]; // cursor
        [a writeMessageField:4 usingBlock:^(ProtobufEncoder *b){
            [b writeStringField:4 string:videoId];
            [b writeUInt64Field:6 value:sortByVal];
        }];
        [a writeUInt64Field:6 value:1];
        [a writeStringField:8 string:@"engagement-panel-comments-section"];
        
    }];

    NSData *out = [enc dataRepresentation];
    NSString *b64 = [out base64EncodedString];
    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)b64, NULL, CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
    NSString *urlEncodedB64 = (NSString *)escaped;

    [body setObject:urlEncodedB64 forKey:@"continuation"];
    
    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)addComment:(NSString*)videoId commentText:(NSString*)commentText withClient:(YoutubeClientType*)client {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];
    [body setObject:commentText forKey:@"commentText"];

    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    [enc writeStringField:2 string:videoId];
    NSData *out = [enc dataRepresentation];
    NSString *b64 = [out base64EncodedString];
    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)b64, NULL, CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
    NSString *urlEncodedB64 = (NSString *)escaped;

    [body setObject:urlEncodedB64 forKey:@"createCommentParams"];
    
    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)clientOnlyWithClient:(YoutubeClientType*)client {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];

    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

+(NSData*)subscribeToChannelId:(NSString*)channelId withClient:(YoutubeClientType*)client {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];

    [body setObject:[client makeContext] forKey:@"context"];
    [body setObject:@"EgIIAxgAIgtxQ0dUX0NLR2dGRQ%3D%3D" forKey:@"params"];
    [body setObject:@[channelId] forKey:@"channelIds"];

    return [NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; // TODO: NSJSON will never run on iOS 4 and below, we should switch this to SBJson
}

@end

NSDate *RFC3339toNSDate(NSString *rfc3339DateTimeString) {
    /*
      Returns a user-visible date time string that corresponds to the specified
      RFC 3339 date time strings, handling both UTC (Z) and timezone offsets.
     */
 
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
 
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
 
    // Convert the RFC 3339 date time string to an NSDate.
    return [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
}

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

long YTTextToNumber(NSString *string) {
    if (!string || string.length == 0) return 0;
    
    // Remove common suffixes like "subscribers", "views", etc.
    NSString *cleaned = [[[string lowercaseString] 
                          stringByReplacingOccurrencesOfString:@" subscribers" withString:@""]
                          stringByReplacingOccurrencesOfString:@" videos" withString:@""];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@" views" withString:@""];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@"," withString:@""];
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Extract the numeric part and multiplier
    NSScanner *scanner = [NSScanner scannerWithString:cleaned];
    double value = 0;
    [scanner scanDouble:&value];
    
    // Check for multiplier suffix (K, M, B)
    NSString *remainder = [cleaned substringFromIndex:[scanner scanLocation]];
    remainder = [remainder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([remainder hasPrefix:@"k"]) {
        value *= 1000;
    } else if ([remainder hasPrefix:@"m"]) {
        value *= 1000000;
    } else if ([remainder hasPrefix:@"b"]) {
        value *= 1000000000;
    }
    
    return (long)value;
}
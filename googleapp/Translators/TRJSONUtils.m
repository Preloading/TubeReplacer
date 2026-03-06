// TRJSONUtils.m
// TubeReplacer
//
// Utilities duh

#import "TRJSONUtils.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation TRJSONUtils

#pragma mark - Safe Keypath Access

+ (id)valueFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    if (!json || ![json isKindOfClass:[NSDictionary class]] || !keyPath) {
        return nil;
    }
    
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    id current = json;
    
    for (NSString *key in keys) {
        if ([current isKindOfClass:[NSDictionary class]]) {
            current = [current objectForKey:key];
        } else {
            return nil;
        }
        
        if (!current) {
            return nil;
        }
    }
    
    return current;
}

+ (id)valueFromJSON:(NSDictionary *)json keyPathWithArrays:(NSString *)keyPath {
    if (!json || ![json isKindOfClass:[NSDictionary class]] || !keyPath) {
        return nil;
    }
    
    id current = json;
    NSScanner *scanner = [NSScanner scannerWithString:keyPath];
    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *key = nil;
        
        // Scan until we hit a dot, bracket, or end
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@".["] intoString:&key];
        
        if (key && [key length] > 0) {
            if ([current isKindOfClass:[NSDictionary class]]) {
                current = [current objectForKey:key];
            } else {
                return nil;
            }
        }
        
        if (!current) {
            return nil;
        }
        
        // Check for array access [n]
        if ([scanner scanString:@"[" intoString:NULL]) {
            NSInteger index = 0;
            if ([scanner scanInteger:&index]) {
                if ([current isKindOfClass:[NSArray class]]) {
                    NSArray *arr = (NSArray *)current;
                    if (index >= 0 && index < [arr count]) {
                        current = [arr objectAtIndex:index];
                    } else {
                        return nil;
                    }
                } else {
                    return nil;
                }
            }
            [scanner scanString:@"]" intoString:NULL];
        }
        
        // Skip the dot separator
        [scanner scanString:@"." intoString:NULL];
    }
    
    return current;
}

#pragma mark - Type-Safe Accessors

+ (NSString *)stringFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    id value = [self valueFromJSON:json keyPathWithArrays:keyPath];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

+ (NSArray *)arrayFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    id value = [self valueFromJSON:json keyPathWithArrays:keyPath];
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

+ (NSDictionary *)dictFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    id value = [self valueFromJSON:json keyPathWithArrays:keyPath];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

+ (uint64_t)intFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    id value = [self valueFromJSON:json keyPathWithArrays:keyPath];
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value longLongValue];
    }
    return 0;
}

+ (BOOL)boolFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath {
    id value = [self valueFromJSON:json keyPathWithArrays:keyPath];
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return NO;
}

#pragma mark - Parsing Helpers

+ (NSDate *)dateFromRFC3339:(NSString *)string {
    if (!string || ![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [formatter setLocale:enUSPOSIXLocale];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate *result = [formatter dateFromString:string];
    [formatter release];
    [enUSPOSIXLocale release];
    
    return result;
}

+ (NSDate *)dateFromISO8601:(NSString *)string {
    if (!string || ![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    [formatter setLocale:enUSPOSIXLocale];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *result = [formatter dateFromString:string];
    [formatter release];
    [enUSPOSIXLocale release];
    
    return result;
}

+ (NSDate *)dateFromTimeAgo:(NSString *)string {
    if (!string || ![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSString *lower = [[[[string lowercaseString] stringByReplacingOccurrencesOfString:@"streamed live " withString:@""] stringByReplacingOccurrencesOfString:@"streamed " withString:@""] stringByReplacingOccurrencesOfString:@" ago" withString:@""];
    NSLog(@"lower -> %@", lower);
    NSScanner *scanner = [NSScanner scannerWithString:lower];
    NSInteger value = 0;
    [scanner scanInteger:&value];
    
    NSArray *parts = [lower componentsSeparatedByString:@" "];
    if ([parts count] < 2) {
        return nil;
    }
    
    NSString *unit = [parts objectAtIndex:1];
    
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    
    if ([unit hasPrefix:@"second"]) {
        [offset setSecond:-value];
    } else if ([unit hasPrefix:@"minute"]) {
        [offset setMinute:-value];
    } else if ([unit hasPrefix:@"hour"]) {
        [offset setHour:-value];
    } else if ([unit hasPrefix:@"day"]) {
        [offset setDay:-value];
    } else if ([unit hasPrefix:@"week"]) {
        [offset setWeekOfYear:-value];
    } else if ([unit hasPrefix:@"month"]) {
        [offset setMonth:-value];
    } else if ([unit hasPrefix:@"year"]) {
        [offset setYear:-value];
    } else {
        [offset release];
        return nil;
    }
    
    NSDate *result = [cal dateByAddingComponents:offset toDate:now options:0];
    [offset release];
    
    return result;
}

+ (NSDate *)dateFromShortDate:(NSString *)string {
    if (!string || ![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [formatter setLocale:enUSPOSIXLocale];
    [formatter setDateFormat:@"MMM dd, yyyy"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate *result = [formatter dateFromString:[[string stringByReplacingOccurrencesOfString:@"Premiered " withString:@""] stringByReplacingOccurrencesOfString:@"Streamed live on " withString:@""]];
    [formatter release];
    [enUSPOSIXLocale release];
    
    return result;
}

+ (long)numberFromText:(NSString *)string {
    if (!string || ![string isKindOfClass:[NSString class]] || [string length] == 0) {
        return 0;
    }
    
    // Clean up common suffixes
    NSString *cleaned = [[string lowercaseString] 
                          stringByReplacingOccurrencesOfString:@" subscribers" withString:@""];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@" videos" withString:@""];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@" views" withString:@""];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@"," withString:@""];
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSScanner *scanner = [NSScanner scannerWithString:cleaned];
    double value = 0;
    [scanner scanDouble:&value];
    
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

+ (long)secondsFromDurationText:(NSString *)durationText {
    if (!durationText || ![durationText isKindOfClass:[NSString class]]) {
        return 0;
    }
    
    NSArray *components = [[[durationText componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
    long seconds = 0;
    
    if ([components count] >= 1) {
        seconds += [[components objectAtIndex:0] intValue];
    }
    if ([components count] >= 2) {
        seconds += [[components objectAtIndex:1] intValue] * 60;
    }
    if ([components count] >= 3) {
        seconds += [[components objectAtIndex:2] intValue] * 3600;
    }
    if ([components count] >= 4) {
        seconds += [[components objectAtIndex:3] intValue] * 86400;
    }
    
    return seconds;
}

#pragma mark - Thumbnail Helpers

+ (NSDictionary *)thumbnailsFromArray:(NSArray *)thumbnailsArray {
    if (!thumbnailsArray || ![thumbnailsArray isKindOfClass:[NSArray class]]) {
        return [NSDictionary dictionary];
    }
    
    NSMutableDictionary *thumbnails = [NSMutableDictionary dictionary];
    
    for (NSDictionary *thumb in thumbnailsArray) {
        if (![thumb isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSString *urlString = [thumb objectForKey:@"url"];
        NSNumber *width = [thumb objectForKey:@"width"];
        NSNumber *height = [thumb objectForKey:@"height"];
        
        if (urlString && width && height) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                CGSize size = CGSizeMake([width floatValue], [height floatValue]);
                NSValue *sizeValue = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
                [thumbnails setObject:url forKey:sizeValue];
            }
        }
    }
    
    return thumbnails;
}

@end

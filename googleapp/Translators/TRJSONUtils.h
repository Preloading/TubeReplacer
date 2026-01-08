// TRJSONUtils.h
// TubeReplacer
//
// Safe JSON access utilities to prevent crashes from nil/missing keys

#import <Foundation/Foundation.h>

@interface TRJSONUtils : NSObject

#pragma mark - Safe Keypath Access

/**
 * Safely retrieve a value from nested JSON using dot-separated keypath.
 * Returns nil if any part of the path is missing or wrong type.
 * Example: [TRJSONUtils valueFromJSON:json keyPath:@"header.pageHeaderRenderer.pageTitle"]
 */
+ (id)valueFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;

/**
 * Safely retrieve a value using array index in keypath.
 * Use [n] syntax for array access.
 * Example: @"contents.tabs[0].tabRenderer.content"
 */
+ (id)valueFromJSON:(NSDictionary *)json keyPathWithArrays:(NSString *)keyPath;

#pragma mark - Type-Safe Accessors

+ (NSString *)stringFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;
+ (NSArray *)arrayFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;
+ (NSDictionary *)dictFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;
+ (NSInteger)intFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;
+ (BOOL)boolFromJSON:(NSDictionary *)json keyPath:(NSString *)keyPath;

#pragma mark - Parsing Helpers

/**
 * Convert RFC3339 date string to NSDate.
 */
+ (NSDate *)dateFromRFC3339:(NSString *)string;

/**
 * Convert "5 days ago" style strings to NSDate.
 */
+ (NSDate *)dateFromTimeAgo:(NSString *)string;

/**
 * Parse view/subscriber counts like "1.2M", "500K", "1,234,567".
 */
+ (long)numberFromText:(NSString *)string;

/**
 * Parse duration string like "4:20" or "1:30:45" to seconds.
 */
+ (long)secondsFromDurationText:(NSString *)durationText;

#pragma mark - Thumbnail Helpers

/**
 * Parse thumbnail array into dictionary keyed by CGSize.
 */
+ (NSDictionary *)thumbnailsFromArray:(NSArray *)thumbnailsArray;

@end

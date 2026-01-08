// TRFeedTranslator.h
// TubeReplacer
//
// Translator for feed/page data containing lists of videos or channels

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRFeedTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate a feed response into a YTPage containing entries.
 * Handles various feed types: home, subscriptions, channel videos, search, etc.
 */
- (id)translateJSON:(NSDictionary *)json error:(NSError **)error;

/**
 * Extract the items array from various feed response structures.
 */
- (NSArray *)extractItemsFromFeed:(NSDictionary *)json;

@end

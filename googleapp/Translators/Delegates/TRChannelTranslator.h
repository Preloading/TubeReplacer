// TRChannelTranslator.h
// TubeReplacer
//
// Translator for channel data from YouTube JSON

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRChannelTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate channel from browse API response (full channel page).
 */
- (id)translateChannelPage:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate channel from search/feed item (compact format).
 */
- (id)translateCompactChannel:(NSDictionary *)json error:(NSError **)error;

@end

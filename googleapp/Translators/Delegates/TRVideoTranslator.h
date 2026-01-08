// TRVideoTranslator.h
// TubeReplacer
//
// Translator for video data from various YouTube JSON formats

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRVideoTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate a single video item from various formats:
 * - videoRenderer
 * - compactVideoRenderer  
 * - gridVideoRenderer
 * - playlistVideoRenderer
 * - videoWithContextRenderer
 * - lockupViewModel
 * - player response videoDetails
 */
- (id)translateJSON:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate video from player API response (full details).
 */
- (id)translatePlayerResponse:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate video from feed/search item (minimal details).
 */
- (id)translateFeedItem:(NSDictionary *)json 
            withContext:(NSDictionary *)context 
                  error:(NSError **)error;

@end

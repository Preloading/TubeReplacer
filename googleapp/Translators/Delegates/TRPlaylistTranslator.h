// TRPlaylistTranslator.h
// TubeReplacer
//
// Translator for playlist data from YouTube JSON

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRPlaylistTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate playlist from compact renderer (feed item).
 */
- (id)translateCompactPlaylist:(NSDictionary *)json 
                   withContext:(NSDictionary *)context 
                         error:(NSError **)error;

@end

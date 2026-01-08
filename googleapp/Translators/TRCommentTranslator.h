// TRCommentTranslator.h
// TubeReplacer
//
// Translator for comment data from YouTube JSON

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRCommentTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate a comment from feed item format (commentThreadRenderer).
 */
- (id)translateFeedComment:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate a comment from "just created" response format.
 */
- (id)translateCreatedComment:(NSDictionary *)json error:(NSError **)error;

@end

// TRSubscriptionTranslator.h
// TubeReplacer
//
// Translator for subscription data from YouTube JSON

#import <Foundation/Foundation.h>
#import "TRJSONTranslatorProtocol.h"

@interface TRSubscriptionTranslator : NSObject <TRJSONTranslatorProtocol>

/**
 * Translate subscription from channel list item (subscription page).
 */
- (id)translateListItem:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate subscription from channel header (subscription check).
 */
- (id)translateFromChannelHeader:(NSDictionary *)json error:(NSError **)error;

/**
 * Translate subscription from just-subscribed response.
 */
- (id)translateFromSubscribeAction:(NSDictionary *)json error:(NSError **)error;

@end

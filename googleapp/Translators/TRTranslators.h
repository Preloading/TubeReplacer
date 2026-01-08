// TRTranslators.h
// TubeReplacer
//
// Convenience header that imports all translator components
// 
// Architecture:
//   Server → App: TRJSONTranslator routes JSON to specific translators
//   App → Server: TRRequestBuilder constructs API request bodies
//

#ifndef TRTranslators_h
#define TRTranslators_h

#import "TREndpointType.h"
#import "TRJSONTranslatorProtocol.h"
#import "TRJSONTranslator.h"
#import "TRJSONUtils.h"
#import "Delegates/TRVideoTranslator.h"
#import "Delegates/TRChannelTranslator.h"
#import "Delegates/TRFeedTranslator.h"
#import "Delegates/TRCommentTranslator.h"
#import "Delegates/TRSubscriptionTranslator.h"
#import "Delegates/TRPlaylistTranslator.h"
#import "TRRequestBuilder.h"
#import "../../YoutubeClientType.h"

#endif

// TRTranslators.h
// TubeReplacer
//
// Convenience header that imports all translator components
// 
// Architecture:
//   Server → App: TRJSONTranslator routes JSON to specific translators
//   App → Server: TRRequestBuilder constructs API request bodies
//
// Usage: #include "Translators/TRTranslators.h" in any .x file

#ifndef TRTranslators_h
#define TRTranslators_h

#import "TREndpointType.h"
#import "TRJSONTranslatorProtocol.h"
#import "TRJSONTranslator.h"
#import "TRJSONUtils.h"
#import "TRVideoTranslator.h"
#import "TRChannelTranslator.h"
#import "TRFeedTranslator.h"
#import "TRCommentTranslator.h"
#import "TRSubscriptionTranslator.h"
#import "TRPlaylistTranslator.h"
#import "TRRequestBuilder.h"
#import "../../YoutubeClientType.h"

#endif /* TRTranslators_h */

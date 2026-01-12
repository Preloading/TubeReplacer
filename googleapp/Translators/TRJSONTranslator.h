// TRJSONTranslator.h
// TubeReplacer
//
// Singleton router that dispatches JSON to appropriate translators

#import <Foundation/Foundation.h>
#import "TREndpointType.h"
#import "TRJSONTranslatorProtocol.h"

@interface TRJSONTranslator : NSObject

/**
 * Shared singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Translate JSON for a specific endpoint type.
 * Routes to the appropriate registered translator.
 */
- (id)translateJSON:(NSDictionary *)json 
       forEndpoint:(TREndpointType)endpoint
             error:(NSError **)error;

/**
 * Auto-detect endpoint type and translate.
 * Iterates through translators calling canTranslateJSON: until one matches.
 */
- (id)translateJSON:(NSDictionary *)json error:(NSError **)error;

/**
 * Register a translator for an endpoint type.
 * Called at startup to populate the router.
 */
- (void)registerTranslator:(id<TRJSONTranslatorProtocol>)translator
              forEndpoint:(TREndpointType)endpoint;

/**
 * Get the translator for a specific endpoint.
 */
- (id<TRJSONTranslatorProtocol>)translatorForEndpoint:(TREndpointType)endpoint;

@end

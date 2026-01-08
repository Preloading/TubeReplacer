// TRJSONTranslatorProtocol.h
// TubeReplacer
//
// Protocol defining the interface for JSON translators

#import <Foundation/Foundation.h>
#import "TREndpointType.h"

@protocol TRJSONTranslatorProtocol <NSObject>

@required

/**
 * Check if this translator can handle the given JSON data.
 * Used for auto-detection when endpoint type is unknown.
 */
- (BOOL)canTranslateJSON:(NSDictionary *)json;

/**
 * Translate JSON dictionary into the appropriate model object.
 * Returns nil and sets error on failure.
 */
- (id)translateJSON:(NSDictionary *)json error:(NSError **)error;

/**
 * Returns the endpoint type this translator handles.
 */
+ (TREndpointType)supportedEndpoint;

@optional

/**
 * Translate JSON with additional context (e.g., the full response body).
 * Useful for feeds where individual items need context from parent.
 */
- (id)translateJSON:(NSDictionary *)json 
        withContext:(NSDictionary *)context 
              error:(NSError **)error;

@end

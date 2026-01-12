// TRJSONTranslator.m
// TubeReplacer
//
// Singleton router implementation

#import "TRJSONTranslator.h"

@interface TRJSONTranslator ()
@property (nonatomic, retain) NSMutableDictionary *translators;
@end

@implementation TRJSONTranslator

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static TRJSONTranslator *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TRJSONTranslator alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _translators = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_translators release];
    [super dealloc];
}

#pragma mark - Registration

- (void)registerTranslator:(id<TRJSONTranslatorProtocol>)translator
              forEndpoint:(TREndpointType)endpoint {
    if (!translator) {
        return;
    }
    NSNumber *key = [NSNumber numberWithInteger:endpoint];
    [self.translators setObject:translator forKey:key];
}

- (id<TRJSONTranslatorProtocol>)translatorForEndpoint:(TREndpointType)endpoint {
    NSNumber *key = [NSNumber numberWithInteger:endpoint];
    return [self.translators objectForKey:key];
}

#pragma mark - Translation

- (id)translateJSON:(NSDictionary *)json 
       forEndpoint:(TREndpointType)endpoint
             error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRTranslatorError" 
                                         code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid JSON input"}];
        }
        return nil;
    }
    
    id<TRJSONTranslatorProtocol> translator = [self translatorForEndpoint:endpoint];
    
    if (!translator) {
        // Fall back to auto-detection
        return [self translateJSON:json error:error];
    }
    
    return [translator translateJSON:json error:error];
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRTranslatorError" 
                                         code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid JSON input"}];
        }
        return nil;
    }
    
    // Try each registered translator
    for (NSNumber *key in self.translators) {
        id<TRJSONTranslatorProtocol> translator = [self.translators objectForKey:key];
        if ([translator canTranslateJSON:json]) {
            return [translator translateJSON:json error:error];
        }
    }
    
    // No translator found
    if (error) {
        *error = [NSError errorWithDomain:@"TRTranslatorError" 
                                     code:2 
                                 userInfo:@{NSLocalizedDescriptionKey: @"No translator found for JSON"}];
    }
    return nil;
}

@end

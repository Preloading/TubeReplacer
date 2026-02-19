// parsing.x
// TubeReplacer
//
// Data format detection and routing (XML vs JSON)
// Also handles subscription caching for POST requests

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Format Detection & Parsing

%hook YTTBParser

-(id)parse:(NSData*)rawData error:(NSError **)error {
    if (!rawData || [rawData length] == 0) {
        NSLog(@"TubeReplacer: Empty data received");
        return nil;
    }

    // NSLog(@"rawData -> %@", rawData);
    
    const unsigned char* bytes = [rawData bytes];
    NSUInteger length = [rawData length];
    NSData *cleanData = rawData;
    
    // Strip Google's anti-XSS prefix: )]}'\\n
    // This is prepended to JSON responses to prevent JSONP hijacking
    if (length >= 5 && 
        bytes[0] == ')' && 
        bytes[1] == ']' && 
        bytes[2] == '}' && 
        bytes[3] == '\'' && 
        bytes[4] == '\n') {
        bytes += 5;
        length -= 5;
        cleanData = [NSData dataWithBytes:bytes length:length];
    }
    
    // Detect format by first character
    if (length > 0 && bytes[0] == '<') {
        // XML format - use legacy TBXML parser
        NSLog(@"TubeReplacer: XML detected, using TBXML");
        TBXML *xml = [%c(TBXML) tbxmlWithXMLData:cleanData error:error];
        if ([xml rootXMLElement]) {
            YTTBXMLElement *rootElement = [[[%c(YTTBXMLElement) alloc] 
                initWithElement:[xml rootXMLElement]] autorelease];
            return [self parseElement:rootElement error:error];
        }
        return nil;
    } 
    else if (length > 0 && bytes[0] == '{') {
        // JSON format - parse and route to translators
        NSLog(@"TubeReplacer: JSON detected");
        id json = [NSJSONSerialization 
            JSONObjectWithData:cleanData 
            options:NSJSONReadingMutableContainers 
            error:error];
        
        if (!json) {
            NSLog(@"TubeReplacer: JSON parsing failed");
            return nil;
        }
        
        // Route to parseElement which will use the appropriate translator
        return [self parseElement:json error:error];
    } 
    else {
        NSLog(@"TubeReplacer: Unknown format, first byte: 0x%02X", bytes[0]);
        return nil;
    }
}

%end

#pragma mark - POST Request Caching

%hook YTGDataService

- (void)makePOSTRequest:(YTGDataRequest *)request
             withParser:(id)parser
          responseBlock:(id)responseBlock
             errorBlock:(id)errorBlock {
    
    // Wrap the response block to intercept certain responses for caching
    void (^originalResponseBlock)(id) = [responseBlock copy];

    void (^wrappedResponseBlock)(id) = ^(id response) {
        // Cache subscriptions when fetching subscription page
        NSLog(@"parser -> %@", parser);
        if (parser == [self valueForKey:@"subscriptionPageParser_"]) {
            id cache = [self valueForKey:@"subscriptionCache_"];
            [cache setValue:@100000 forKey:@"countLimit_"];
            [self cacheSubscriptionsFromSubscriptionPage:response];
        }

        if (parser == [self valueForKey:@"channelParser_"]) {
            id cache = [self channelCache];
            [cache setValue:@100000 forKey:@"countLimit_"];
            [self cacheChannel:response];
        }

        

        if (parser == [self valueForKey:@"channelPageParser_"]) {
            id cache = [self channelCache];
            for (id channel in [response entries]) {
                [cache setValue:@100000 forKey:@"countLimit_"];
                [self cacheChannel:channel];
            }
            
        }

        if (originalResponseBlock) {
            originalResponseBlock(response);
        }
    };

    %orig(request, parser, wrappedResponseBlock, errorBlock);
    
    [originalResponseBlock release];
}

%end

// fixes views & other values being capped at 32bit unsigned int limit
%hook YTUtils
+(id)localizedCount:(uint64_t)number
{
  return [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithLongLong:number] numberStyle:1];
}
%end

%hook YTUIUtils
+(id)localizedCount:(uint64_t)number
{
  return [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithLongLong:number] numberStyle:1];
}
%end

@interface PendingRequestKey

-(id)keyWithRequest:(id)a3 authorizer:(id)a4;

@end

// i hate you youtube for not writing this correctly!!!!
%hook YTBaseService

-(void)performHTTPRequest:(id)request withAuthorizer:(id)withAuthorizer completionBlock:(id)completionBlock
{
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        return %orig;
    } else {
        id copiedCompletionBlock = [completionBlock copy];

        NSBlockOperation *operation =
        [NSBlockOperation blockOperationWithBlock:^{

            id requestKey =
            [%c(PendingRequestKey) keyWithRequest:request authorizer:withAuthorizer];

            id completionBlock2 = [copiedCompletionBlock autorelease];

            NSMutableArray *v6 =
            [NSMutableArray arrayWithObject:completionBlock2];

            [[self valueForKey:@"pendingRequests_"]
                setObject:v6 forKey:requestKey];

            GTMHTTPFetcher *fetcher =
            [[self valueForKey:@"httpFetcherService_"]
                fetcherWithRequest:request];

            [fetcher setAuthorizer:withAuthorizer];

            [fetcher beginFetchWithCompletionHandler:
            ^(NSData *data, NSError *error) {

                for (void (^block)(NSData *, NSError *) in v6) {
                    block(data, error);
                }

                [(NSMutableDictionary*)
                [self valueForKey:@"pendingRequests_"]
                removeObjectForKey:requestKey];
            }];
        }];

        [[NSOperationQueue mainQueue] addOperation:operation];
    }
}
%end
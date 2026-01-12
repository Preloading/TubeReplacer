// channels.x
// TubeReplacer
//
// Channel page request and parsing hooks

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForChannelWithID:(NSString*)channelId {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" 
                       authentication:nil 
                                 body:[TRRequestBuilder browseBodyWithId:channelId 
                                                                  params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeChannelRequestWithID:(NSString*)channelId responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id url = [%c(YTGDataRequest) requestForChannelWithID:channelId];
    [self makePOSTRequest:url 
               withParser:[self valueForKey:@"channelParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Channel Parsing

%hook YTChannelParser

-(id)parseElement:(id)body error:(NSError*)error {
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRChannelTranslator *translator = [[[TRChannelTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id channel = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRChannelTranslator error: %@", translatorError);
        }
        
        return channel;
    } else {
        NSLog(@"YTChannelParser: input is not NSDictionary");
        return nil;
    }
}

%end
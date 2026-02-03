// channelfeed.x
// TubeReplacer
//
// Channel uploaded videos hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForUploadedVideosWithChannelID:(NSString*)channelId {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:channelId 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForEventsWithChannelID:(NSString*)channelId {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil 
                //  body:[TRRequestBuilder browseBodyWithId:channelId 
                //                                             params:@"EgZ2aWRlb3PyBgQKAjoA" 
                //                                             client:[YoutubeClientType webMobileClient]]];
                           body:[TRRequestBuilder getPopularVideosFromChannelId:channelId
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeUploadedVideosRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil // i hope this wont cause issues... 
                           body:[TRRequestBuilder continueWithContext:[request URL] 
                                                            client:[YoutubeClientType webMobileClient]]];
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makeEventsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil // i hope this wont cause issues... 
                           body:[TRRequestBuilder continueWithContext:[request URL] 
                                                        client:[YoutubeClientType webMobileClient]]];
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"eventPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

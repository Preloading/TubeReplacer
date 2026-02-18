// channelfeed.x
// TubeReplacer
//
// Channel uploaded videos hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "Translators/TRContinuation.h"
#include "general.h"

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
    return [self requestWithURL:channelId
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:channelId 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];}

%end

%hook YTGDataRequestFactory

-(id)requestForUploadedVideosWithChannelID:(NSString*)channelId {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:channelId 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];
}

-(id)requestForEventsWithChannelID:(NSString*)channelId {
    return [self requestWithURL:channelId
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:channelId 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeUploadedVideosRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        }
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makeEventsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    id actualRequest = request;
    id newResponseBlock = responseBlock;

    if ([[request URL] isKindOfClass:[TRContinuation class]]) {
        if ([version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[[request URL] token]
                                                            client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[[request URL] token]
                                                            client:[YoutubeClientType webMobileClient]]];
        }
    } else {
        if ([version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil 
                            body:[TRRequestBuilder getPopularVideosFromChannelId:[request URL]
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                    authentication:nil 
                            body:[TRRequestBuilder getPopularVideosFromChannelId:[request URL]
                                                                client:[YoutubeClientType webMobileClient]]];
        }
        void (^originalResponseBlock)(id) = [responseBlock copy];
        void (^newResponseBlock)(id) = ^(id response) {
            [response setValue:nil forKey:@"nextURL_"];
            for (YTEvent *event in [response entries]) {
                [event setValue:@5 forKey:@"action_"];
                [event setValue:[request URL] forKey:@"authorUserID_"];
                [event setValue:[[[self channelCache] objectForKey:[request URL]] displayName] forKey:@"authorDisplayName_"];
                [[event video] setValue:[request URL] forKey:@"uploaderChannelID_"];
                [[event video] setValue:[[[self channelCache] objectForKey:[request URL]] displayName] forKey:@"uploaderDisplayName_"];
            }

            if (originalResponseBlock) {
                originalResponseBlock(response);
            }
        };

        [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"eventPageParser_"] 
            responseBlock:newResponseBlock 
               errorBlock:errorBlock];

               return;
        
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"eventPageParser_"] 
            responseBlock:newResponseBlock 
               errorBlock:errorBlock];
}

%end

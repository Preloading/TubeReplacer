// suggestedvideos.x
// TubeReplacer
//
// Related/suggested videos hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest 

+(id)requestForRelatedVideosWithURL:(id)videoId safeSearch:(id)safeSearch {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next?prettyPrint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder nextBodyWithVideoId:videoId 
                                                               client:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataRequestFactory

-(id)requestForRelatedVideosWithURL:(id)videoId safeSearch:(id)safeSearch {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next?prettyPrint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder nextBodyWithVideoId:videoId 
                                                               client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeRelatedVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next?prettyPrint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next?prettyPrint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        }
    }
    
    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:l(@"videoPageParser")] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end
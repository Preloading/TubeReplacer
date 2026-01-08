// suggestedvideos.x
// TubeReplacer
//
// Related/suggested videos hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest 

+(id)requestForRelatedVideosWithURL:(id)videoId safeSearch:(id)safeSearch {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
                 authentication:nil 
                           body:[TRRequestBuilder playerBodyWithVideoId:videoId 
                                                                 client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeRelatedVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end
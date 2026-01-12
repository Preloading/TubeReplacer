// homefeed.x
// TubeReplacer
//
// Home feed and subscription uploads hooks

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeMySubscriptionUploadsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMySubscriptionUploadsWithAuth:(id)authentication safeSearch:(BOOL)isSafeSearch {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"FEsubscriptions" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMySubscriptionUpdatesWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"FEwhat_to_watch" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

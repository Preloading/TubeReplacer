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
// something for future, it may be worth it to figure out the entire pagination stuff so we dont have to do this everywhere
    NSLog(@"makeMySubscriptionUploadsRequest class -> %@", NSStringFromClass([[request URL] class]));
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

%end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMySubscriptionUploadsWithAuth:(id)authentication safeSearch:(BOOL)isSafeSearch {
    %log;
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

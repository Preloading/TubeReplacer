// accountfeeds.x
// TubeReplacer
//
// User account feeds: favorites, history, watch later, uploads

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMyFavoriteVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"VLLL" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMyWatchHistoryVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"FEhistory" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMyWatchLaterVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"VLWL" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMyPurchases:(id)authentication {
    [%c(GIPToast) showToast:@"do you really think youtube would actually let you watch any of your purchases on a decade old phone?" forDuration:4];
    return %orig;
}

+(id)requestForMyUploadedVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:[authentication channelID] 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataRequestFactory

-(id)requestForMyFavoriteVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"VLLL" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

-(id)requestForMyWatchHistoryVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"FEhistory" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

-(id)requestForMyWatchLaterVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:@"VLWL" 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

-(id)requestForMyPurchases:(id)authentication {
    [%c(GIPToast) showToast:@"do you really think youtube would actually let you watch any of your purchases on a decade old phone?" forDuration:4];
    return %orig;
}

-(id)requestForMyUploadedVideosWithAuth:(id)authentication {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:[authentication channelID] 
                                                            params:@"EgZ2aWRlb3PyBgQKAjoA" 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeMyFavoriteVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
                            authentication:nil // i hope this wont cause issues... 
                                    body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                        client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
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

-(void)makeMyWatchHistoryVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
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

-(void)makeMyWatchLaterVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
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

-(void)makeMyUploadedVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false"] 
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

%end

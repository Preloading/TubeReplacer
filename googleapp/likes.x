// likes.x
// TubeReplacer
//
// Like/unlike video action hooks

#include <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestToRateWithVideoID:(NSString *)videoId authentication:(id)authentication like:(BOOL)like {
    // Choose endpoint based on like/unlike
    // TODO: Add RYTDL support
    NSString *endpoint = like 
        ? @"https://www.youtube.com/youtubei/v1/like/like?prettyPrint=false" 
        : @"https://www.youtube.com/youtubei/v1/like/removelike?prettyPrint=false";
    
    NSData *body = [TRRequestBuilder likeBodyWithVideoId:videoId 
                                                  client:[YoutubeClientType webMobileClient]];
    
    return [self requestWithURLString:endpoint 
                       authentication:authentication 
                                 body:body];
}

+(id)requestToAddToFavoritesWithVideoID:(NSString *)videoId authentication:(id)authentication {
    // TODO: see if i can make this actually run the like video stuff.
    return [%c(YTGDataRequest) requestToRateWithVideoID:videoId authentication:authentication like:YES]; // i mean i think it used to be a seperate playlist but not it's not so
}


%end

%hook YTGDataRequestFactory

-(id)requestToRateWithVideoID:(NSString *)videoId authentication:(id)authentication like:(BOOL)like {
    // Choose endpoint based on like/unlike
    // TODO: Add RYTDL support
    NSString *endpoint = like 
        ? @"https://www.youtube.com/youtubei/v1/like/like?prettyPrint=false" 
        : @"https://www.youtube.com/youtubei/v1/like/removelike?prettyPrint=false";
    
    NSData *body = [TRRequestBuilder likeBodyWithVideoId:videoId 
                                                  client:[YoutubeClientType webMobileClient]];
    
    return [self requestWithURLString:endpoint 
                       authentication:authentication 
                                 body:body];
}

-(id)requestToAddToFavoritesWithVideoID:(NSString *)videoId authentication:(id)authentication {
    return [self requestToRateWithVideoID:videoId authentication:authentication like:YES]; // i mean i think it used to be a seperate playlist but not it's not so
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeRateRequestWithVideoID:(NSString*)videoId authentication:(id)authentication like:(BOOL)like responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    
    YTGDataRequest *request = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        request = [%c(YTGDataRequest) requestToRateWithVideoID:videoId 
                                        authentication:authentication 
                                                    like:like];
    } else {
        request = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestToRateWithVideoID:videoId 
                                        authentication:authentication 
                                                    like:like];
    }
    
    // Like responses don't need parsing - just check for success
    [self makePOSTRequest:request 
               withParser:nil 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

// likes.x
// TubeReplacer
//
// Like/unlike video action hooks

#include <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestToRateWithVideoID:(NSString *)videoId authentication:(id)authentication like:(BOOL)like {
    // Choose endpoint based on like/unlike
    // TODO: Add RYTDL support
    NSString *endpoint = like 
        ? @"https://www.youtube.com/youtubei/v1/like/like" 
        : @"https://www.youtube.com/youtubei/v1/like/removelike";
    
    NSData *body = [TRRequestBuilder likeBodyWithVideoId:videoId 
                                                  client:[YoutubeClientType webMobileClient]];
    
    return [self requestWithURLString:endpoint 
                       authentication:authentication 
                                 body:body];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeRateRequestWithVideoID:(NSString*)videoId authentication:(id)authentication like:(BOOL)like responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    YTGDataRequest *request = [%c(YTGDataRequest) requestToRateWithVideoID:videoId 
                                                            authentication:authentication 
                                                                      like:like];
    
    // Like responses don't need parsing - just check for success
    [self makePOSTRequest:request 
               withParser:nil 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

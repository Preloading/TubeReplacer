#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest 

+(id)requestForRelatedVideosWithURL:(id)videoId safeSearch:(id)safeSearch {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] authentication:nil body:[YoutubeRequestClient getVideoWithID:videoId withClient:[YoutubeClientType webMobileClient]]];//[YoutubeRequestClient browseBody:browseId params:params]];
}

%end

%hook YTGDataService

// convert from GET to POST
-(void)makeRelatedVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
  [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end
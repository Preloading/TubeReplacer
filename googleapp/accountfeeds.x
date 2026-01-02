#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

+(id)requestForMyFavoriteVideosWithAuth:(id)authentication
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"VLLL" params:nil]];
}

+(id)requestForMyWatchHistoryVideosWithAuth:(id)authentication
{
   return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"FEhistory" params:nil]];
}

%end

%hook YTGDataService
-(void)makeMyFavoriteVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

-(void)makeMyWatchHistoryVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}
%end
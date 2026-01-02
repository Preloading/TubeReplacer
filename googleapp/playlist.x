#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

+(id)requestForMyPlaylistVideosWithURL:(id)url authentication:(id)authentication
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"FEplaylist_aggregation" params:nil]];
}

%end

%hook YTGDataService
-(void)makeMyPlaylistsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 

    NSLog(@"dear god just give it to me please playlists: %@", [[request authentication] channelID]);
    [self makePOSTRequest:[%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:nil body:[YoutubeRequestClient browseBody:@"FEplaylist_aggregation" params:nil]] 
        withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end
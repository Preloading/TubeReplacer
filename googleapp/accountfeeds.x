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

+(id)requestForMyWatchLaterVideosWithAuth:(id)authentication
{
   return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"VLWL" params:nil]];
}

+(id)requestForMyPurchases:(id)authentication
{
    [%c(GIPToast) showToast:@"do you really think youtube would actually let you watch any of your purchases on a decade old phone?" forDuration:4];
    return %orig;
}

+(id)requestForMyUploadedVideosWithAuth:(id)authentication
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:[authentication channelID] params:@"EgZ2aWRlb3PyBgQKAjoA"]];
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

-(void)makeMyWatchLaterVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

-(void)makeMyUploadedVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}
%end

// https://studio.youtube.com/youtubei/v1/creator/list_creator_videos?alt=json
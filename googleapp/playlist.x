#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

// my play
+(id)requestForPlaylistsWithChannelID:(id)channelId
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:nil body:[YoutubeRequestClient browseBody:channelId params:@"EglwbGF5bGlzdHPyBgQKAkIA"]];
}

+(id)requestForPlaylistVideosWithURL:(NSString*)playlistId
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:nil body:[YoutubeRequestClient browseBody:[NSString stringWithFormat:@"VL%@", playlistId] params:nil]];
}

+(id)requestForMyPlaylistVideosWithURL:(NSString*)playlistId authentication:(id)authentication
{
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:[NSString stringWithFormat:@"VL%@", playlistId] params:nil]];
}

%end

%hook YTGDataService
-(void)makeMyPlaylistsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 

    [self makePOSTRequest:[%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:nil body:[YoutubeRequestClient browseBody:[[request authentication] channelID] params:@"EglwbGF5bGlzdHPyBgQKAkIA"]] 
        withParser:[self valueForKey:@"playlistPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

-(void)makePlaylistsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 

    [self makePOSTRequest:request withParser:[self valueForKey:@"playlistPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

-(void)makePlaylistVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

-(void)makeMyPlaylistVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

%hook YTPlaylistParser 

-(id)parseElement:(NSDictionary*)body error:(NSError *)onError {
    NSDictionary *data = body[@"i"][@"compactPlaylistRenderer"];
    NSMutableDictionary *thumbnails = [NSMutableDictionary new];
    NSDictionary *unparsedThumbnails = data[@"thumbnail"][@"thumbnails"];
    for (NSDictionary *unparsedThumbnail in unparsedThumbnails) {
        [thumbnails setObject:[NSURL URLWithString:unparsedThumbnail[@"url"]] forKey:[NSValue valueWithBytes:&(CGSize){[unparsedThumbnail[@"height"] intValue],[unparsedThumbnail[@"width"] intValue]} objCType:@encode(CGSize)]];
    }

    return [[[%c(YTPlaylist) alloc] initWithTitle:data[@"title"][@"runs"][0][@"text"]
        summary:@""
        authorDisplayName:body[@"all"][@"header"][@"pageHeaderRenderer"][@"pageTitle"]
        updated:[NSDate date] // :(
        thumbnailURLs:thumbnails
        contentURL:data[@"playlistId"]
        editURL:[NSURL URLWithString:@"https://example.com/editurl"]
        size:[data[@"videoCountShortText"][@"runs"][0][@"text"] intValue]
        isPrivate:[data[@"shortBylineText"][@"runs"][0][@"text"] isEqualToString:@"Private"] // i think that technically if the channel of "Private" has a playlist, this *might* break, but realistically idc
    ] autorelease];
}

%end




// playlist.x
// TubeReplacer
//
// Playlist-related hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForPlaylistsWithChannelID:(id)channelId {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:channelId 
                                                            params:@"EglwbGF5bGlzdHPyBgQKAkIA" 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForPlaylistVideosWithURL:(NSString*)playlistId {
    NSString *browseId = [NSString stringWithFormat:@"VL%@", playlistId];
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:browseId 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMyPlaylistVideosWithURL:(NSString*)playlistId authentication:(id)authentication {
    NSString *browseId = [NSString stringWithFormat:@"VL%@", playlistId];
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:authentication 
                           body:[TRRequestBuilder browseBodyWithId:browseId 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeMyPlaylistsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    // Rebuild request with channelID from authentication
    NSData *body = [TRRequestBuilder browseBodyWithId:[[request authentication] channelID] 
                                               params:@"EglwbGF5bGlzdHPyBgQKAkIA" 
                                               client:[YoutubeClientType webMobileClient]];
    
    YTGDataRequest *newRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                                                     authentication:nil 
                                                               body:body];
    
    [self makePOSTRequest:newRequest 
               withParser:[self valueForKey:@"playlistPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makePlaylistsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"playlistPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makePlaylistVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makeMyPlaylistVideosRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Playlist Parsing

%hook YTPlaylistParser 

-(id)parseElement:(NSDictionary*)body error:(NSError *)error {
    // Use unified translator for playlist parsing
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRPlaylistTranslator *translator = [[[TRPlaylistTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id playlist = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRPlaylistTranslator error: %@", translatorError);
        }
        
        return playlist;
    }
    
    NSLog(@"YTPlaylistParser: input is not NSDictionary");
    return nil;
}

%end

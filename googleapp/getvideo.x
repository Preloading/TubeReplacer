// getvideo.x
// TubeReplacer
//
// Video detail request and parsing hooks

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(YTGDataRequest*)requestForVideoWithVideoID:(NSString*)videoId {
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/player?noauth=1"];
    NSURL *fullURL = [urlBuilder URL];
    return [self requestWithURL:fullURL 
                 authentication:nil 
                           body:[TRRequestBuilder playerBodyWithVideoId:videoId 
                                                                 client:[YoutubeClientType androidClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeVideoRequestWithVideoID:(NSString*)videoId responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id videoCache = [self valueForKey:@"videoCache_"];
    id cachedVideo = [videoCache objectForKey:videoId];
    
    if (cachedVideo) {
        [self performResponseBlock:responseBlock response:cachedVideo];
    } else {
        YTGDataRequest *request = [%c(YTGDataRequest) requestForVideoWithVideoID:videoId];
        [self makePOSTRequest:request 
                   withParser:[self valueForKey:@"videoParser_"] 
                responseBlock:responseBlock 
                   errorBlock:errorBlock];
    }
}

%end

#pragma mark - Video Parsing

%hook YTVideoParser

-(YTVideo*)parseElement:(id)body error:(NSError*)error {
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRVideoTranslator *translator = [[[TRVideoTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id video = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRVideoTranslator error: %@", translatorError);
        }
        
        return video;
    } else {
        NSLog(@"YTVideoParser: input is not NSDictionary");
        return nil;
    }
}

%end

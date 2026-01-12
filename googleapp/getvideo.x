// getvideo.x
// TubeReplacer
//
// Video detail request and parsing hooks
// Makes both /player (for streams) and /next (for likes) requests

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "appheaders.h"
#include "general.h"
#include "Translators/TRTranslators.h"

// Forward declare new methods for YTVideoParser
@interface YTVideoParser : NSObject
-(id)parseElement:(id)fp8 error:(id *)fp12;
// New methods
-(NSDictionary *)fetchNextDataForVideoId:(NSString *)videoId;
-(void)enhanceVideo:(id)video withNextData:(NSDictionary *)nextData;
@end

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
    if (![body isKindOfClass:[NSDictionary class]]) {
        NSLog(@"YTVideoParser: input is not NSDictionary");
        return nil;
    }
    
    TRVideoTranslator *translator = [[[TRVideoTranslator alloc] init] autorelease];
    NSError *translatorError = nil;
    id video = [translator translateJSON:body error:&translatorError];
    
    if (translatorError) {
        NSLog(@"TRVideoTranslator error: %@", translatorError);
        return nil;
    }
    
    // Enhance with /next data for like counts
    NSString *videoId = [TRJSONUtils stringFromJSON:body keyPath:@"videoDetails.videoId"];
    
    if (videoId && video) {
        @try {
            NSDictionary *nextData = [self fetchNextDataForVideoId:videoId];
            if (nextData) {
                [translator enhanceVideo:video withNextResponse:nextData];
            }
        } @catch (NSException *e) {
            NSLog(@"Failed to fetch /next data: %@", e);
        }
    }
    
    return video;
}

%new
-(NSDictionary *)fetchNextDataForVideoId:(NSString *)videoId {
    // Synchronous request to /next endpoint
    // Consider making this async for better UX BUT im lazy

    NSMutableDictionary *allData = [NSMutableDictionary dictionary];

    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[TRRequestBuilder nextBodyWithVideoId:videoId 
                                                        client:[YoutubeClientType webMobileClient]]];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&reqError];
    
    if (!reqError && data) {
        NSError *jsonError = nil;

        allData[@"next"] = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    }
    
    
    // TODO: this should be running at the same time as the next request
    NSURL *rytdl = [NSURL URLWithString:[NSString stringWithFormat:@"https://returnyoutubedislikeapi.com/votes?videoId=%@", videoId]];
    
    NSMutableURLRequest *requestDL = [NSMutableURLRequest requestWithURL:rytdl];
    [requestDL setHTTPMethod:@"GET"];
    
    NSURLResponse *responseDL = nil;
    NSError *reqErrorDL = nil;
    NSData *dataDL = [NSURLConnection sendSynchronousRequest:requestDL returningResponse:&responseDL error:&reqErrorDL];
    
    if (!reqErrorDL && dataDL) {
        NSError *jsonErrorDL = nil;
        allData[@"dislikes"] = [NSJSONSerialization JSONObjectWithData:dataDL options:0 error:&jsonErrorDL];
    }
    
    return allData;
}

%end

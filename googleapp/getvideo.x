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

// this is just for debugging setting strings as NSURL
%hook __NSCFString

%new
-(id)host {
    NSLog(@"String got a host call!");
    [%c(GIPToast) showTodo];
    return nil; // things go wrong here
}
%end

%hook GIPDevice

- (BOOL)canPlayH264MainProfile {
    NSString *gen = [self generation];

    if ([gen isEqualToString:@"iPodTouch1G"]) return NO;
    if ([gen isEqualToString:@"iPodTouch2G"]) return NO;
    if ([gen isEqualToString:@"iPodTouch3G"]) return NO;
    if ([gen isEqualToString:@"iPhone2G"]) return NO;
    if ([gen isEqualToString:@"iPhone3G"]) return NO;
    if ([gen isEqualToString:@"iPhone3GS"]) return NO;

    return YES;
}

%new
- (BOOL)canPlayH264HighProfile {
    if (![self canPlayH264MainProfile]) { return NO; }

    NSString *category = [self deviceCategory];
    NSString *gen = [self generation];

    // they didn't add high profile till the 7th! holy shit!
    if ([category isEqualToString:@"iPodTouch"]) return NO;
    if ([gen isEqualToString:@"iPad"]) return NO;
    if ([gen isEqualToString:@"iPhone4"]) return NO;

    return YES;
}
%end


%hook YTStream

// changed to provide both an audio & video stream (since it's muxed)
+(id)selectStreamForVideo:(YTVideo*)video onWiFi:(BOOL)onWifi {
    NSLog(@"+(id)selectStreamForVideo");
    NSArray *streams = [video streams];

    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    BOOL isRetina = [%c(YTUtils) isRetinaDisplay];

    // video rankings
    // 1 = tiny/144p
    // 2 = small/240p
    // 3 = medium/360p
    // 4 = large/480p
    // 5 = hd720
    // 6 = hd1080

    int selectedVideo = 0;

    if (onWifi) {
        if (isRetina) {
            if (isPad) {
                selectedVideo = 6;
                // 1080p, best audio
            } else {
                selectedVideo = 5;
                // 720p, best audio
            }
        } else {
            if (isPad) {
                // we're using a slightly higher to get full resolution, even tho i think scaling might impact it
                selectedVideo = 6;
                // 1080p high audio
            } else {
                // iphone 3GS
                selectedVideo = 3;
                // 360p high audio
            }
        }
    } else {
        if (isRetina) {
            if (isPad) {
                selectedVideo = 5;
                // 720p, low audio
            } else {
                selectedVideo = 4;
                // 480p, low audio
            }
        } else {
            if (isPad) {
                selectedVideo = 5;
                // 720p low audio
            } else {
                selectedVideo = 2;
                // 240p low audio?
            }
        }
    }
    NSLog(@"Finding video with rank %i", selectedVideo);

    int closenessToVideoRank = 2147483647;
    YTStream *currentlySelectedVideo = nil;

    // int closenessToAudioRank = 2147483647;
    // YTStream *currentlySelectedAudio = nil;

    NSLog(@"a1");
    GIPDevice *device = [%c(GIPDevice) currentDevice];
    for (YTStream *actualStream in streams) {
        NSLog(@"a2");
        TRYTStreamDetails* stream = [actualStream valueForKey:@"details"];
        if (!stream) {
    NSLog(@"Stream is nil, skipping");
    continue;
}
if (!stream || ![stream isKindOfClass:[TRYTStreamDetails class]]) {
    NSLog(@"Invalid stream object");
    continue;
}

        NSLog(@"type -> %i", [stream type]);
        NSLog(@"itag -> %i", [stream itag]);
        NSLog(@"mimetype -> %@", [stream mimetype]);
        NSLog(@"profile -> %@", [stream profile]);
        NSLog(@"height -> %i", [stream height]);
        NSLog(@"fps -> %i", [stream fps]);
        NSLog(@"quality -> %@", [stream quality]);


        NSLog(@"a3");
        if ([stream type] == 3) { continue; } // ignoring audio for now in case we chose a muxed stream :P
        if ([[stream profile] isEqualToString:@"vp8"]) { continue; }
        if ([[stream profile] isEqualToString:@"vp9"]) { continue; }
        if ([[stream profile] isEqualToString:@"av1"]) { continue; }
        if ([[stream profile] isEqualToString:@"high444"]) { continue; }
        if ([[stream profile] isEqualToString:@"high422"]) { continue; }
        if ([[stream profile] isEqualToString:@"high10"])  { continue; }
        if ([[stream profile] isEqualToString:@"main"]     && ![device canPlayH264MainProfile]) { continue; }
        if ([[stream profile] isEqualToString:@"extended"] && ![device canPlayH264HighProfile]) { continue; }
        if ([[stream profile] isEqualToString:@"high"]     && ![device canPlayH264HighProfile]) { continue; }
        NSLog(@"profile -> %@", [stream profile]);
        int currentVideoType = 0;

        // video rankings
        // 1 = tiny/144p
        // 2 = small/240p
        // 3 = medium/360p
        // 4 = large/480p
        // 5 = hd720
        // 6 = hd1080
        NSLog(@"a4");
        NSLog(@"[stream quality] -> %@", [stream quality]);
        if ([[stream quality] isEqualToString:@"tiny"]) {
            currentVideoType=1;
        } else if ([[stream quality] isEqualToString:@"small"]) {
            currentVideoType=2;
        } else if ([[stream quality] isEqualToString:@"medium"]) {
            currentVideoType=3;
        } else if ([[stream quality] isEqualToString:@"large"]) {
            currentVideoType=4;
        } else if ([[stream quality] isEqualToString:@"hd720"]) {
            currentVideoType=5;
        } else if ([[stream quality] isEqualToString:@"hd1080"]) {
            currentVideoType=6;
        }
        NSLog(@"a5");
        
        int closenessOfStream = abs(selectedVideo - currentVideoType);
        if (closenessOfStream < closenessToVideoRank) {
            closenessToVideoRank = closenessOfStream;
            currentlySelectedVideo = actualStream;
        } else if (closenessOfStream == closenessToVideoRank) {
            // the seperated streams are better than the muxed stream in general.
            TRYTStreamDetails* bestRankedStream = [actualStream URL];
            if ([bestRankedStream type] == 1) {
                closenessToVideoRank = closenessOfStream;
                currentlySelectedVideo = actualStream;
            }
        }
        NSLog(@"a6");
    }

NSLog(@"a7");
    TRYTStreamDetails *currentlySelectedVideoDetails = [currentlySelectedVideo URL];
    NSLog(@"Selected a %@ stream", [currentlySelectedVideoDetails quality]);

    return nil;
}

%end
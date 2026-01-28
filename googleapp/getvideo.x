// getvideo.x
// TubeReplacer
//
// Video detail request and parsing hooks
// Makes both /player (for streams) and /next (for likes) requests

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
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
    return NO; // THIS IS JUST FOR DEBUGGINGG!!!!!!!!!!

    return YES;
}

%end

%hook YTStream
+(id)selectStreamForVideo:(YTVideo*)video onWiFi:(BOOL)onWifi {
    NSArray *streams = [video streams];

    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    BOOL isRetina = [NSClassFromString(@"YTUtils") isRetinaDisplay];

    // video rankings
    // 1 = tiny/144p
    // 2 = small/240p
    // 3 = medium/360p
    // 4 = large/480p
    // 5 = hd720
    // 6 = hd1080

    // audio rankings
    // 1 = low audio
    // 2 = medium audio
    // 3 = high audio (i haven't seen this, but uhh praying :D)

    int selectedVideo = 0;
    int selectedAudio = 0;

    if (onWifi) {
        if (isRetina) {
            if (isPad) {
                selectedVideo = 6;
                selectedAudio = 3;
                // 1080p, best audio
            } else {
                selectedVideo = 5;
                selectedAudio = 3;
                // 720p, best audio
            }
        } else {
            if (isPad) {
                // we're using a slightly higher to get full resolution, even tho i think scaling might impact it
                selectedVideo = 6;
                selectedAudio = 3;
                // 1080p high audio
            } else {
                // iphone 3GS
                selectedVideo = 3;
                selectedAudio = 3;
                // 360p high audio
            }
        }
    } else {
        if (isRetina) {
            if (isPad) {
                selectedVideo = 5;
                selectedAudio = 1;
                // 720p, low audio
            } else {
                selectedVideo = 4;
                selectedAudio = 1;
                // 480p, low audio
            }
        } else {
            if (isPad) {
                selectedVideo = 5;
                selectedAudio = 1;
                // 720p low audio
            } else {
                selectedVideo = 2;
                selectedAudio = 1;
                // 240p low audio?
            }
        }
    }
    NSLog(@"Finding video with rank %i", selectedVideo);

    int closenessToVideoRank = 2147483647;
    TRYTStreamDetails *currentlySelectedVideo = nil;

    int closenessToAudioRank = 2147483647;
    TRYTStreamDetails *currentlySelectedAudio = nil;

    GIPDevice *device = [NSClassFromString(@"GIPDevice") currentDevice];
    for (TRYTStreamDetails *stream in streams) {
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
        int currentVideoType = 0;

        // video rankings
        // 1 = tiny/144p
        // 2 = small/240p
        // 3 = medium/360p
        // 4 = large/480p
        // 5 = hd720
        // 6 = hd1080
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
        
        int closenessOfStream = abs(selectedVideo - currentVideoType);
        if (closenessOfStream < closenessToVideoRank) {
            closenessToVideoRank = closenessOfStream;
            currentlySelectedVideo = stream;
        } else if (closenessOfStream == closenessToVideoRank) {
            // the seperated streams are better than the muxed stream in general. 
            if ([currentlySelectedVideo type] == 1) {
                closenessToVideoRank = closenessOfStream;
                currentlySelectedVideo = stream;
            }
        }
    }

    if ([currentlySelectedVideo type] == 1) { // muxed
        NSLog(@"Selected a %@ video stream (muxed)", [currentlySelectedVideo quality]);
        return currentlySelectedVideo; // we dont need to fetch audio for muxed data
    }

    for (TRYTStreamDetails *stream in streams) {
        if ([stream type] != 3) { continue; }
        if ([[stream mimetype] hasPrefix:@"audio/webm;"]) { continue; }

        int currentAudioType = 0;

        // audio rankings
        // 1 = low
        // 2 = medium
        // 3 = high
        if ([[stream audioQuality] isEqualToString:@"AUDIO_QUALITY_LOW"]) {
            currentAudioType=1;
        } else if ([[stream audioQuality] isEqualToString:@"AUDIO_QUALITY_MEDIUM"]) {
            currentAudioType=2;
        } else if ([[stream audioQuality] isEqualToString:@"AUDIO_QUALITY_HIGH"]) { // guess
            currentAudioType=3;
        }
        
        int closenessOfStream = abs(selectedAudio - currentAudioType);
        if (closenessOfStream < closenessToAudioRank) {
            closenessToAudioRank = closenessOfStream;
            currentlySelectedAudio = stream;
        }
    }

    NSLog(@"Selected a %@ video stream, mimetype -> %@", [currentlySelectedVideo quality], [currentlySelectedVideo mimetype]);
    NSLog(@"Selected a %@ audio stream", [currentlySelectedAudio audioQuality]);

    return [TRYTStreams initWithVideoStream:currentlySelectedVideo audioStream:currentlySelectedAudio];
}
%end

%hook YTPlayerController
-(void)setAndPlayVideoStream:(id)streams
{
  if ([self valueForKey:@"viewVisible_"] )
  {
    YTPlayerView *playerView = [self valueForKey:@"playerView_"];
    BOOL encrypted = [streams encrypted];
    [playerView setAirPlayAllowed:encrypted == 0];
    YTPlayer_iOS5 *player = [self valueForKey:@"player_"];
    if ([streams isKindOfClass:[TRYTStreams class]]) {
        [player setContentURL:streams];
    } else {
        [player setContentURL:[streams URL]];
    }
    
    [self playIfPermitted];
  }
}

%end

%hook YTPlayer_iOS5
    
-(void)setContentURL:(id)url
{
    if ([url isKindOfClass:[NSURL class]]) {
        return %orig; // muxed
    }

    TRYTStreams *streams = url;

    NSURL *videoStreamURL = [[streams videoStream] URL];
    NSURL *audioStreamURL = [[streams audioStream] URL];

    NSLog(@"videoStream -> %@", videoStreamURL);
    NSLog(@"audioStream -> %@", audioStreamURL);

    // return %orig(audioStreamURL);
    // videoStreamURL = [NSURL URLWithString:@"http://10.0.0.75:5500/480pvideo.mp4"];
    // videoStreamURL = [NSURL URLWithString:@"https://rr6---sn-ni5f-txbl.googlevideo.com/videoplayback?expire=1769393517&ei=DXl2aax3-pWx8g-mrt65CQ&ip=50.65.201.220&id=o-AHivQ_VNw4XoV79hPyFE4sjzHhgGP3tyckQnUbJLxKVH&itag=18&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&cps=0&met=1769371917%2C&mh=yL&mm=31%2C29&mn=sn-ni5f-txbl%2Csn-nx57ynss&ms=au%2Crdu&mv=m&mvi=6&pl=22&rms=au%2Cau&initcwndbps=3755000&bui=AW-iu_rH8oRAdYBxQXC1L9Fo7GZWZrqBJyTPHTmGZ1EhRupfuUGpj7OUiNVyw3m4aRvudw0XCM-hd2Rz&spc=q5xjPFkDbJUdvWI_XcBb&vprv=1&svpuc=1&mime=video%2Fmp4&rqh=1&cnr=14&ratebypass=yes&dur=623.641&lmt=1753340441716778&mt=1769371508&fvip=2&fexp=51552689%2C51565115%2C51565681%2C51580968&c=ANDROID&txp=1538534&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cbui%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Crqh%2Ccnr%2Cratebypass%2Cdur%2Clmt&sig=AJEij0EwRQIgMjvCydrH83t0RfhHf7lvEgtWV_twKPg-2BTlfX49whcCIQDcYMgIu56mKGbd_81MXMffYbcFKd6PdfYFZ2TkhlWD8A%3D%3D&lsparams=cps%2Cmet%2Cmh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Crms%2Cinitcwndbps&lsig=APaTxxMwRAIgEI_emmp8m4KFfYCYc3koxJT0xhZsKMeh-cCaKc7-gzoCIDM1h2vI9tR73k062qS5ihZc2E4pVkvjADWWmB4LonnM"];
    return %orig(videoStreamURL);

    [self pause];
    [self setPlaybackState:4]; // "Loading"
    [self setTotalTimeHint:0];
    [self removePlayerItemNotifications];
    [self createPlayerIfNeeded];

    // Now load the asset asynchronously
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoStreamURL options:nil];

    NSArray *keys = @[@"tracks"];

    [asset loadValuesAsynchronouslyForKeys:keys
                         completionHandler:^{

        dispatch_async(dispatch_get_main_queue(), ^{

            NSError *error = nil;
            AVKeyValueStatus status =
                [asset statusOfValueForKey:@"tracks" error:&error];

            NSLog(@"AVKeyValueStatusFailed %i", AVKeyValueStatusFailed);
            NSLog(@"AVKeyValueStatusCancelled %i", AVKeyValueStatusCancelled);
            if (status == AVKeyValueStatusLoaded)
            {
                NSLog(@"Asset load status good: %ld, error: %@", (long)status, error);
                AVPlayerItem *item =
                    [AVPlayerItem playerItemWithAsset:asset];
                [self removePlayerItemNotifications];
                [self addPlayerItemNotifications];

                // Use the property setter instead of direct member access
                id avPlayer = [self valueForKey:@"avPlayer_"];
                [avPlayer replaceCurrentItemWithPlayerItem:item];
            }
            else if (status == AVKeyValueStatusFailed)
            {
                NSError *playbackError =
                    [NSError errorWithPlaybackError:0];
                NSLog(@"Asset load status: %ld, error: %@", (long)status, error);
                id delegate = [self valueForKey:@"delegate_"];
                [delegate playbackDidFailWithError:playbackError];

                [self removePlayerItemNotifications];
            }
            else if (status == AVKeyValueStatusCancelled)
            {
                [self removePlayerItemNotifications];
            }
        });
    }];
}

%end
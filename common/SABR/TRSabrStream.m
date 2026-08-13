#import "TRSabrStream.h"
#include <Foundation/NSLock.h>
#include "video_streaming/BufferedRange.pbobjc.h"
#include <math.h>
#include "TRSabrHTTPConnection.h"
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSData.h>
#import "TRSabrStream+PartHandler.h"
#include <Foundation/NSArray.h>
#import "TRAdaptiveFormat.h"
#import "proto/generated/video_streaming/VideoPlaybackAbrRequest.pbobjc.h"
#import "common/potoken.h"
#import "common/YoutubeClientType.h"
#import "base64/NSData+Base64.h"

@implementation TRSabrStream : NSObject

-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId {
    [self startWebServerThreaded];
    NSString *decipheredStreamURL = [[TRPOTokenSolver sharedInstance] decipherUrl:streamURL signatureCipher:nil];
    
    self.currentlyRequesting = NO;
    self.networkQueue = [[[NSOperationQueue alloc] init] autorelease];
    self.networkQueue.maxConcurrentOperationCount = 1;

    // NSLog(@"stream URL -> %@ ustreamConfig -> %@", decipheredStreamURL, ustreamConfig);
    self.decipheredStreamURL = decipheredStreamURL;
    self.ustreamConfig = [NSData dataWithBase64EncodedString:[[ustreamConfig stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
    NSMutableDictionary *formatsDict = [NSMutableDictionary dictionary];
    for (TRAdaptiveFormat *format in formats) {
        formatsDict[@(format.itag)] = format;
    }
    self.formats = formatsDict;
    self.videoId = videoId;

    NSMutableArray *videoFormatsWeHave = [[NSMutableArray alloc] init];
    NSMutableArray *audioFormatsWeHave = [[NSMutableArray alloc] init];
    for (TRAdaptiveFormat *format in [self.formats allValues]) {
        if ([format.mimeType hasPrefix:@"audio"]) {
            [audioFormatsWeHave addObject:format];
        } else {
            [videoFormatsWeHave addObject:format];
        }
    }

    self.videoFormatsWeHave = videoFormatsWeHave;
    self.audioFormatsWeHave = audioFormatsWeHave;

    if ([[TRPOTokenSolver sharedInstance] isReadyToMintTokens]) {
        NSString *poTokenString = [[TRPOTokenSolver sharedInstance] mintPOTokenWithData:videoId];
        if (poTokenString) {
            self.poToken = [NSData dataWithBase64EncodedString:[[poTokenString stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
        } else {
            self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:videoId clientState:1]];
        }
    } else {
        self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:videoId clientState:1]];
    }

    [self requestAdditionalData:0];
    return self;
}

-(void)requestAdditionalData:(int)currentStreamTimeMS {
    NSLog(@"current stream ts -> %i", currentStreamTimeMS);
    if (!self.currentlyRequesting) {
        self.currentlyRequesting = YES;

        NSData *testReq = [self buildRequestBody:currentStreamTimeMS];

        [self makeStreamingRequestWithBody:testReq andCallback:^(NSData *response, NSError *error) {
            __block NSMutableDictionary *currentlyParsingDatas = [[NSMutableDictionary alloc] init];
            __block NSMutableDictionary *currentlyParsingHeaders = [[NSMutableDictionary alloc] init];
            [TRUmpReader read:response handlePartWith:^(TRUmpPart *part) {
                [self handlePart:part currentlyParsingDatas:&currentlyParsingDatas currentlyParsingHeaders:&currentlyParsingHeaders];
                [part release];
            }];

            self.currentlyRequesting = NO;

            if (((self.videoStream == nil || !self.videoStream.isReadyForPlayback || self.audioStream == nil || !self.audioStream.isReadyForPlayback)) && self.requestNumber < 10) {
                NSLog(@"not enough data to start stream! trying again...");
                [self requestAdditionalData:currentStreamTimeMS];
            }
            // NSLog(@"response -> %@", response); 
        }];
    }

}

-(ClientAbrState*)createClientABRState:(int)currentStreamTimeMS { //WithVideo:(TRAdaptiveFormat*)video andAudio:(TRAdaptiveFormat*)audio {
    ClientAbrState *state = [[ClientAbrState alloc] init];
    // viewport, i *could* spend the time to bother figuring out what it actually is, but that sounds annoying, and chances are they'd be watching in landscape.
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (screenBounds.size.width > screenBounds.size.height) { // assume landscape
        state.clientViewportWidth = (int)screenBounds.size.width * scale;
        state.clientViewportHeight = (int)screenBounds.size.height * scale;
    } else {
        state.clientViewportWidth = (int)screenBounds.size.height * scale;
        state.clientViewportHeight = (int)screenBounds.size.width * scale;
    }
    state.preferVp9 = false;
    state.playerTimeMs = currentStreamTimeMS;

    state.playbackRate = 1.0;
    state.drcEnabled = true; // think this is the stable volume stuff
    state.visibility = 1;
    state.clientViewportIsFlexible = false;
    state.enabledTrackTypesBitfield = 0;

    state.playerState = 0;

    state.stickyResolution = 720;
    state.enableVoiceBoost = false;


    // PlaybackAuthorization *playerAuth = [[PlaybackAuthorization alloc] init];

    // NSMutableArray *authFormats = [[NSMutableArray alloc] init];
    // AuthorizedFormat *authFormat1 = [[AuthorizedFormat alloc] init];

    // authFormat1.trackType = 1;
    // authFormat1.isHdr = false;

    // [authFormats addObject:authFormat1];

    AuthorizedFormat *authFormat2 = [[AuthorizedFormat alloc] init];

    authFormat2.trackType = 2;
    authFormat2.isHdr = false;
    

    // [authFormats addObject:authFormat2];

    // playerAuth.authorizedFormatsArray = authFormats;

    // state.playbackAuthorization = playerAuth;

    return state;
}

-(StreamerContext*)createStreamerContext {
    StreamerContext *context = [[StreamerContext alloc] init];
    YoutubeClientType *clientType = [YoutubeClientType webMobileClient];

    StreamerContext_ClientInfo *clientInfo = [[StreamerContext_ClientInfo alloc] init];

    clientInfo.clientName = [clientType.nameProto intValue];
    clientInfo.clientVersion = clientType.version;
    clientInfo.osName = clientType.osName;
    clientInfo.osVersion = clientType.osVersion;

    // clientInfo.acceptLanguage = [[NSLocale preferredLanguages] firstObject];
    // clientInfo.acceptRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];

    context.clientInfo = clientInfo;

    if (self.poToken) {
        context.poToken = self.poToken;
    } else {
        if ([[TRPOTokenSolver sharedInstance] isReadyToMintTokens]) {
            NSString *poTokenString = [[TRPOTokenSolver sharedInstance] mintPOTokenWithData:self.videoId];
            if (poTokenString) {
                self.poToken = [NSData dataWithBase64EncodedString:[[poTokenString stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
                context.poToken = self.poToken;
            } else {
                context.poToken = self.coldstart;
            }
            
        } else {
            context.poToken = self.coldstart;
        }
    }

    if (self.playbackCookie)
        context.playbackCookie = [self.playbackCookie data];

    
    return context;
}

-(NSData*)buildRequestBody:(int)currentStreamTimeMS {
    VideoPlaybackAbrRequest *request = [[VideoPlaybackAbrRequest alloc] init];

    request.streamerContext = [self createStreamerContext];
    request.videoPlaybackUstreamerConfig = self.ustreamConfig;

    NSMutableDictionary *videoFormatsIdsWeHave = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *audioFormatsIdsWeHave = [[NSMutableDictionary alloc] init];
    NSMutableArray *bufferedRanges = [[NSMutableArray alloc] init];

    for (TRAdaptiveFormat *format in self.formats.allValues) {
        FormatId *formatId = [[FormatId alloc] init];
        formatId.itag = format.itag;

        long long convertedValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:format.lastModified];
        [scanner scanLongLong:&convertedValue];
        formatId.lastModified = (unsigned long long)convertedValue;
        formatId.xtags = @"";
        if (format.xtags) {
            formatId.xtags = format.xtags;
        }

        if ([format.mimeType hasPrefix:@"audio"]) {
            audioFormatsIdsWeHave[@(format.itag)] = formatId;
        } else {
            videoFormatsIdsWeHave[@(format.itag)] = formatId;
        }
    }

    if (self.videoStream != nil) {
        BufferedRange *bufferedRange = [[BufferedRange alloc] init];
        bufferedRange.formatId = videoFormatsIdsWeHave[@(self.videoStream.itag)];
        [self.videoStream updateBufferTime];
        bufferedRange.startTimeMs = llround(self.videoStream.earliestTimestampBuffered*1000);
        bufferedRange.startSegmentIndex = self.videoStream.earliestSegmentIndexBuffered;
        bufferedRange.durationMs = llround(self.videoStream.latestTimestampBuffered*1000) - llround(self.videoStream.earliestTimestampBuffered*1000);
        bufferedRange.endSegmentIndex = self.videoStream.latestSegmentIndexBuffered;
        [bufferedRanges addObject:bufferedRange];
    }

    request.preferredVideoFormatIdsArray = [[videoFormatsIdsWeHave allValues] mutableCopy];
    request.preferredAudioFormatIdsArray = [[audioFormatsIdsWeHave allValues] mutableCopy];
    request.preferredSubtitleFormatIdsArray = [[NSMutableArray alloc] init];

    request.field1000Array = [[NSMutableArray alloc] init];
    request.bufferedRangesArray = bufferedRanges;

    // if (self.currentPlayerTimeFunction != nil)
    //     state.playerTimeMs = llround(self.currentPlayerTimeFunction()*1000);
    // else
    //     state.playerTimeMs = 0;

    request.clientAbrState = [self createClientABRState:currentStreamTimeMS];

    return [request data];
}

-(void)makeStreamingRequestWithBody:(NSData*)body andCallback:(void (^)(NSData *, NSError *))callback {
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&rn=%i", self.decipheredStreamURL, self.requestNumber]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-protobuf" forHTTPHeaderField:@"content-type"];
    [request setValue:@"identity" forHTTPHeaderField:@"accept-encoding"];
    [request setValue:@"application/vnd.yt-ump" forHTTPHeaderField:@"accept"];
    

    self.requestNumber += 1;
    // GTMHTTPFetcher *fetcher = [NSClassFromString(@"GTMHTTPFetcher") fetcherWithRequest:request];
    // if (auth != nil)
    //     [fetcher setAuthorizer:auth];

    // [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
    [NSURLConnection sendAsynchronousRequest:request queue:self.networkQueue completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        callback(response, error);
    }];
}

-(NSString*)createHLSRootManifest {
    NSMutableString *hlsManifest = [[NSMutableString alloc] init];
    [hlsManifest appendString:@"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-INDEPENDENT-SEGMENTS\n"];


    [hlsManifest appendString:@"#EXT-X-STREAM-INF:BANDWIDTH=1000000\nvideo.m3u8\n"];
    // [hlsManifest appendString:@"#EXT-X-STREAM-INF:\naudio.m3u8\n"]; // todo: no audio for now

    // finish
    NSString *final = [hlsManifest copy];
    [hlsManifest release];
    return final;
}

-(void)startWebServer {
    self.httpServer = [[TRSabrHTTPServer alloc] init];
	
    self.httpServer.stream = self;
	[self.httpServer setConnectionClass:[TRSabrHTTPConnection class]];
    

	NSError *error;
	BOOL success = [self.httpServer start:&error];
	
	if(!success)
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}

    

    // NSLog(@"http server at -> http://%@:%hu/", [self.httpServer [self.httpServer port]);
}

- (void)startWebServerThreaded {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self startWebServer]; // TODO: If the device goes to sleep, the HTTP server does not come back online. Also an issue for background playback

        while (self.httpServer) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                        beforeDate:[NSDate distantFuture]];
        }
    });
}

-(void)dealloc {
    NSLog(@"deallocating!!!");
    [_httpServer stop];
    [_httpServer release];
    [_videoStream release];
    [_audioStream release];
    [_playbackCookie release];
    [_videoFormatsWeHave release];
    [_audioFormatsWeHave release];
    [_formats release];
    [_poToken release];
    [_coldstart release];
    [_videoId release];
    [_ustreamConfig release];
    [_decipheredStreamURL release];

    [super dealloc];
}
@end
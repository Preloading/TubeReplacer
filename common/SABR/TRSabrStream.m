#import "TRSabrStream.h"
#include <CoreFoundation/CFRunLoop.h>
#include <Foundation/NSOperation.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSObjCRuntime.h>
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
#import "TRSabrRequest.h"

@implementation TRSabrStream : NSObject

-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId {
    self = [super init];
    if (!self) return nil;
    self.isStreamBad = NO;
    self.isStreamReady = NO;

    NSString *decipheredStreamURL = [[TRPOTokenSolver sharedInstance] decipherUrl:streamURL signatureCipher:nil];

    // NSLog(@"stream URL -> %@ ustreamConfig -> %@", decipheredStreamURL, ustreamConfig);
    if (decipheredStreamURL != nil)
        self.decipheredStreamURL = decipheredStreamURL;
    else
        self.decipheredStreamURL = streamURL;
    self.ustreamConfig = [NSData dataWithBase64EncodedString:[[ustreamConfig stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
    NSMutableDictionary *formatsDict = [NSMutableDictionary dictionary];
    for (TRAdaptiveFormat *format in formats) {
        formatsDict[@(format.itag)] = format;
    }
    self.formats = formatsDict;
    self.videoId = videoId;

    return self;
}

-(void)start {
    self.currentlyRequestingInNormal = NO;
    self.currentlyRequestingInFastTrack = NO;
    self.networkQueue = [[[NSOperationQueue alloc] init] autorelease];
    self.networkQueue.maxConcurrentOperationCount = 2;

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
    [videoFormatsWeHave release];
    [audioFormatsWeHave release];
    
    self.videoStream = [[[TRSabrMedia alloc] init] autorelease];
    self.audioStream = [[[TRSabrMedia alloc] init] autorelease];

    self.isStreamReady = YES;
    [self startWebServerThreaded];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidBecomeActive:)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];

    if ([[TRPOTokenSolver sharedInstance] isReadyToMintTokens]) {
        NSString *poTokenString = [[TRPOTokenSolver sharedInstance] mintPOTokenWithData:self.videoId];
        if (poTokenString) {
            self.poToken = [NSData dataWithBase64EncodedString:[[poTokenString stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
        } else {
            self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:self.videoId clientState:1]];
        }
    } else {
        self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:self.videoId clientState:1]];
    }

    [self requestAdditionalData:0 state:TRSabrBufferingFastTrack];
}

-(void)declareStreamBad {
    self.isStreamBad = YES;
    NSLog(@"SABR stream is unhealty! Switching streams...");
    [self cleanup];
    self.reloadPlayerFunction();
}

-(void)requestAdditionalData:(int)currentStreamTimeMS state:(TRSabrBufferingType)bufferingState {
    NSLog(@"current stream ts -> %i", currentStreamTimeMS);
    if (self.currentlyRequestingInNormal && bufferingState == TRSabrBufferingNormal) {
        return;
    } else if (bufferingState == TRSabrBufferingNormal) {
        self.currentlyRequestingInNormal = YES;
    }

    if (self.currentlyRequestingInFastTrack && bufferingState == TRSabrBufferingFastTrack) {
        return;
    } else if (bufferingState == TRSabrBufferingFastTrack) {
        self.currentlyRequestingInFastTrack = YES;
    }

    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&rn=%i", self.decipheredStreamURL, self.requestNumber]];
    NSData *requestBody = [self buildRequestBody:currentStreamTimeMS];
    self.requestNumber += 1;

    __block NSMutableDictionary *currentlyParsingDatas = [[NSMutableDictionary alloc] init];
    __block NSMutableDictionary *currentlyParsingHeaders = [[NSMutableDictionary alloc] init];

    TRSabrRequest *sabrRequest = [[TRSabrRequest alloc] init];

    [sabrRequest startRequestWithURL:requestURL body:requestBody auth:self.authentication partCallback:^(TRUmpPart *part) {
        [self handlePart:part currentlyParsingDatas:&currentlyParsingDatas currentlyParsingHeaders:&currentlyParsingHeaders];
    } completionCallback:^(NSError *error) {
        if (!self.isStreamReady) {
            [currentlyParsingDatas release];
            [currentlyParsingHeaders release];
            return;
        }
        if (error) {
            NSLog(@"an error occured! error -> %@", error);
            [currentlyParsingDatas release];
            [currentlyParsingHeaders release];
            [self declareStreamBad];
            return;
        }
        [currentlyParsingDatas release];
        [currentlyParsingHeaders release];


        NSLog(@"we now have these video segments -> %@", [self.videoStream.segmentData allKeys]);
        NSLog(@"we now have these audio segments -> %@", [self.audioStream.segmentData allKeys]);

        if (bufferingState == TRSabrBufferingFastTrack)
            self.currentlyRequestingInFastTrack = NO;
        else
            self.currentlyRequestingInNormal = NO;

        if (((self.videoStream == nil || !self.videoStream.isReadyForPlayback || self.audioStream == nil || !self.audioStream.isReadyForPlayback)) && self.isStreamReady) {
            if (self.requestNumber > 10) {
                [self declareStreamBad];
            } else {
                NSLog(@"not enough data to start stream! requesting again...");
                [self requestAdditionalData:currentStreamTimeMS state:bufferingState];
            }
        }
    }];
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

    // state.stickyResolution = 720;
    state.enableVoiceBoost = false;


    // PlaybackAuthorization *playerAuth = [[PlaybackAuthorization alloc] init];

    // NSMutableArray *authFormats = [[NSMutableArray alloc] init];
    // AuthorizedFormat *authFormat1 = [[AuthorizedFormat alloc] init];

    // authFormat1.trackType = 1;
    // authFormat1.isHdr = false;

    // [authFormats addObject:authFormat1];

    // AuthorizedFormat *authFormat2 = [[AuthorizedFormat alloc] init];

    // authFormat2.trackType = 2;
    // authFormat2.isHdr = false;
    

    // [authFormats addObject:authFormat2];

    // playerAuth.authorizedFormatsArray = authFormats;

    // state.playbackAuthorization = playerAuth;

    return state;
}

-(StreamerContext*)createStreamerContext {
    StreamerContext *context = [[StreamerContext alloc] init];

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    YoutubeClientType *clientType = [YoutubeClientType webClient];
    if ([preferences[@"StreamType"] isEqualToString:@"mweb"]) {
        clientType = [YoutubeClientType webMobileClient];
    } else if ([preferences[@"StreamType"] isEqualToString:@"visionos"]) {
        clientType = [YoutubeClientType visionOSClient];
    } else if ([preferences[@"StreamType"] isEqualToString:@"android"]) {
        clientType = [YoutubeClientType androidClient];
    } else if ([preferences[@"StreamType"] isEqualToString:@"androidvr"]) {
        clientType = [YoutubeClientType androidVrClient];
    }

    StreamerContext_ClientInfo *clientInfo = [[StreamerContext_ClientInfo alloc] init];

    clientInfo.clientName = [clientType.nameProto intValue];
    clientInfo.clientVersion = clientType.version;
    clientInfo.osName = clientType.osName;
    clientInfo.osVersion = clientType.osVersion;

    // clientInfo.acceptLanguage = [[NSLocale preferredLanguages] firstObject];
    // clientInfo.acceptRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];

    context.clientInfo = clientInfo;
    [clientInfo release];

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
    VideoPlaybackAbrRequest *request = [[[VideoPlaybackAbrRequest alloc] init] autorelease];

    request.streamerContext = [[self createStreamerContext] autorelease];
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
        [formatId release];
    }

    // if (self.videoStream != nil) {
    //     BufferedRange *bufferedRange = [[BufferedRange alloc] init];
    //     bufferedRange.formatId = videoFormatsIdsWeHave[@(self.videoStream.itag)];
    //     [self.videoStream updateBufferTime];
    //     bufferedRange.startTimeMs = llround(self.videoStream.earliestTimestampBuffered*1000);
    //     bufferedRange.startSegmentIndex = self.videoStream.earliestSegmentIndexBuffered;
    //     bufferedRange.durationMs = llround(self.videoStream.latestTimestampBuffered*1000) - llround(self.videoStream.earliestTimestampBuffered*1000);
    //     bufferedRange.endSegmentIndex = self.videoStream.latestSegmentIndexBuffered;
    //     [bufferedRanges addObject:bufferedRange];
    //     [bufferedRange release];
    // }

    // if (self.audioStream != nil) {
    //     BufferedRange *bufferedRange = [[BufferedRange alloc] init];
    //     bufferedRange.formatId = audioFormatsIdsWeHave[@(self.audioStream.itag)];
    //     [self.audioStream updateBufferTime];
    //     bufferedRange.startTimeMs = llround(self.audioStream.earliestTimestampBuffered*1000);
    //     bufferedRange.startSegmentIndex = self.audioStream.earliestSegmentIndexBuffered;
    //     bufferedRange.durationMs = llround(self.audioStream.latestTimestampBuffered*1000) - llround(self.audioStream.earliestTimestampBuffered*1000);
    //     bufferedRange.endSegmentIndex = self.audioStream.latestSegmentIndexBuffered;
    //     [bufferedRanges addObject:bufferedRange];
    //     [bufferedRange release];
    // }

    request.preferredVideoFormatIdsArray = [[[videoFormatsIdsWeHave allValues] mutableCopy] autorelease];
    request.preferredAudioFormatIdsArray = [[[audioFormatsIdsWeHave allValues] mutableCopy] autorelease];
    request.preferredSubtitleFormatIdsArray = [[[NSMutableArray alloc] init] autorelease];

    [videoFormatsIdsWeHave release];
    [audioFormatsIdsWeHave release];

    request.field1000Array = [[[NSMutableArray alloc] init] autorelease];
    request.bufferedRangesArray = bufferedRanges;
    [bufferedRanges release];

    // if (self.currentPlayerTimeFunction != nil)
    //     state.playerTimeMs = llround(self.currentPlayerTimeFunction()*1000);
    // else
    //     state.playerTimeMs = 0;

    request.clientAbrState = [[self createClientABRState:currentStreamTimeMS] autorelease];

    return [request data];
}

-(NSString*)createHLSRootManifest {
    NSMutableString *hlsManifest = [[NSMutableString alloc] init];
    [hlsManifest appendString:@"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-INDEPENDENT-SEGMENTS\n"];


    [hlsManifest appendString:@"#EXT-X-MEDIA:GROUP-ID=\"audio\",NAME=\"Audio Track\",TYPE=AUDIO,DEFAULT=YES,AUTOSELECT=YES,URI=\"audio.m3u8\"\n"];
    [hlsManifest appendString:@"#EXT-X-STREAM-INF:BANDWIDTH=1000000,AUDIO=\"audio\"\nvideo.m3u8\n"];

    // finish
    NSString *final = [hlsManifest copy];
    [hlsManifest release];
    return final;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%u", self.httpServer.port]];

    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:requestURL] autorelease];
    [request setTimeoutInterval:0.5];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
       if (error) {
            NSLog(@"reloading player...");
            [self stopWebServer];
            [self startWebServerThreaded];
            // self.reloadPlayerFunction();
       }
    }];
}

-(void)stopHTTPServerOnThread {
    self.httpServer.stream = nil;
    [self.httpServer stop];
    self.httpServer = nil;

    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)stopWebServer {
    if (!self.httpServer || !self.httpServerThread) return;

    [self performSelector:@selector(stopHTTPServerOnThread)
            onThread:self.httpServerThread 
            withObject:nil 
            waitUntilDone:YES];

    // [self.httpServerThread release];
    self.httpServerThread = nil;
}

-(void)startWebServer {
    self.httpServer = [[[TRSabrHTTPServer alloc] init] autorelease];
	
    self.httpServer.stream = self;
	[self.httpServer setConnectionClass:[TRSabrHTTPConnection class]];
    
    if (self.port != 0) {
        [self.httpServer setPort:self.port];
    }

	NSError *error;
	BOOL success = [self.httpServer start:&error];
	self.port = self.httpServer.port;

	if(!success)
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}

    while (self.httpServer) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                        beforeDate:[NSDate distantFuture]];
        }
    }

    // NSLog(@"http server at -> http://%@:%hu/", [self.httpServer [self.httpServer port]);
}

- (void)startWebServerThreaded {
    self.httpServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startWebServer) object:nil];
    [self.httpServerThread start];
}

// segment idx starts at 0
-(void)handleBufferingWithCurrentSegment:(uint16_t)segmentIdx mediaType:(TRSabrMediaType)mediaType {
    if (!self.isStreamReady)
        return; // bad things will happen
    if (mediaType == TRSabrMediaTypeVideo) {
        double requestedVideoSegmentStart = [self.videoStream.segmentIndexesCombined[segmentIdx] doubleValue]/(double)self.videoStream.timescale;
        double requestedVideoSegmentEnd = requestedVideoSegmentStart + ([self.videoStream.segmentIndexes[segmentIdx] doubleValue]/(double)self.videoStream.timescale);


        for (NSNumber *curSegmentIdx in self.videoStream.segmentData.allKeys) {
            double startIdx = [self.videoStream.segmentIndexesCombined[[curSegmentIdx intValue]-1] doubleValue]/(double)self.videoStream.timescale;
            double endIdx = startIdx + ([self.videoStream.segmentIndexes[[curSegmentIdx intValue]-1] doubleValue]/(double)self.videoStream.timescale);

            // the first segment is needed for immediete resume if we lock the phone.
            if ([curSegmentIdx intValue] == 1 || [curSegmentIdx intValue]-1 == segmentIdx || [curSegmentIdx intValue] == segmentIdx || [curSegmentIdx intValue] == segmentIdx+1 || [curSegmentIdx intValue] == segmentIdx+2 || [curSegmentIdx intValue] == segmentIdx+3 || [curSegmentIdx intValue] == segmentIdx+4) {}
            else if (endIdx+10 < requestedVideoSegmentStart) {
                // 10 second cache in the past expired
                [self.videoStream.segmentData removeObjectForKey:curSegmentIdx];
            }
            else if (startIdx > requestedVideoSegmentStart + 45) {
                // it's 50 seconds into the future, cached too fars
                [self.videoStream.segmentData removeObjectForKey:curSegmentIdx];
            }
        }

        // clean out segments not connected to the currently requested


        // find segment borders
        // int leftEdge = segmentIdx-1;
        // int rightEdge = segmentIdx+1;

        // // left
        // while (self.videoStream.segmentData[@(leftEdge)] != nil) {
        //     leftEdge--;
        // }

        // // right
        // while (self.videoStream.segmentData[@(rightEdge)] != nil) {
        //     leftEdge++;
        // }
        // [self.videoStream updaterBufferTime:segmentIdx+1];

        // if (self.videoStream.segmentData[@(self.videoStream.segmentIndexes.count)] != nil)
        //     return;

        if (self.videoStream.segmentData[@(segmentIdx+1)] == nil) {
            // we are in the middle of the currently requested segment, we need to get the video right now as we are likely buffering
            NSLog(@"potential buffering may happen!");
            [self requestAdditionalData:requestedVideoSegmentStart*1000 state:TRSabrBufferingFastTrack]; // providing the acurate time should be fine here
            return;
        }
        if ((self.videoStream.segmentIndexes.count > segmentIdx) || (self.videoStream.segmentData[@(segmentIdx+2)] == nil && self.videoStream.segmentIndexes.count > segmentIdx+1)) {
            NSLog(@"standard buffering occuring");
            [self requestAdditionalData:requestedVideoSegmentEnd*1000  state:TRSabrBufferingNormal];
        }
    } else if (mediaType == TRSabrMediaTypeAudio) {
        double requestedAudioSegmentStart = [self.audioStream.segmentIndexesCombined[segmentIdx] doubleValue]/(double)self.audioStream.timescale;
        double requestedAudioSegmentEnd = requestedAudioSegmentStart + ([self.audioStream.segmentIndexes[segmentIdx] doubleValue]/(double)self.audioStream.timescale);


        for (NSNumber *curSegmentIdx in self.audioStream.segmentData.allKeys) {
            double startIdx = [self.audioStream.segmentIndexesCombined[[curSegmentIdx intValue]-1] doubleValue]/(double)self.audioStream.timescale;
            double endIdx = startIdx + ([self.audioStream.segmentIndexes[[curSegmentIdx intValue]-1] doubleValue]/(double)self.audioStream.timescale);


            if ([curSegmentIdx intValue]-1 == segmentIdx || [curSegmentIdx intValue] == segmentIdx || [curSegmentIdx intValue] == segmentIdx+1 || [curSegmentIdx intValue] == segmentIdx+2 || [curSegmentIdx intValue] == segmentIdx+3 || [curSegmentIdx intValue] == segmentIdx+4) {}
            else if (endIdx+10 < requestedAudioSegmentStart) {
                // 10 second cache in the past expired
                [self.audioStream.segmentData removeObjectForKey:curSegmentIdx];
            }
            else if (startIdx > requestedAudioSegmentStart + 50) {
                // it's 50 seconds into the future, cached too fars
                [self.audioStream.segmentData removeObjectForKey:curSegmentIdx];
            }
        }

        if (self.audioStream.segmentData[@(self.audioStream.segmentIndexes.count)] != nil)
            return;

        if (self.audioStream.segmentData[@(segmentIdx)] == nil) { // idk why this actually works the best, from what i can tell this should be +1 since data is based on sabr's stuff, with the header being 0, and segment idx's 0 is the first segment
            // we are in the middle of the currently requested segment, we need to get the video right now as we are likely buffering
            NSLog(@"potential buffering may happen!");
            [self requestAdditionalData:requestedAudioSegmentStart*1000 state:TRSabrBufferingFastTrack]; // providing the acurate time should be fine here
            return;
        }
        if ((self.audioStream.segmentData[@(segmentIdx+1)] == nil && self.audioStream.segmentIndexes.count > segmentIdx) || (self.audioStream.segmentData[@(segmentIdx+2)] == nil && self.audioStream.segmentIndexes.count > segmentIdx+1)) {
            NSLog(@"standard buffering occuring");
            [self requestAdditionalData:requestedAudioSegmentEnd*1000  state:TRSabrBufferingNormal];
        }
    }
}

-(NSURL*)URL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%u/master.m3u8", self.httpServer.port]];
}

-(int)format {
    return 5;
}

-(BOOL)encrypted {
    return NO;
}

-(BOOL)isWidevine {
    return NO;
}

// it's intended to be able to restart is cleanup is called.
-(void)cleanup {
    self.isStreamReady = false;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopWebServer];
    [_videoStream release];
    [_audioStream release];
    [_playbackCookie release];
    [_poToken release];
    [_coldstart release];
    [_networkQueue release];
    [_videoFormatsWeHave release];
    [_audioFormatsWeHave release];
}

-(void)dealloc {
    NSLog(@"deallocating!!!");
    [_videoId release];
    [_ustreamConfig release];
    [_decipheredStreamURL release];
    [_formats release];
    [self cleanup];

    [super dealloc];
}
@end
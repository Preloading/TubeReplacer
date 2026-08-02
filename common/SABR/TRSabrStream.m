#import "TRSabrStream.h"
#include <Foundation/NSArray.h>
#import "TRAdaptiveFormat.h"
#import "proto/generated/video_streaming/VideoPlaybackAbrRequest.pbobjc.h"
#import "common/potoken.h"
#import "common/YoutubeClientType.h"
#import "base64/NSData+Base64.h"

@implementation TRSabrStream : NSObject

-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId {
    NSString *decipheredStreamURL = [[TRPOTokenSolver sharedInstance] decipherUrl:streamURL signatureCipher:nil];

    NSLog(@"stream URL -> %@ ustreamConfig -> %@", decipheredStreamURL, ustreamConfig);
    self.decipheredStreamURL = decipheredStreamURL;
    self.ustreamConfig = [NSData dataWithBase64EncodedString:[[ustreamConfig stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
    self.formats = formats;
    self.videoId = videoId;

    NSMutableArray *videoFormatsWeHave = [[NSMutableArray alloc] init];
    NSMutableArray *audioFormatsWeHave = [[NSMutableArray alloc] init];
    for (TRAdaptiveFormat *format in self.formats) {
        if ([format.mimeType hasPrefix:@"audio"]) {
            [audioFormatsWeHave addObject:format];
        } else {
            [videoFormatsWeHave addObject:format];
        }
    }

    self.videoFormatsWeHave = videoFormatsWeHave;
    self.audioFormatsWeHave = audioFormatsWeHave;

    NSLog(@"a");

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

    NSData *testReq = [self buildRequestBody];
    NSLog(@"buildRequestBody -> %@", testReq);
    [self makeStreamingRequestWithBody:testReq andCallback:^(NSData *response, NSError *error) {
        // NSLog(@"response -> %@", response); 
    }];
    return self;
}

-(TRAdaptiveFormat*)pickVideoFormat:(NSArray*)videoFormatsWeHave {
    // TODO: this is genuienly awful right now, i will fix this later. I just want to get *something* from sabr atm
    for (TRAdaptiveFormat *format in videoFormatsWeHave) {
        if ([format.quality isEqualToString:@"hd720"]) {
            return format;
        }
    }
    return nil;
}

-(TRAdaptiveFormat*)pickAudioFormat:(NSArray*)audioFormatsWeHave {
    // TODO: this is genuienly awful right now, i will fix this later. I just want to get *something* from sabr atm
    for (TRAdaptiveFormat *format in audioFormatsWeHave) {
        if ([format.mimeType rangeOfString:@"mp4a"].location != NSNotFound) {
            return format;
        }
    }
    return nil;
}

-(void)test {

}

//   private async fetchAndProcessSegments(
//     abrState: ClientAbrState,
//     selectedAudioFormat: SabrFormat,
//     selectedVideoFormat: SabrFormat
//   ): Promise<void> {
//     const initializedVideoFormat = this.initializedFormatsMap.get(FormatKeyUtils.fromFormat(selectedVideoFormat) || '');
//     const initializedAudioFormat = this.initializedFormatsMap.get(FormatKeyUtils.fromFormat(selectedAudioFormat) || '');

//     // Cache buffered ranges in case the request fails, allowing retries to use the same values.
//     if (!this.cachedBufferedRanges?.length) {
//       this.cachedBufferedRanges = this.buildBufferedRanges(initializedVideoFormat, initializedAudioFormat);
//     }

//     const requestBody = this.buildRequestBody(abrState, selectedAudioFormat, selectedVideoFormat);

//     this.mediaHeadersProcessed = false;
//     const response = await this.makeStreamingRequest(requestBody);
//     const processedParts = await this.processStreamingResponse(response);

//     if (!processedParts.length) {
//       throw new Error('No valid parts received from server.');
//     } else if ((this.streamProtectionStatus?.status || 0) >= 2 && !processedParts.includes(UMPPartId.MEDIA)) {
//       throw new Error('No media parts or protocol updates received from server.');
//     }

//     if (
//       processedParts.includes(UMPPartId.MEDIA_HEADER) &&
//       (initializedVideoFormat?.lastMediaHeaders?.length && initializedAudioFormat?.lastMediaHeaders?.length) ||
//       (abrState.enabledTrackTypesBitfield !== 0 && this.mainFormat?.lastMediaHeaders?.length)
//     ) {
//       this.mediaHeadersProcessed = true;
//     }
//   }

//   private buildRequestBody(
//     abrState: ClientAbrState,
//     selectedAudioFormat: SabrFormat,
//     selectedVideoFormat: SabrFormat
//   ): Uint8Array {
//     if (!this.videoPlaybackUstreamerConfig)
//       throw new Error('Video playback ustreamer config must be set before starting.');
//     if (!this.clientInfo)
//       throw new Error('Client info must be set before starting.');

//     const bufferedRanges = this.cachedBufferedRanges || [];
//     const { sabrContexts, unsentSabrContexts } = this.prepareSabrContexts();

//     const { selectedFormatIds, updatedBufferedRanges } = this.prepareFormatSelections(
//       [ selectedVideoFormat, selectedAudioFormat ],
//       bufferedRanges
//     );

//     return VideoPlaybackAbrRequest.encode({
//       clientAbrState: abrState,
//       preferredAudioFormatIds: [ selectedAudioFormat ],
//       preferredVideoFormatIds: [ selectedVideoFormat ],
//       preferredSubtitleFormatIds: [],
//       selectedFormatIds,
//       videoPlaybackUstreamerConfig: base64ToU8(this.videoPlaybackUstreamerConfig),
//       streamerContext: {
//         sabrContexts,
//         unsentSabrContexts,
//         poToken: this.poToken ? base64ToU8(this.poToken) : undefined,
//         playbackCookie: this.nextRequestPolicy?.playbackCookie ? PlaybackCookie.encode(this.nextRequestPolicy.playbackCookie).finish() : undefined,
//         clientInfo: this.clientInfo
//       },
//       bufferedRanges: updatedBufferedRanges,
//       field1000: []
//     }).finish();
//   }

-(ClientAbrState*)createClientABRStateWithVideo:(TRAdaptiveFormat*)video andAudio:(TRAdaptiveFormat*)audio {
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
    state.playerTimeMs = 0;
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
//       "clientAbrState": {
//     "timeSinceLastManualFormatSelectionMs": "970799435",
//     "lastManualDirection": 1,
//     "lastManualSelectedResolution": 1080,
//     "detailedNetworkType": 0,
//     "clientViewportWidth": 640,
//     "clientViewportHeight": 360,
//     "clientBitrateCapBytesPerSec": "0",
//     "stickyResolution": 0,
//     "clientViewportIsFlexible": false,
//     "bandwidthEstimate": "21649875",
//     "minAudioQuality": 0,
//     "maxAudioQuality": 0,
//     "videoQualitySetting": 0,
//     "audioRoute": 0,
//     "playerTimeMs": "0",
//     "timeSinceLastSeek": "781",
//     "dataSaverMode": false,
//     "networkMeteredState": 0,
//     "visibility": 5,
//     "playbackRate": 0,
//     "elapsedWallTimeMs": "799",
//     "timeSinceLastActionMs": "277",
//     "enabledTrackTypesBitfield": 0,
//     "maxPacingRate": 0,
//     "playerState": "0",
//     "drcEnabled": true,
//     "field48": 0,
//     "field50": 0,
//     "field51": 0,
//     "sabrReportRequestCancellationInfo": 0,
//     "disableStreamingXhr": false,
//     "field57": "48",
//     "preferVp9": false,
//     "av1QualityThreshold": 8192,
//     "field60": 0,
//     "isPrefetch": false,
//     "sabrSupportQualityConstraints": false,
//     "sabrLicenseConstraint": "",
//     "allowProximaLiveLatency": 0,
//     "sabrForceProxima": 0,
//     "field67": 0,
//     "sabrForceMaxNetworkInterruptionDurationMs": "0",
//     "audioTrackId": "",
//     "enableVoiceBoost": false,
//     "playbackAuthorization": {
//       "authorizedFormats": [
//         {
//           "trackType": 1,
//           "isHdr": false
//         },
//         {
//           "trackType": 2,
//           "isHdr": false
//         },
//         {
//           "trackType": 2,
//           "isHdr": true
//         }
//       ],
//       "sabrLicenseConstraint": ""
//     }
//   },

    NSLog(@"screenBounds.size.width -> %i", state.clientViewportWidth);


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

    
    return context;
}

-(NSData*)buildRequestBody {
    VideoPlaybackAbrRequest *request = [[VideoPlaybackAbrRequest alloc] init];

    request.streamerContext = [self createStreamerContext];
    request.videoPlaybackUstreamerConfig = self.ustreamConfig;

    NSMutableArray *videoFormatsIdsWeHave = [[NSMutableArray alloc] init];
    NSMutableArray *audioFormatsIdsWeHave = [[NSMutableArray alloc] init];
    for (TRAdaptiveFormat *format in self.formats) {
        FormatId *formatId = [[FormatId alloc] init];
        formatId.itag = format.itag;

        NSLog(@"last modified -> %@", format.lastModified);
        long long convertedValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:format.lastModified];
        [scanner scanLongLong:&convertedValue];
        formatId.lastModified = (unsigned long long)convertedValue;
        formatId.xtags = @"";
        if (format.xtags) {
            formatId.xtags = format.xtags;
        }

        if ([format.mimeType hasPrefix:@"audio"]) {
            [audioFormatsIdsWeHave addObject:formatId];
        } else {
            [videoFormatsIdsWeHave addObject:formatId];
        }
    }

    request.preferredVideoFormatIdsArray = videoFormatsIdsWeHave;
    request.preferredAudioFormatIdsArray = audioFormatsIdsWeHave;
    request.preferredSubtitleFormatIdsArray = [[NSMutableArray alloc] init];

    TRAdaptiveFormat *chosenVideoFormat = [self pickVideoFormat:self.videoFormatsWeHave];
    TRAdaptiveFormat *chosenAudioFormat = [self pickAudioFormat:self.audioFormatsWeHave];
    NSLog(@"video format -> %@", chosenVideoFormat);
    NSLog(@"audio format -> %@", chosenAudioFormat);

    request.clientAbrState = [self createClientABRStateWithVideo:chosenVideoFormat andAudio:chosenAudioFormat];
    request.field1000Array = [[NSMutableArray alloc] init];
    request.bufferedRangesArray = [[NSMutableArray alloc] init];

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
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        callback(response, error);
    }];
}

@end
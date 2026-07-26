#import "TRSabrStream.h"
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
    self.ustreamConfig = [NSData dataWithBase64EncodedString:ustreamConfig];
    self.formats = formats;
    self.videoId = videoId;

    NSLog(@"a");

    if ([[TRPOTokenSolver sharedInstance] isReadyToMintTokens]) {
        NSString *poTokenString = [[TRPOTokenSolver sharedInstance] mintPOTokenWithData:videoId];
        if (poTokenString) {
            self.poToken = [NSData dataWithBase64EncodedString:poTokenString];
        } else {
            self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:videoId clientState:1]];
        }
    } else {
        self.coldstart = [NSData dataWithBase64EncodedString:[TRPOTokenSolver generateColdStartTokenWithContent:videoId clientState:1]];
    }

    NSData *testReq = [self buildRequestBody];
    NSLog(@"buildRequestBody -> %@", testReq);
    [self makeStreamingRequestWithBody:testReq andCallback:^(NSData *response, NSError *error) {
        NSLog(@"response -> %@", response); 
    }];
    return self;
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

-(ClientAbrState*)createClientABRState {
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

    clientInfo.acceptLanguage = [[NSLocale preferredLanguages] firstObject];
    clientInfo.acceptRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];

    context.clientInfo = clientInfo;

    if (self.poToken) {
        context.poToken = self.poToken;
    } else {
        if ([[TRPOTokenSolver sharedInstance] isReadyToMintTokens]) {
            NSString *poTokenString = [[TRPOTokenSolver sharedInstance] mintPOTokenWithData:self.videoId];
            if (poTokenString) {
                self.poToken = [NSData dataWithBase64EncodedString:poTokenString];
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

    NSMutableArray *videoFormatsWeHave = [[NSMutableArray alloc] init];
    NSMutableArray *audioFormatsWeHave = [[NSMutableArray alloc] init];
    for (TRAdaptiveFormat *format in self.formats) {
        FormatId *formatId = [[FormatId alloc] init];
        formatId.itag = format.itag;

        NSLog(@"last modified -> %@", format.lastModified);
        long long convertedValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:format.lastModified];
        [scanner scanLongLong:&convertedValue];
        formatId.lastModified = (unsigned long long)convertedValue;
        formatId.xtags = @"";

        if ([format.mimeType hasPrefix:@"audio"]) {
            [audioFormatsWeHave addObject:formatId];
        } else {
            [videoFormatsWeHave addObject:formatId];
        }
    }

    request.preferredVideoFormatIdsArray = videoFormatsWeHave;
    request.preferredAudioFormatIdsArray = audioFormatsWeHave;

    request.clientAbrState = [self createClientABRState];

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
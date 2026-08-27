#include "TRSabrHTTPServer.h"
#include "common/SABR/TRAdaptiveFormat.h"
#import "googleapp/appheaders.h"
#include "video_streaming/PlaybackCookie.pbobjc.h"
#include "video_streaming/MediaHeader.pbobjc.h"
#include "TRSabrMedia.h"
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TRSabrBufferingType) {
    TRSabrBufferingNormal = 0,
    TRSabrBufferingFastTrack,
};

@interface TRSabrStream : NSObject
@property (nonatomic, strong) NSString *decipheredStreamURL; // this URL is deciphered
@property (nonatomic, strong) NSData *ustreamConfig;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSData *coldstart;
@property (nonatomic, strong) NSData *poToken;
@property (nonatomic, strong) NSDictionary<NSNumber*, TRAdaptiveFormat*> *formats;

// used for normal filling of the buffer, where playback isn't at ris
@property (nonatomic, assign) BOOL currentlyRequestingInNormal;
// used in case a seek occurs, or something is actively inhibiting playback
@property (nonatomic, assign) BOOL currentlyRequestingInFastTrack;

@property (nonatomic, strong) NSArray<TRAdaptiveFormat*> *videoFormatsWeHave;
@property (nonatomic, strong) NSArray<TRAdaptiveFormat*> *audioFormatsWeHave;

@property (nonatomic, strong) PlaybackCookie *playbackCookie;

@property (nonatomic, strong) TRSabrMedia *videoStream;
@property (nonatomic, strong) TRSabrMedia *audioStream;

// HTTP server used for serving HLS content
@property (nonatomic, strong) TRSabrHTTPServer *httpServer;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, strong) NSThread *httpServerThread;

// SABR data
@property (nonatomic, assign) int streamProtectionStatus;
@property (nonatomic, assign) int requestNumber;

// player callbacks
@property (nonatomic, copy) double (^currentPlayerTimeFunction)();
@property (nonatomic, copy) void (^reloadPlayerFunction)();

@property(nonatomic, retain) NSOperationQueue *networkQueue;

@property (nonatomic, assign) BOOL isStreamBad;
@property (nonatomic, retain) GTMOAuth2Authentication *authentication;


-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId;
-(NSString*)createHLSRootManifest;
-(void)requestAdditionalData:(int)currentStreamTimeMS state:(TRSabrBufferingType)bufferingState;
-(void)handleBufferingWithCurrentSegment:(uint16_t)segmentIdx mediaType:(TRSabrMediaType)mediaType;
-(void)declareStreamBad;
-(void)start;

// YTStream compatibility
-(NSURL*)URL;
-(int)format;
-(BOOL)encrypted;
-(BOOL)isWidevine;

@end
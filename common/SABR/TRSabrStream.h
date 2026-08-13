#include "TRSabrHTTPServer.h"
#include "common/SABR/TRAdaptiveFormat.h"
#include "video_streaming/PlaybackCookie.pbobjc.h"
#include "video_streaming/MediaHeader.pbobjc.h"
#include "TRSabrMedia.h"
#import <Foundation/Foundation.h>

@interface TRSabrStream : NSObject
@property (nonatomic, strong) NSString *decipheredStreamURL; // this URL is deciphered
@property (nonatomic, strong) NSData *ustreamConfig;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSData *coldstart;
@property (nonatomic, strong) NSData *poToken;
@property (nonatomic, strong) NSDictionary<NSNumber*, TRAdaptiveFormat*> *formats;

@property (nonatomic, assign) BOOL currentlyRequesting;


@property (nonatomic, strong) NSArray *videoFormatsWeHave;
@property (nonatomic, strong) NSArray *audioFormatsWeHave;

@property (nonatomic, strong) PlaybackCookie *playbackCookie;

@property (nonatomic, strong) TRSabrMedia *videoStream;
@property (nonatomic, strong) TRSabrMedia *audioStream;

// HTTP server used for serving HLS content
@property (nonatomic, strong) TRSabrHTTPServer *httpServer;

// SABR data
@property (nonatomic, assign) int streamProtectionStatus;
@property (nonatomic, assign) int requestNumber;

// player callbacks
@property (nonatomic, strong) double (^currentPlayerTimeFunction)();

@property(nonatomic, retain) NSOperationQueue *networkQueue;


-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId;
-(NSString*)createHLSRootManifest;
-(void)requestAdditionalData:(int)currentStreamTimeMS;
@end
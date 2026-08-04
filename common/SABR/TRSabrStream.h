#include "TRSabrHTTPServer.h"
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
@property (nonatomic, strong) NSArray *formats;

@property (nonatomic, strong) NSArray *videoFormatsWeHave;
@property (nonatomic, strong) NSArray *audioFormatsWeHave;

@property (nonatomic, strong) PlaybackCookie *playbackCookie;

@property (nonatomic, strong) TRSabrMedia *videoStream;
@property (nonatomic, strong) TRSabrMedia *audioStream;

// HTTP server used for serving HLS content
@property (nonatomic, strong) TRSabrHTTPServer *httpServer;

@property (nonatomic, assign) int streamProtectionStatus;

@property (nonatomic, assign) int requestNumber;

-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId;
-(NSString*)createHLSRootManifest;
@end
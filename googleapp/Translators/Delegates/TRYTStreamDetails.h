#include <Foundation/Foundation.h>
#import "../appheaders.h"

@interface TRYTStreamDetails : NSObject 
@property (nonatomic, assign) int type; // 1 = muxed, 2 = video, 3 = audio
@property (nonatomic, assign) int itag;
@property (nonatomic, strong) NSString *mimetype;
@property (nonatomic, strong) NSString *profile; // baseline, main, high.
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) NSString *quality;
@property (nonatomic, strong) NSString *qualityLabel;
@property (nonatomic, strong) NSString *audioQuality;
@property (nonatomic, assign) int averageBitrate;
@property (nonatomic, assign) int bitrate;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, assign) BOOL encrypted;

+(TRYTStreamDetails*)initWithType:(int)type
                    itag:(int)itag
                    mimeType:(NSString*)mimeType
                    profile:(NSString*)profile //baseline, main, high, vp9
                    height:(int)height
                    width:(int)width
                    fps:(int)fps
                    quality:(NSString*)quality
                    qualityLabel:(NSString*)qualityLabel
                    audioQuality:(NSString*)audioQuality
                    averageBitrate:(int)averageBitrate
                    bitrate:(int)bitrate
                    url:(NSURL*)url;

@end
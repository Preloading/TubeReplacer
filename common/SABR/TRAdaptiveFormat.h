#import <Foundation/Foundation.h>

@interface TRAdaptiveFormat : NSObject

@property (nonatomic, assign) uint itag;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *decipheredUrl;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, assign) uint bitrate;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

@property (nonatomic, strong) NSString *lastModified;
@property (nonatomic, assign) uint64_t contentLength;
@property (nonatomic, strong) NSString *quality;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) NSString *qualityLabel;
@property (nonatomic, strong) NSString *projectionType;

@property (nonatomic, assign) uint averageBitrate;
@property (nonatomic, assign) uint64_t approxDurationMs;

// audio
@property (nonatomic, assign) double loudnessDb;
@property (nonatomic, assign) double trackAbsoluteLoudnessLkfs;
@property (nonatomic, assign) uint audioSampleRate;
@property (nonatomic, strong) NSString *audioQuality;

@property (nonatomic, strong) NSString *qualityOrdinal;

@end
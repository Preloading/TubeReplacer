#import "TRYTStreamDetails.h"

@implementation TRYTStreamDetails
+(TRYTStreamDetails*)initWithType:(int)type
                    itag:(int)itag
                    mimeType:(NSString*)mimeType
                    profile:(NSString*)profile
                    height:(int)height
                    width:(int)width
                    fps:(int)fps
                    quality:(NSString*)quality
                    qualityLabel:(NSString*)qualityLabel
                    audioQuality:(NSString*)audioQuality
                    averageBitrate:(int)averageBitrate
                    bitrate:(int)bitrate
                    url:(NSURL*)url
{
    TRYTStreamDetails *details = [[TRYTStreamDetails alloc] init];
    details->_type = type;
    details->_itag = itag;
    details->_mimetype = [mimeType retain];
    details->_profile = [profile retain];
    details->_height = height;
    details->_width = width;
    details->_fps = fps;
    details->_quality = [quality retain];
    details->_qualityLabel = [qualityLabel retain];
    details->_audioQuality = [audioQuality retain];
    details->_averageBitrate = averageBitrate;
    details->_bitrate = bitrate;
    details->_URL = [url retain];
    details->_encrypted = NO;
    return details;
}

- (void)dealloc {
    [_mimetype release];
    [_profile release];
    [_quality release];
    [_qualityLabel release];
    [_audioQuality release];
    [_URL release];
    [super dealloc];
}

@end

@implementation TRYTStreams
+(TRYTStreams*)initWithVideoStream:(TRYTStreamDetails*)videoStream
                audioStream:(TRYTStreamDetails*)audioStream 
{
    TRYTStreams *streams = [[TRYTStreams alloc] init];
    streams->_videoStream = videoStream;
    streams->_audioStream = audioStream;
    streams->_encrypted = NO; // encryption is likely to just be never supported. anyways it would need a lot more work :P
    return streams;
}

- (void)dealloc {
    [_videoStream release];
    [_audioStream release];
    [super dealloc];
}

@end
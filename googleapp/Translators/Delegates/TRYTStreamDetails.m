#import "TRYTStreamDetails.h"

@implementation TRYTStreamDetails
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
                    url:(NSURL*)url
{
    TRYTStreamDetails *details = [TRYTStreamDetails alloc];
    details->_type = type;
    details->_itag = itag;
    details->_mimetype = mimeType;
    details->_profile  = profile;
    details->_height = height;
    details->_width = width;
    details->_fps = fps;
    details->_quality = quality;
    details->_qualityLabel = qualityLabel;
    details->_audioQuality = audioQuality;
    details->_averageBitrate = averageBitrate;
    details->_bitrate = bitrate;
    details->_url = url;
    return details;
}
@end
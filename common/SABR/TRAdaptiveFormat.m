#import "TRAdaptiveFormat.h"

@implementation TRAdaptiveFormat

-(NSString*)description {
    return [NSString stringWithFormat:@"(\n itag -> %i\n url -> %@\n mimeType -> %@\n bitrate -> %i\n average bitrate -> %i\n dimentions -> w: %i h: %i\n last modified: %@\n content length: %lld\n quality -> %@\n fps -> %i\n)",
        self.itag, self.url, self.mimeType, self.bitrate, self.averageBitrate, self.width, self.height, self.lastModified, self.contentLength, self.quality, self.fps
    ];
}

@end
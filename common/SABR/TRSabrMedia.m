#include "TRSabrMedia.h"
#include <CoreFoundation/CFByteOrder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <objc/NSObjCRuntime.h>
#include <stdint.h>


@implementation TRSabrMedia

-(void)parseMP4Header:(NSData*)header {
    NSLog(@"header to parse -> %@", header);

    // find sidx
    int boxOffset = 0;

    while (boxOffset < [header length]) {
        uint32_t boxLength;
        [header getBytes:&boxLength range:NSMakeRange(boxOffset, 4)];
        boxLength = CFSwapInt32BigToHost(boxLength);
        boxOffset += 4;

        NSLog(@"box length -> %i", boxLength);

        NSString *boxType = [[NSString alloc] initWithData:[header subdataWithRange:NSMakeRange(boxOffset, 4)] encoding:NSUTF8StringEncoding];
        boxOffset += 4;

        NSLog(@"found box type of %@", boxType);
        if ([boxType isEqualToString:@"sidx"]) {
            NSLog(@"found sidx!!");
            int offset = boxOffset;

            uint8_t version;
            [header getBytes:&version range:NSMakeRange(offset, 1)];
            offset+=1;
            if (version == 1) {
                NSLog(@"they actually used version 1??? wow, guess i get to go implement that now. if this made it into prod, shoot me a DM or email :)");
                return;
            }

            offset += 3; // there are flags here, but i'm pretty sure they are all just reserve.

            offset += 4; // would be the refrence id, but i don't actually care about that, I think its used if there are more than one medias? like an audio track? idk
            
            uint32_t timescale;
            [header getBytes:&timescale range:NSMakeRange(offset, 4)];
            timescale = CFSwapInt32BigToHost(timescale);
            offset+=4;
            self.timescale = timescale;

            offset+=10; // random other junk i don't need

            uint16_t referenceCount;
            [header getBytes:&referenceCount range:NSMakeRange(offset, 2)];
            referenceCount = CFSwapInt16BigToHost(referenceCount);
            offset+=2;

            NSMutableArray *segmentIndexes = [[NSMutableArray alloc] initWithCapacity:referenceCount];

            for (uint16_t i = 0; i < referenceCount; i++) {
                offset += 4; // contains type & size of segment, irrelevent to us using sabr

                uint32_t segment_duration;
                [header getBytes:&segment_duration range:NSMakeRange(offset, 4)];
                segment_duration = CFSwapInt32BigToHost(segment_duration);
                offset+=8;
                segmentIndexes[i] = @(segment_duration);
                // NSLog(@"segment duration (in ticks) -> %i", segment_duration);
                // NSLog(@"segment duration (in seconds) -> %f", (double)segment_duration/(double)timescale);
            }
            self.segmentIndexes = [segmentIndexes copy];
            [segmentIndexes release];
            
        }

        boxOffset += boxLength-8;
    }
}

-(NSString*)generateHLSManifest {
    NSMutableString *hlsManifest = [[NSMutableString alloc] init];
    [hlsManifest appendString:@"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-PLAYLIST-TYPE:VOD\n#EXT-X-MEDIA-SEQUENCE:0\n"];

    int maxDurationTicks = [[self.segmentIndexes valueForKeyPath:@"@max.intValue"] intValue];
    NSLog(@"max duration -> %i", maxDurationTicks);
    [hlsManifest appendFormat:@"#EXT-X-TARGETDURATION:%f\n", (double)maxDurationTicks/(double)self.timescale];

    int segmentIndex = 0;
    for (NSNumber *durationTicks in self.segmentIndexes) {
        [hlsManifest appendFormat:@"#EXTINF:%f,\ns%i-%05i.ts\n", [durationTicks doubleValue]/(double)self.timescale, self.itag, segmentIndex];
        segmentIndex++;
    }

    [hlsManifest appendString:@"#EXT-X-ENDLIST"];

    // finish
    NSString *final = [hlsManifest copy];
    [hlsManifest release];
    return final;
}

@end
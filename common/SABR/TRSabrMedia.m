#include "TRSabrMedia.h"
#include <CoreFoundation/CFByteOrder.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <objc/NSObjCRuntime.h>
#include <stdint.h>
#include "TRMP4Box.h"

@implementation TRSabrMedia

-(instancetype)init {
    self = [super init];
    _segmentData = [[NSMutableDictionary alloc] init];
    return self;
}

-(void)handleParsedHeaderBox:(TRMP4Box*)box {
    NSLog(@"found box type of %@", box.type);
    if ([box.type isEqualToString:@"moov"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"trak"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"mdia"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"trak"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"minf"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"stbl"]) { [self parseMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"stsd"]) {
        int offset = 4; // version & flags

        uint32_t entryCount;
        [box.data getBytes:&entryCount range:NSMakeRange(offset, 4)];
        entryCount = CFSwapInt32BigToHost(entryCount);
        offset+=4;

        NSLog(@"entry count -> %i", entryCount);

        for (int i = 0; i < entryCount; i++) {
            TRMP4Box *newBox = [[TRMP4Box alloc] parseMP4Box:box.data atOffset:&offset];
            [self handleParsedHeaderBox:newBox];
            offset += [newBox length];
        }
    } 
    else if ([box.type isEqualToString:@"avc1"]) { 
        int offset = 78;
        TRMP4Box *newBox = [[TRMP4Box alloc] parseMP4Box:box.data atOffset:&offset];
        [self handleParsedHeaderBox:newBox];
    } 
    else if ([box.type isEqualToString:@"avcC"]) { 
        int offset = 4;
        
        uint8_t lengthScaleMinusOne;
        [box.data getBytes:&lengthScaleMinusOne range:NSMakeRange(offset,1)];
        self.lengthScaleMinusOne = lengthScaleMinusOne & 0x03;
        NSLog(@"length scale minus one -> %i", self.lengthScaleMinusOne);
        offset += 2;

        uint16_t spsLen;
        [box.data getBytes:&spsLen range:NSMakeRange(offset,2)];
        spsLen = CFSwapInt16BigToHost(spsLen);
        offset+=2;

        self.sps = [box.data subdataWithRange:NSMakeRange(offset,spsLen)];
        offset += spsLen+1;

        uint16_t ppsLen;
        [box.data getBytes:&ppsLen range:NSMakeRange(offset,2)];
        ppsLen = CFSwapInt16BigToHost(ppsLen);
        offset+=2;

        self.pps = [box.data subdataWithRange:NSMakeRange(offset,ppsLen)];

        NSLog(@"sps -> %@\npps -> %@", self.sps, self.pps);
    } 
    else if ([box.type isEqualToString:@"sidx"]) {
        int offset = 0;

        uint8_t version;
        [box.data getBytes:&version range:NSMakeRange(offset, 1)];
        offset+=1;
        if (version == 1) {
            NSLog(@"they actually used version 1??? wow, guess i get to go implement that now. if this made it into prod, shoot me a DM or email :)");
            return;
        }

        offset += 3; // there are flags here, but i'm pretty sure they are all just reserve.

        offset += 4; // would be the refrence id, but i don't actually care about that, I think its used if there are more than one medias? like an audio track? idk
        
        uint32_t timescale;
        [box.data getBytes:&timescale range:NSMakeRange(offset, 4)];
        timescale = CFSwapInt32BigToHost(timescale);
        offset+=4;
        self.timescale = timescale;

        offset+=10; // random other junk i don't need

        uint16_t referenceCount;
        [box.data getBytes:&referenceCount range:NSMakeRange(offset, 2)];
        referenceCount = CFSwapInt16BigToHost(referenceCount);
        offset+=2;

        NSMutableArray *segmentIndexes = [[NSMutableArray alloc] initWithCapacity:referenceCount];

        for (uint16_t i = 0; i < referenceCount; i++) {
            offset += 4; // contains type & size of segment, irrelevent to us using sabr

            uint32_t segment_duration;
            [box.data getBytes:&segment_duration range:NSMakeRange(offset, 4)];
            segment_duration = CFSwapInt32BigToHost(segment_duration);
            offset+=8;
            segmentIndexes[i] = @(segment_duration);
            // NSLog(@"segment duration (in ticks) -> %i", segment_duration);
            // NSLog(@"segment duration (in seconds) -> %f", (double)segment_duration/(double)timescale);
        }
        self.segmentIndexes = [segmentIndexes copy];
        [segmentIndexes release];
        
    }
}

-(void)parseMP4Header:(NSData*)header {
    // NSLog(@"header to parse -> %@", header);

    // find sidx
    int boxOffset = 0;

    while (boxOffset < [header length]) {
        TRMP4Box *box = [[TRMP4Box alloc] parseMP4Box:header atOffset:&boxOffset];
        
        
        [self handleParsedHeaderBox:box];

        boxOffset += [box length];
    }
}


// -(void)parseFMP4Fragment:(NSData*)fragment dataOut:(NSData**)dataOut  {
//     // NSLog(@"header to parse -> %@", header);

//     // find sidx
//     int boxOffset = 0;

//     while (boxOffset < [fragment length]) {
//         TRMP4Box *box = [[TRMP4Box alloc] parseMP4Box:fragment atOffset:&boxOffset];
        
        
//         [self handleParsedHeaderBox:box];

//         boxOffset += [box length];
//     }
// }
 
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

-(NSData*)convertFMP4ToMPEGTSWithIndex:(int)index {
    // NSData *source = self.segmentData[@(index)];

    // NSLog(@"keys -> %@", [self.segmentData allKeys]);
    

    return nil; /// temp
}

@end
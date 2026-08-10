#include "TRSabrMedia.h"
#include <CoreFoundation/CFByteOrder.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <math.h>
#include <objc/NSObjCRuntime.h>
#include <stdint.h>
#include <sys/types.h>
#include "TRMP4Box.h"
#include "TRMP4FragmentInfo.h"

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

-(void)handleFMP4FragmentBox:(TRMP4Box*)box out:(TRMP4FragmentInfo**)fragmentOut {
    NSLog(@"found box type of %@", box.type);
    if ([box.type isEqualToString:@"moof"]) { [self parseFMP4Fragment:box.data out:fragmentOut]; }
    else if ([box.type isEqualToString:@"traf"]) { [self parseFMP4Fragment:box.data out:fragmentOut]; }
    else if ([box.type isEqualToString:@"tfdt"]) { 
        int offset = 0;
        uint8_t version;
        [box.data getBytes:&version range:NSMakeRange(offset, 1)];
        offset += 4; // includes flags

        if (version == 1) {
            uint64_t baseDecodeTime;
            [box.data getBytes:&baseDecodeTime range:NSMakeRange(offset, 8)];
            baseDecodeTime = CFSwapInt64BigToHost(baseDecodeTime);
            (*fragmentOut).baseMediaDecodeTime = baseDecodeTime;
        } else {
            uint32_t baseDecodeTime;
            [box.data getBytes:&baseDecodeTime range:NSMakeRange(offset, 4)];
            baseDecodeTime = CFSwapInt32BigToHost(baseDecodeTime);
            (*fragmentOut).baseMediaDecodeTime = baseDecodeTime;
        }
        
    } else if ([box.type isEqualToString:@"tfhd"]) { 
        int offset = 0;

        uint32_t flags; // upper 8 bits are version
        [box.data getBytes:&flags range:NSMakeRange(offset, 4)];
        flags = CFSwapInt32BigToHost(flags);
        offset += 4;

        uint32_t trackId; // will also contain version
        [box.data getBytes:&trackId range:NSMakeRange(offset, 4)];
        trackId = CFSwapInt32BigToHost(trackId);
        offset += 4;
        (*fragmentOut).trackId = trackId;

        (*fragmentOut).hasDefaultSampleDuration = NO;
        (*fragmentOut).hasDefaultSampleSize = NO;
        (*fragmentOut).hasDefaultSampleFlags = NO;

        // base data offset
        if (flags & 0x000001) { 
            offset += 8;
        }
        // sample description index
        if (flags & 0x000002) {
            offset += 4;
        }
        // default sample duration
        if (flags & 0x000008) {
            (*fragmentOut).hasDefaultSampleDuration = YES;

            uint32_t defaultSampleDuration; // will also contain version
            [box.data getBytes:&defaultSampleDuration range:NSMakeRange(offset, 4)];
            defaultSampleDuration = CFSwapInt32BigToHost(defaultSampleDuration);
            offset += 4;
            (*fragmentOut).defaultSampleDuration = defaultSampleDuration;
        }
        // default sample size
        if (flags & 0x000010) {
            (*fragmentOut).hasDefaultSampleSize = YES;

            uint32_t defaultSampleSize; // will also contain version
            [box.data getBytes:&defaultSampleSize range:NSMakeRange(offset, 4)];
            defaultSampleSize = CFSwapInt32BigToHost(defaultSampleSize);
            offset += 4;
            (*fragmentOut).defaultSampleSize = defaultSampleSize;
        }
        // default sample flags
        if (flags & 0x000020) {
            (*fragmentOut).hasDefaultSampleFlags = YES;

            uint32_t defaultSampleFlags; // will also contain version
            [box.data getBytes:&defaultSampleFlags range:NSMakeRange(offset, 4)];
            defaultSampleFlags = CFSwapInt32BigToHost(defaultSampleFlags);
            offset += 4;
            (*fragmentOut).defaultSampleFlags = defaultSampleFlags;
        }
    } else if ([box.type isEqualToString:@"trun"]) { 
        int offset = 0;

        uint32_t flags; // upper 8 bits are version
        [box.data getBytes:&flags range:NSMakeRange(offset, 4)];
        flags = CFSwapInt32BigToHost(flags);
        offset += 4;

        uint32_t sampleCount;
        [box.data getBytes:&sampleCount range:NSMakeRange(offset, 4)];
        sampleCount = CFSwapInt32BigToHost(sampleCount);
        offset += 4;
        (*fragmentOut).sampleCount = sampleCount;

        // data offset
        if (flags & 0x000001) {
            offset += 4;
        }

        // first sample flags
        if (flags & 0x000004) {
            offset += 4;
        }

        NSMutableArray<NSNumber*> *sampleDurationArray = [[NSMutableArray alloc] init];
        NSMutableArray<NSNumber*> *sampleSizeArray = [[NSMutableArray alloc] init];
        NSMutableArray<NSNumber*> *sampleCompositionOffsetsArray = [[NSMutableArray alloc] init];
        NSMutableArray<NSNumber*> *sampleFlagsArray = [[NSMutableArray alloc] init];

        for (uint32_t i = 0; i < sampleCount; i++) {
            if (flags & 0x000100) {
                uint32_t sampleDuration;
                [box.data getBytes:&sampleDuration range:NSMakeRange(offset, 4)];
                sampleDuration = CFSwapInt32BigToHost(sampleDuration);
                [sampleDurationArray addObject:@(sampleDuration)];
                offset += 4;
            }

            if (flags & 0x000200) {
                uint32_t sampleSize;
                [box.data getBytes:&sampleSize range:NSMakeRange(offset, 4)];
                sampleSize = CFSwapInt32BigToHost(sampleSize);
                [sampleSizeArray addObject:@(sampleSize)];
                offset += 4;
            }

            if (flags & 0x000400) {
                uint32_t sampleFlags;
                [box.data getBytes:&sampleFlags range:NSMakeRange(offset, 4)];
                sampleFlags = CFSwapInt32BigToHost(sampleFlags);
                [sampleFlagsArray addObject:@(sampleFlags)];
                offset += 4;
            }

            if (flags & 0x000800) {
                if (flags & 0b00000001000000000000000000000000) { // version 1
                    int32_t sampleCompositionOffset;
                    [box.data getBytes:&sampleCompositionOffset range:NSMakeRange(offset, 4)];
                    sampleCompositionOffset = CFSwapInt32BigToHost(sampleCompositionOffset);
                    [sampleCompositionOffsetsArray addObject:@(sampleCompositionOffset)];
                    offset += 4;
                } else {
                    uint32_t sampleCompositionOffset;
                    [box.data getBytes:&sampleCompositionOffset range:NSMakeRange(offset, 4)];
                    sampleCompositionOffset = CFSwapInt32BigToHost(sampleCompositionOffset);
                    [sampleCompositionOffsetsArray addObject:@(sampleCompositionOffset)];
                    offset += 4;
                }
            }
        }

        (*fragmentOut).sampleDuration = [sampleDurationArray copy];
        (*fragmentOut).sampleSize = [sampleSizeArray copy];
        (*fragmentOut).sampleCompositionOffsets = [sampleCompositionOffsetsArray copy];
        (*fragmentOut).sampleFlags = [sampleFlagsArray copy];

        [sampleDurationArray release];
        [sampleSizeArray release];
        [sampleCompositionOffsetsArray release];
        [sampleFlagsArray release];
    }
    else if ([box.type isEqualToString:@"mdat"]) { 
        (*fragmentOut).data = box.data; 
    }
}

-(void)parseFMP4Fragment:(NSData*)fragment out:(TRMP4FragmentInfo**)fragmentOut  {

    // find sidx
    int boxOffset = 0;

    while (boxOffset < [fragment length]) {
        TRMP4Box *box = [[TRMP4Box alloc] parseMP4Box:fragment atOffset:&boxOffset];
        

        [self handleFMP4FragmentBox:box out:fragmentOut];

        boxOffset += [box length];
    }
}

-(NSArray<NSData*>*)extractSamplesFromFragment:(TRMP4FragmentInfo*)fragment {
    NSMutableArray<NSData*> *samples = [[NSMutableArray alloc] initWithCapacity:fragment.sampleCount];
    uint32_t offset = 0;
    
    for (uint32_t i = 0; i < fragment.sampleCount; i++) {
        // technically I don't think your suppost to do this, but that can't stop me from doing it anyways... unlessss it fails

        uint32_t sampleSize = 0;
        NSNumber *sampleSizeNSNumber = fragment.sampleSize[i];
        if (!sampleSizeNSNumber) {
            // revert to default, even though this wouldn't work if there are gaps in sample size for the default.
            if (fragment.hasDefaultSampleSize) {
                sampleSize = fragment.defaultSampleSize;
            } else {
                return nil; // bad
            }
        } else {
            sampleSize = [sampleSizeNSNumber unsignedIntValue];
        }

        NSData *sample = [fragment.data subdataWithRange:NSMakeRange(offset, sampleSize)];
        offset += sampleSize;
        samples[i] = sample;
    }

    NSArray *copy = [samples copy];
    [samples release];
    return copy;
}
 
+(NSData*)annexBStartCodeNAL:(NSData*)nal {
    static const uint8_t startCode[4] = {0x00, 0x00, 0x00, 0x01};

    NSMutableData *out = [NSMutableData dataWithBytes:startCode length:4];
    [out appendData:nal];
    return out;
}

-(NSArray<NSData*>*)convertSamplesToAnnexB:(NSArray<NSData*>*)samples fragmentInfo:(TRMP4FragmentInfo*)fragment {
    NSMutableArray<NSData*> *annexBOut = [NSMutableArray arrayWithCapacity:samples.count];
    for (uint32_t i = 0; i < fragment.sampleCount; i++) {
        NSMutableData *annexB = [[NSMutableData alloc] init];
        
        // get our flags
        uint32_t flags = 0;
        if (fragment.sampleFlags.count == 0) {
            flags = fragment.defaultSampleFlags;
        } else {
            flags = [fragment.sampleFlags[i] unsignedIntValue];
        }

        if ((flags & 0x00010000) == 0) {
            // keyframe
            [annexB appendData:[TRSabrMedia annexBStartCodeNAL:self.sps]];
            [annexB appendData:[TRSabrMedia annexBStartCodeNAL:self.pps]];
        }

        uint32_t offset = 0;
        while (offset < samples[i].length) {
            int naluLengthSize = self.lengthScaleMinusOne+1; // a length to your length!
            uint64_t naluLength = 0;
            
            for (int j = 0; j < naluLengthSize; j++) {
                uint8_t newBytes;
                [samples[i] getBytes:&newBytes range:NSMakeRange(offset, 1)];
                naluLength = (naluLength << 8) | newBytes;
                offset++;
            }

            [annexB appendData:[TRSabrMedia annexBStartCodeNAL:[samples[i] subdataWithRange:NSMakeRange(offset, naluLength)]]];
            offset += naluLength;
        }
        [annexBOut addObject:annexB];
    }
    return annexBOut;
}

// ok this function is AI. sowwy. this just breaks my dam head.
// Encodes a 33-bit timestamp (PTS or DTS) into 5 bytes per the spec.
// prefix: 0x2 for PTS-only, 0x3 for PTS-with-DTS(PTS), 0x1 for DTS
static void EncodeTimestamp(NSMutableData *data, uint8_t prefix, uint64_t ts) {
    uint8_t bytes[5];
    bytes[0] = (prefix << 4) | (((ts >> 30) & 0x07) << 1) | 0x01;
    bytes[1] = (ts >> 22) & 0xFF;
    bytes[2] = (((ts >> 15) & 0x7F) << 1) | 0x01;
    bytes[3] = (ts >> 7) & 0xFF;
    bytes[4] = ((ts & 0x7F) << 1) | 0x01;
    [data appendBytes:bytes length:5];
}


-(NSData*)createPESPacketFromData:(NSData*)data pts:(uint64_t)pts dts:(uint64_t)dts {
    NSMutableData *pesPacket = [[NSMutableData alloc] init];
    
    uint8_t stream_id = 0;
    if (self.mediaType == TRSabrMediaTypeVideo) {
        stream_id = 0xE0;
    } else {
        stream_id = 0xC0;
    }
    uint8_t startCode[4] = {0x00, 0x00, 0x01, stream_id};
    [pesPacket appendBytes:startCode length:4];

    // optional header
    NSMutableData *optional = [[NSMutableData alloc] init];

    uint8_t flags1 = 0x80;
    uint8_t flags2 = 0x00;
    NSMutableData *tsData = [[NSMutableData alloc] init];
    if (pts == dts) {
        flags2 |= 0xC0;
        EncodeTimestamp(tsData, 0x3, pts);
        EncodeTimestamp(tsData, 0x3, dts);
    } else {
        flags2 |= 0x80;
        EncodeTimestamp(tsData, 0x2, pts);
    }

    uint8_t tsDataLen = tsData.length;
    [optional appendBytes:&flags1 length:1];
    [optional appendBytes:&flags2 length:1];
    [optional appendBytes:&tsDataLen length:1];
    [optional appendData:tsData];

    // packet length
    uint32_t packetLengthFull = [optional length] + [data length];
    uint16_t packetLength = 0;

    if (packetLengthFull <= 0xFFFF) {
        packetLength = packetLengthFull;
    }

    packetLength = CFSwapInt16HostToBig(packetLength);
    uint8_t lengthBytes[2] = {(uint8_t)(packetLength << 8), (uint8_t)packetLength};
    [pesPacket appendBytes:lengthBytes length:2];

    // merge em all together and send it!
    [pesPacket appendData:optional];
    [pesPacket appendData:data];
    return pesPacket;

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

-(NSData*)convertFMP4ToMPEGTSWithIndex:(int)index {
    NSData *source = self.segmentData[@(index)];

    if (!source) {
        NSLog(@"[TubeReplacer] segment is not found");
        return nil;
    }

    TRMP4FragmentInfo *fragmentInfo = [[TRMP4FragmentInfo alloc] init];
    [self parseFMP4Fragment:source out:&fragmentInfo];

    if (!fragmentInfo.data || fragmentInfo.sampleSize.count == 0) {
        NSLog(@"[TubeReplacer] required format data is missing");
        return nil;
    }

    NSArray<NSData*> *samples = [self extractSamplesFromFragment:fragmentInfo];
    NSArray<NSData*> *annexB = [self convertSamplesToAnnexB:samples fragmentInfo:fragmentInfo];
    [samples release];
    
    double ticksTo90k = (90000.0 / (double)self.timescale);
    NSMutableData *pesPackets = [[NSMutableData alloc] init];
    uint64_t baseMediaDecodeTimeRunning = fragmentInfo.baseMediaDecodeTime;
    for (uint32_t i = 0; i < fragmentInfo.sampleCount; i++) {
        uint64_t dts = (uint64_t)llround(baseMediaDecodeTimeRunning * ticksTo90k);
        uint64_t pts = (uint64_t)llround(baseMediaDecodeTimeRunning + [fragmentInfo.sampleCompositionOffsets[i] doubleValue] * ticksTo90k);

        [pesPackets appendData:[self createPESPacketFromData:annexB[i] pts:pts dts:dts]];

        if (fragmentInfo.sampleDuration.count == 0)
            baseMediaDecodeTimeRunning += fragmentInfo.defaultSampleDuration;
        else
            baseMediaDecodeTimeRunning += [fragmentInfo.sampleDuration[i] unsignedLongLongValue];
    }

    NSLog(@"pes packets -> %@", pesPackets);
    // bunch of todo stuff
    


    return nil; /// temp
}

@end
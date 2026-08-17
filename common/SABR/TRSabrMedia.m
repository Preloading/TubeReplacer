#include "TRSabrMedia.h"
#include <CoreFoundation/CFByteOrder.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <math.h>
#include <objc/NSObjCRuntime.h>
#include <stdint.h>
#include <sys/_types/_off_t.h>
#include <sys/types.h>
#include "TRMP4Box.h"
#include "TRMP4FragmentInfo.h"

@implementation TRSabrMedia

-(instancetype)init {
    self = [super init];
    _segmentData = [[NSMutableDictionary alloc] init];
    self.isReadyForPlayback = false;
    self.manifestReady = [[[NSCondition alloc] init] autorelease];
    self.segmentCondition = [[[NSCondition alloc] init] autorelease];
    return self;
}

-(void)handleParsedHeaderBox:(TRMP4Box*)box {
    // NSLog(@"found box type of %@", box.type);
    if ([box.type isEqualToString:@"moov"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"trak"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"mdia"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"trak"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"minf"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"stbl"]) { [self parseSubMP4Header:box.data]; } 
    else if ([box.type isEqualToString:@"stsd"]) {
        int offset = 4; // version & flags

        uint32_t entryCount;
        [box.data getBytes:&entryCount range:NSMakeRange(offset, 4)];
        entryCount = CFSwapInt32BigToHost(entryCount);
        offset+=4;

        for (int i = 0; i < entryCount; i++) {
            TRMP4Box *newBox = [[TRMP4Box alloc] parseMP4Box:box.data atOffset:&offset];
            [self handleParsedHeaderBox:newBox];
            offset += [newBox length];
            [newBox release];
        }
    } 
    else if ([box.type isEqualToString:@"avc1"]) { 
        int offset = 78;
        TRMP4Box *newBox = [[TRMP4Box alloc] parseMP4Box:box.data atOffset:&offset];
        [self handleParsedHeaderBox:newBox];
        [newBox release];
    } 
    else if ([box.type isEqualToString:@"avcC"]) { 
        int offset = 4;
        
        uint8_t lengthScaleMinusOne;
        [box.data getBytes:&lengthScaleMinusOne range:NSMakeRange(offset,1)];
        self.lengthScaleMinusOne = lengthScaleMinusOne & 0x03;
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
    } 
    else if ([box.type isEqualToString:@"mp4a"]) { 
        int offset = 41;

        // uint32_t esdsLength = 0;
        while (true) {
            uint8_t lengthSegment;
            [box.data getBytes:&lengthSegment range:NSMakeRange(offset,1)];
            offset+=1;
            // esdsLength = (lengthSegment << 7) | (lengthSegment & 0x7F);
            if ((lengthSegment & 0x80) == 0)
                break;
        }

        offset+=3; // i ignore stuff that ig could be important, but it's not like this has to work with every video format lol

        // tag 0x04
        offset+=1;

            // uint32_t esdsLength = 0;
        while (true) {
            uint8_t lengthSegment;
            [box.data getBytes:&lengthSegment range:NSMakeRange(offset,1)];
            offset+=1;
            // esdsLength = (lengthSegment << 7) | (lengthSegment & 0x7F);
            if ((lengthSegment & 0x80) == 0)
                break;
        }

        offset+=13;

        // tag 0x05
        offset+=1;
        while (true) {
            uint8_t lengthSegment;
            [box.data getBytes:&lengthSegment range:NSMakeRange(offset,1)];
            offset+=1;
            // esdsLength = (lengthSegment << 7) | (lengthSegment & 0x7F);
            if ((lengthSegment & 0x80) == 0)
                break;
        }

        // https://wiki.multimedia.cx/index.php/MPEG-4_Audio
        uint8_t ascByte1;
        [box.data getBytes:&ascByte1 range:NSMakeRange(offset,1)];
        offset+=1;
        uint8_t ascByte2;
        [box.data getBytes:&ascByte2 range:NSMakeRange(offset,1)];
        offset+=1;

        uint8_t objectType = ascByte1>>3; // 5 bits

        // i mean this case is really annyoing
        // if (objectType == 31) {
        //     objectType = ((ascByte1 & 0x11111000) << 3) + (ascByte2 >> 5) + 32;  // 3 bits + 3 bits
        // }
        uint8_t frequencyIndex = ((ascByte1 & 0x11111000) << 1) + (ascByte2 >> 7);

        // so is this one!
        // if (frequencyIndex == 15) {

        // }

        self.channelConfig = (ascByte2 & 0b01111000) >> 3;
        self.audioObjectType = objectType;
        self.samplingFrequencyIndex = frequencyIndex;
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
        NSMutableArray *segmentIndexesCombined = [[NSMutableArray alloc] initWithCapacity:referenceCount];

        uint32_t lastSegmentDuration = 0;

        for (uint16_t i = 0; i < referenceCount; i++) {
            offset += 4; // contains type & size of segment, irrelevent to us using sabr

            uint32_t segment_duration;
            [box.data getBytes:&segment_duration range:NSMakeRange(offset, 4)];
            segment_duration = CFSwapInt32BigToHost(segment_duration);
            offset+=8;
            segmentIndexes[i] = @(segment_duration);
            segmentIndexesCombined[i] = @(lastSegmentDuration);
            lastSegmentDuration += segment_duration;
            // NSLog(@"segment duration (in ticks) -> %i", segment_duration);
            // NSLog(@"segment duration (in seconds) -> %f", (double)segment_duration/(double)timescale);
        }
        self.segmentIndexes = segmentIndexes;
        self.segmentIndexesCombined = segmentIndexesCombined;
        [segmentIndexes release];
        [segmentIndexesCombined release];
    }
}

-(void)parseSubMP4Header:(NSData*)header {
    // find sidx
    int boxOffset = 0;

    while (boxOffset < [header length]) {
        TRMP4Box *box = [[TRMP4Box alloc] parseMP4Box:header atOffset:&boxOffset];
        
        [self handleParsedHeaderBox:box];

        boxOffset += [box length];
        [box release];
    }
}

-(void)parseMP4Header:(NSData*)header {
    [self parseSubMP4Header:header];

    [self.manifestReady lock];
    self.isReadyForPlayback = YES;
    [self.manifestReady signal];
    [self.manifestReady unlock];
}

-(void)addNewFMP4FragmentWithID:(int)fragmentId data:(NSData*)data {
    [self.segmentCondition lock];
    self.segmentData[@(fragmentId)] = data;
    [self.segmentCondition broadcast];
    [self.segmentCondition unlock];
}

-(void)handleFMP4FragmentBox:(TRMP4Box*)box out:(TRMP4FragmentInfo**)fragmentOut {
    // NSLog(@"found box type of %@", box.type);
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
        (*fragmentOut).data = [[box.data copy] autorelease];
    }
}

-(void)parseFMP4Fragment:(NSData*)fragment out:(TRMP4FragmentInfo**)fragmentOut  {

    // find sidx
    int boxOffset = 0;

    while (boxOffset < [fragment length]) {
        TRMP4Box *box = [[TRMP4Box alloc] parseMP4Box:fragment atOffset:&boxOffset];
        

        [self handleFMP4FragmentBox:box out:fragmentOut];

        boxOffset += [box length];
        [box release];
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

    static const uint8_t audNALBytes[1] = { 0xF0 };
    NSData *audNAL = [NSData dataWithBytes:audNALBytes length:1];

    for (uint32_t i = 0; i < fragment.sampleCount; i++) {
        NSMutableData *annexB = [[NSMutableData alloc] init];
        
        NSMutableData *audFull = [NSMutableData dataWithBytes:"\x09" length:1];
        [audFull appendData:audNAL];
        [annexB appendData:[TRSabrMedia annexBStartCodeNAL:audFull]];
        
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
        [annexB release];
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
    if (pts != dts) {
        flags2 |= 0xC0;
        EncodeTimestamp(tsData, 0x3, pts);
        EncodeTimestamp(tsData, 0x1, dts);
    } else {
        flags2 |= 0x80;
        EncodeTimestamp(tsData, 0x2, pts);
    }

    uint8_t tsDataLen = tsData.length;
    [optional appendBytes:&flags1 length:1];
    [optional appendBytes:&flags2 length:1];
    [optional appendBytes:&tsDataLen length:1];
    [optional appendData:tsData];
    [tsData release];

    // packet length
    uint32_t packetLengthFull = [optional length] + [data length];
    uint16_t packetLength = 0;

    if (packetLengthFull <= 0xFFFF) {
        packetLength = packetLengthFull;
    }

    uint8_t lengthBytes[2] = {(uint8_t)(packetLength >> 8), (uint8_t)packetLength};
    [pesPacket appendBytes:lengthBytes length:2];

    // merge em all together and send it!
    [pesPacket appendData:optional];
    [pesPacket appendData:data];

    [optional release];
    return pesPacket;
}

// Source - https://stackoverflow.com/a/54351365
// Posted by rcgldr, modified by community. See post 'Timeline' for change history
// Retrieved 2026-08-10, License - CC BY-SA 4.0

unsigned int crc32b(unsigned char *message, size_t l)
{
   size_t i, j;
   unsigned int crc, msb;

   crc = 0xFFFFFFFF;
   for(i = 0; i < l; i++) {
      // xor next byte to upper bits of crc
      crc ^= (((unsigned int)message[i])<<24);
      for (j = 0; j < 8; j++) {    // Do eight times.
            msb = crc>>31;
            crc <<= 1;
            crc ^= (0 - msb) & 0x04C11DB7;
      }
   }
   return crc;         // don't complement crc on output
}

-(NSData*)buildPATSection {
    NSMutableData *patSection = [NSMutableData data];

    uint8_t patSectionStart[12] = {0x00, // table id
        0xB0, 0x0D, // length, since this is basically hardcoded, as news flash tells me I am not putting 250 channels in one TS stream lmao
        0x00, 0x01, // transport_stream_id
        0b11000001, // first two are reserverd, 5 bits for version, current next indecator is last
        0x00, // section number
        0x00, // last section number
        // program loop
        0x00, 0x01, // program name
        0xF0, 0x00 // PMT ID + reserved stuff. PMT ID is 0x23 maybe
    };

    unsigned int crcResult = crc32b(patSectionStart, sizeof(patSectionStart));
    uint8_t crcBytes[4] = {(uint8_t)(crcResult >> 24), (uint8_t)(crcResult >> 16), (uint8_t)(crcResult >> 8), (uint8_t)crcResult};

    uint8_t pointerField = 0x00;
    [patSection appendBytes:&pointerField length:1];
    [patSection appendBytes:patSectionStart length:12];
    [patSection appendBytes:crcBytes length:4];
    return patSection;
}

-(NSData*)buildPMTSection:(uint16_t)pid {
    NSMutableData *pmtSection = [NSMutableData data];

    uint8_t streamType = 0;
    if (self.mediaType == TRSabrMediaTypeVideo) {
        streamType = 0x1B;
    } else {
        streamType = 0x0F;
    }

    uint8_t pmtSectionStart[17] = {
        0x02,                          // table_id
        0xB0, 0x12,                    // section_length: flags + length
        0x00, 0x01,                    // program_number
        0b11000001,                    // reserved(2) + version(5) + current_next(1)
        0x00,                          // section_number
        0x00,                          // last_section_number
        (uint8_t)(0xE0 | (pid >> 8)),  // reserved(3) + PCR_PID high bits
        (uint8_t)(pid & 0xFF),         // PCR_PID low byte
        0xF0, 0x00,                    // reserved(4) + program_info_length(12)
        streamType,                    // stream_type
        (uint8_t)(0xE0 | (pid >> 8)),  // reserved(3) + elementary_PID high bits
        (uint8_t)(pid & 0xFF),         // elementary_PID low byte
        0xF0, 0x00                     // reserved(4) + ES_info_length(12) = 0
    };

    unsigned int crcResult = crc32b(pmtSectionStart, sizeof(pmtSectionStart));
    uint8_t crcBytes[4] = {(uint8_t)(crcResult >> 24), (uint8_t)(crcResult >> 16), (uint8_t)(crcResult >> 8), (uint8_t)crcResult};

    uint8_t pointerField = 0x00;
    [pmtSection appendBytes:&pointerField length:1];
    [pmtSection appendBytes:pmtSectionStart length:17];
    [pmtSection appendBytes:crcBytes length:4];
    return pmtSection;
}

-(NSMutableData*)buildTSPackets:(NSData*)pesPacket pid:(uint16_t)pid packetCounter:(uint8_t*)packetCounter pcr:(NSNumber*)pcr useSectionPadding:(BOOL)useSectionPadding {
    int offset = 0;
    NSMutableData *finishedPackets = [NSMutableData data];

    while (offset < [pesPacket length]) {
        NSMutableData *tsPacket = [NSMutableData data];
        BOOL containsPayload = YES;
        BOOL containsAdaption = NO;
        BOOL containsPCR = NO;

        uint8_t byte1 = 0x00;
        uint8_t byte2 = 0x00;

        if (offset == 0) { // packet start
            byte1 |= 0b01000000;   
            if (pcr) {
                // must add PCR
                containsAdaption = YES;
                containsPCR = YES;
            }
        }

        // length calculations
        int dataNeeded = 4;
        if (containsPCR)
            dataNeeded+=8; // Adaption header + PCR

        int payloadToWrite = 188-dataNeeded;

        if ([pesPacket length] < offset + payloadToWrite) {
            payloadToWrite = [pesPacket length] - offset;
            if (!useSectionPadding)
                containsAdaption = YES;
        }
    

        byte1 |= ((pid >> 8) & 0b00011111);
        byte2 = (pid & 0xFF);

        
        uint8_t byte3 = *packetCounter;
        byte3 &= 0x0F; // value is 4 bits at the end

        if (containsAdaption)
            byte3 |= 0b00100000;
        if (containsPayload) {
            byte3 |= 0b00010000;
            *packetCounter += 1;
        }
        uint8_t tsHeader[4] = { 0x47, byte1, byte2, byte3 };
        [tsPacket appendBytes:tsHeader length:4];
        if (containsAdaption) {
            if (payloadToWrite == 183 && !containsPCR) {
                const uint8_t blankPCR = {0x00}; // handle the one byte of padding case 
                [tsPacket appendBytes:&blankPCR length:1];
            } else {
                // figure out how much we need to pad
                int32_t lengthToPad = 184 - ([pesPacket length] - offset); // 184 is total packet size - ts header

                lengthToPad-=2; //adaption header length
                if (containsPCR)
                    lengthToPad-=6;

                if (lengthToPad < 0)
                    lengthToPad = 0;

                uint8_t adaptionLength = lengthToPad+1; // length
                uint8_t adaptionFlags = 0b00000000; // bunch of metadata bout the container

                if (containsPCR) {
                    adaptionFlags |= 0b00010000; // enable PCR
                    adaptionLength += 6;
                }

                uint8_t adaption[2] = {adaptionLength, adaptionFlags };
                [tsPacket appendBytes:adaption length:2];

                if (containsPCR) {
                    uint64_t base = [pcr unsignedLongLongValue] / 300;
                    uint16_t extension = (uint16_t)([pcr unsignedLongLongValue] % 300);
                    base &= 0x1FFFFFFFFULL;
                    extension &= 0x1FF;

                    // 33 bits base, 6 bits reserved, 9 bits extension
                    uint8_t byte7 = (uint8_t)((base & 0x1) << 7); // last bit of base + 6 reserved + first bit of extension
                    byte7 |= (uint8_t)((extension >> 8) & 0x1); 
                    byte7 |= 0b01111110;

                    uint8_t adaptionPCR[6] = {
                        (uint8_t)((base >> 25) & 0xFF), 
                        (uint8_t)((base >> 17) & 0xFF), 
                        (uint8_t)((base >> 9) & 0xFF), 
                        (uint8_t)((base >> 1) & 0xFF), 
                        byte7,
                        (uint8_t)(extension & 0xFF)
                    };

                    [tsPacket appendBytes:adaptionPCR length:6];
                }

                // write filler bytes
                if (lengthToPad > 0) {
                    const uint8_t fillerBytes = {0xFF};
                    for (int i = 0; i<lengthToPad; i++) {
                        [tsPacket appendBytes:&fillerBytes length:1];
                    }
                }
            }
        }
        
        if (containsPayload) {
            [tsPacket appendData:[pesPacket subdataWithRange:NSMakeRange(offset,payloadToWrite)]];
        }

        if (useSectionPadding) {
            int16_t lengthToPad = 184 - ([pesPacket length] - offset);
            if (containsAdaption)
                lengthToPad-=2; //adaption header length
            if (containsAdaption && containsPCR)
                lengthToPad-=6;
            const uint8_t fillerBytes = {0xFF};
            for (int i = 0; i<lengthToPad; i++) {
                [tsPacket appendBytes:&fillerBytes length:1];
            }
        }

        if (containsPayload)
            offset+=payloadToWrite;
        
        [finishedPackets appendData:tsPacket];
    }
    
    

    return finishedPackets;
}

-(NSString*)generateHLSManifest {
    [self.manifestReady lock];

    while (!self.isReadyForPlayback) {
        [self.manifestReady wait];
    }

    [self.manifestReady unlock];

    NSMutableString *hlsManifest = [[NSMutableString alloc] init];
    [hlsManifest appendString:@"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-PLAYLIST-TYPE:VOD\n#EXT-X-MEDIA-SEQUENCE:0\n"];

    int maxDurationTicks = [[self.segmentIndexes valueForKeyPath:@"@max.intValue"] intValue];
    [hlsManifest appendFormat:@"#EXT-X-TARGETDURATION:%i\n", (uint8_t)(ceil((double)maxDurationTicks/(double)self.timescale))];

    int segmentIndex = 0;
    for (NSNumber *durationTicks in self.segmentIndexes) {
        [hlsManifest appendFormat:@"#EXTINF:%f,\ns%i-%05i.ts\n", [durationTicks doubleValue]/(double)self.timescale, self.itag, segmentIndex];
        segmentIndex++;
    }

    [hlsManifest appendString:@"#EXT-X-ENDLIST\n"];

    // finish
    NSString *final = [hlsManifest copy];
    [hlsManifest release];
    return final;
}

-(NSData*)convertFMP4ToMPEGTSWithIndex:(int)index {
    [self.segmentCondition lock];

    while (self.segmentData[@(index)] == nil) {
        [self.segmentCondition wait];
    }

    NSData *source = self.segmentData[@(index)];

    [self.segmentCondition unlock];

    TRMP4FragmentInfo *fragmentInfo = [[TRMP4FragmentInfo alloc] init];
    [self parseFMP4Fragment:source out:&fragmentInfo];

    if (!fragmentInfo.data || fragmentInfo.sampleSize.count == 0) {
        NSLog(@"[TubeReplacer] required format data is missing");
        [fragmentInfo release];
        return nil;
    }

    NSArray<NSData*> *samples = [self extractSamplesFromFragment:fragmentInfo];
    NSArray<NSData*> *annexB = [self convertSamplesToAnnexB:samples fragmentInfo:fragmentInfo];
    [samples release];
    
    double ticksTo90k = (90000.0 / (double)self.timescale);
    // NSMutableArray<NSData*> *pesPackets = [[NSMutableArray alloc] init];
    NSMutableData *finalTSData = [NSMutableData data];

    uint8_t streamId = 0;
    if (self.mediaType == TRSabrMediaTypeVideo) {
        streamId = 0xE0;
    } else {
        streamId = 0xC0;
    }

    uint8_t packetCounter = 0;
    uint8_t patPacketCounter = 0;
    uint8_t pmtPacketCounter = 0;
    uint8_t lastMetadataInsertion = 0;

    uint64_t baseMediaDecodeTimeRunning = fragmentInfo.baseMediaDecodeTime;
    for (uint32_t i = 0; i < fragmentInfo.sampleCount; i++) {
        uint64_t dts = (uint64_t)llround(baseMediaDecodeTimeRunning * ticksTo90k);
        uint64_t pts = (uint64_t)llround((baseMediaDecodeTimeRunning + [fragmentInfo.sampleCompositionOffsets[i] doubleValue]) * ticksTo90k);

        if (i == 0 || dts >= lastMetadataInsertion + 45000) {
            // add PAT & PMT
            NSData *pat = [self buildPATSection];
            NSData *pmt = [self buildPMTSection:streamId];
            [finalTSData appendData:[self buildTSPackets:pat pid:0 packetCounter:&patPacketCounter pcr:nil useSectionPadding:YES]];
            [finalTSData appendData:[self buildTSPackets:pmt pid:0x1000 packetCounter:&pmtPacketCounter pcr:nil useSectionPadding:YES]];
            lastMetadataInsertion = dts;
        }

        NSData *pesPacket = [self createPESPacketFromData:annexB[i] pts:pts dts:dts];
        [finalTSData appendData:[self buildTSPackets:pesPacket pid:streamId packetCounter:&packetCounter pcr:[NSNumber numberWithUnsignedLongLong:dts * 300] useSectionPadding:NO]];
        [pesPacket release];
        if (fragmentInfo.sampleDuration.count == 0)
            baseMediaDecodeTimeRunning += fragmentInfo.defaultSampleDuration;
        else
            baseMediaDecodeTimeRunning += [fragmentInfo.sampleDuration[i] unsignedLongLongValue];

        
    }

    // NSLog(@"final ts data -> %@", finalTSData);
    [fragmentInfo release];
    return finalTSData;
}

-(void)updateBufferTime {
    // kinda awful
    int segmentNumber = 1;
    uint64_t segmentTimestamp = 0;
    double earliestTime = -1;
    int32_t earliestSegment = -1;
    int64_t latestTimeInScale = -1;
    int32_t latestSegment = -1;
    uint32_t observedSegments = 0;

    for (NSNumber *timestamp in self.segmentIndexes) {
        if (self.segmentData[@(segmentNumber)] != nil) {
            // we have that segment
            if (earliestTime == -1) {
                earliestTime = (double)segmentTimestamp/(double)self.timescale;
                earliestSegment = segmentNumber;
            }
        }
        segmentTimestamp += [timestamp unsignedLongLongValue];
        if (self.segmentData[@(segmentNumber)] != nil) {
            latestTimeInScale = segmentTimestamp;
            latestSegment = segmentNumber;
            observedSegments++;
        }

        if (observedSegments >= self.segmentData.count)
            break;

        segmentNumber++;

    }
    self.earliestTimestampBuffered = earliestTime;
    self.earliestSegmentIndexBuffered = earliestSegment;
    self.latestTimestampBuffered = (double)latestTimeInScale/(double)self.timescale;
    self.latestSegmentIndexBuffered = latestSegment;
}

-(void)dealloc {
    [_segmentIndexes release];
    [_segmentIndexesCombined release];
    [_segmentCondition release];
    [_manifestReady release];
    [_segmentData release];
    [_sps release];
    [_pps release];
    [super dealloc];
}
@end
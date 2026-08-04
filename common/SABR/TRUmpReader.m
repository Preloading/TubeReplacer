#import "TRUmpReader.h"
#include "common/SABR/TRSabrStream.h"
#include <Foundation/NSRange.h>
#include <objc/NSObjCRuntime.h>
#include <stdint.h>
#include <Foundation/NSData.h>
#import "TRUmpPart.h"

@implementation TRUmpReader

// was initally translated to objc by AI (because it chose to just spat it out for some reason), modified by me to support offsets
+(uint64_t)readVarint:(NSData *)data offset:(int*)offset {
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    NSUInteger available = data.length;

    if (available < 1) {
        [NSException raise:NSInvalidArgumentException format:@"No data to read varint from."];
    }

    uint8_t first = bytes[0 + *offset];
    uint64_t value;
    NSUInteger length;

    if ((first & 0x80) == 0x00) {
        // 0xxxxxxx -> 1 byte
        value = first;
        length = 1;
    } else if ((first & 0xC0) == 0x80) {
        // 10xxxxxx -> 2 bytes
        length = 2;
        if (available < length) goto insufficientData;
        value = (first & 0x3F) | ((uint64_t)bytes[1 + *offset] << 6);
    } else if ((first & 0xE0) == 0xC0) {
        // 110xxxxx -> 3 bytes
        length = 3;
        if (available < length) goto insufficientData;
        value = (first & 0x1F)
              | ((uint64_t)bytes[1 + *offset] << 5)
              | ((uint64_t)bytes[2 + *offset] << 13);
    } else if ((first & 0xF0) == 0xE0) {
        // 1110xxxx -> 4 bytes
        length = 4;
        if (available < length) goto insufficientData;
        value = (first & 0x0F)
              | ((uint64_t)bytes[1 + *offset] << 4)
              | ((uint64_t)bytes[2 + *offset] << 12)
              | ((uint64_t)bytes[3 + *offset] << 20);
    } else if (first == 0xF0) {
        // 5-byte case: prefix + 4 raw little-endian bytes
        length = 5;
        if (available < length) goto insufficientData;
        value = (uint64_t)bytes[1 + *offset]
              | ((uint64_t)bytes[2 + *offset] << 8)
              | ((uint64_t)bytes[3 + *offset] << 16)
              | ((uint64_t)bytes[4 + *offset] << 24);
    } else {
        [NSException raise:NSInvalidArgumentException
                     format:@"Invalid varint prefix byte: 0x%02X", first];
        length = 0; // unreachable, silences warning
        value = 0;
    }

    *offset = *offset + length;
    return value;

insufficientData:
    [NSException raise:NSInvalidArgumentException
                 format:@"Insufficient data to decode varint (need %lu bytes, have %lu).",
                        (unsigned long)length, (unsigned long)available];
    return 0; // unreachable
}

+(void)read:(NSData*)data handlePartWith:(void (^)(TRUmpPart *))partHandler {
    int offset = 0;

    while (offset < [data length]) {
        uint64_t partType = [self readVarint:data offset:&offset];
        uint64_t partSize = [self readVarint:data offset:&offset];
        if (offset > [data length]) {
            break;
        }
        NSData *partData = [data subdataWithRange:NSMakeRange(offset, partSize)];
        offset += partSize;
        TRUmpPart *part = [[TRUmpPart alloc] initWithType:partType data:partData];
        partHandler(part);
    }
}

@end
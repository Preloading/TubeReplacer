// - (uint64_t)readVarint:(NSData *)data bytesConsumed:(NSUInteger *)outConsumed {
//     const uint8_t *bytes = (const uint8_t *)data.bytes;
//     NSUInteger available = data.length;

//     if (available < 1) {
//         [NSException raise:NSInvalidArgumentException format:@"No data to read varint from."];
//     }

//     uint8_t first = bytes[0];
//     uint64_t value;
//     NSUInteger length;

//     if ((first & 0x80) == 0x00) {
//         // 0xxxxxxx -> 1 byte
//         value = first;
//         length = 1;
//     } else if ((first & 0xC0) == 0x80) {
//         // 10xxxxxx -> 2 bytes
//         length = 2;
//         if (available < length) goto insufficientData;
//         value = (first & 0x3F) | ((uint64_t)bytes[1] << 6);
//     } else if ((first & 0xE0) == 0xC0) {
//         // 110xxxxx -> 3 bytes
//         length = 3;
//         if (available < length) goto insufficientData;
//         value = (first & 0x1F)
//               | ((uint64_t)bytes[1] << 5)
//               | ((uint64_t)bytes[2] << 13);
//     } else if ((first & 0xF0) == 0xE0) {
//         // 1110xxxx -> 4 bytes
//         length = 4;
//         if (available < length) goto insufficientData;
//         value = (first & 0x0F)
//               | ((uint64_t)bytes[1] << 4)
//               | ((uint64_t)bytes[2] << 12)
//               | ((uint64_t)bytes[3] << 20);
//     } else if (first == 0xF0) {
//         // 5-byte case: prefix + 4 raw little-endian bytes
//         length = 5;
//         if (available < length) goto insufficientData;
//         value = (uint64_t)bytes[1]
//               | ((uint64_t)bytes[2] << 8)
//               | ((uint64_t)bytes[3] << 16)
//               | ((uint64_t)bytes[4] << 24);
//     } else {
//         [NSException raise:NSInvalidArgumentException
//                      format:@"Invalid varint prefix byte: 0x%02X", first];
//         length = 0; // unreachable, silences warning
//         value = 0;
//     }

//     if (outConsumed) {
//         *outConsumed = length;
//     }
//     return value;

// insufficientData:
//     [NSException raise:NSInvalidArgumentException
//                  format:@"Insufficient data to decode varint (need %lu bytes, have %lu).",
//                         (unsigned long)length, (unsigned long)available];
//     return 0; // unreachable
// }
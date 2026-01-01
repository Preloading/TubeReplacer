// yet another thing that is vibecoded :(
// protobuf is AAAAAAAAAAAAAAAAAAAA
// feel free to rewrite this! I dislike having vibecoded code in here, but I did not want to deal with protobuf

#include "Protobuf.h"

@implementation ProtobufEncoder

- (instancetype)init {
    if (self = [super init]) {
        _buffer = [NSMutableData data];
    }
    return self;
}

- (NSData *)dataRepresentation {
    return [_buffer copy];
}

- (void)writeVarint:(uint64_t)value {
    while (value > 0x7F) {
        uint8_t byte = (uint8_t)((value & 0x7F) | 0x80);
        [_buffer appendBytes:&byte length:1];
        value >>= 7;
    }
    uint8_t final = (uint8_t)(value & 0x7F);
    [_buffer appendBytes:&final length:1];
}

- (void)writeFixed32:(uint32_t)value {
    uint32_t v = value;
    [_buffer appendBytes:&v length:4];
}

- (void)writeFixed64:(uint64_t)value {
    uint64_t v = value;
    [_buffer appendBytes:&v length:8];
}

- (void)writeLengthDelimited:(NSData *)data {
    [self writeVarint:(uint64_t)data.length];
    if (data.length) [_buffer appendData:data];
}

- (void)writeKey:(uint32_t)field wireType:(ProtobufWireType)wt {
    uint32_t key = (field << 3) | (wt & 0x7);
    [self writeVarint:key];
}

- (void)writeUInt32Field:(uint32_t)field value:(uint32_t)value {
    [self writeKey:field wireType:ProtobufWireTypeVarint];
    [self writeVarint:value];
}

- (void)writeUInt64Field:(uint32_t)field value:(uint64_t)value {
    [self writeKey:field wireType:ProtobufWireTypeVarint];
    [self writeVarint:value];
}

static inline uint32_t zigzag32(int32_t n) {
    return ((uint32_t)n << 1) ^ (uint32_t)(n >> 31);
}
static inline uint64_t zigzag64(int64_t n) {
    return ((uint64_t)n << 1) ^ (uint64_t)(n >> 63);
}

- (void)writeSInt32Field:(uint32_t)field value:(int32_t)value {
    [self writeKey:field wireType:ProtobufWireTypeVarint];
    [self writeVarint:zigzag32(value)];
}

- (void)writeSInt64Field:(uint32_t)field value:(int64_t)value {
    [self writeKey:field wireType:ProtobufWireTypeVarint];
    [self writeVarint:zigzag64(value)];
}

- (void)writeFixed32Field:(uint32_t)field value:(uint32_t)value {
    [self writeKey:field wireType:ProtobufWireType32Bit];
    [self writeFixed32:value];
}

- (void)writeFixed64Field:(uint32_t)field value:(uint64_t)value {
    [self writeKey:field wireType:ProtobufWireType64Bit];
    [self writeFixed64:value];
}

- (void)writeBytesField:(uint32_t)field data:(NSData *)data {
    [self writeKey:field wireType:ProtobufWireTypeLengthDelimited];
    [self writeLengthDelimited:data];
}

- (void)writeStringField:(uint32_t)field string:(NSString *)string {
    NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data];
    [self writeBytesField:field data:d];
}

- (void)writeMessageField:(uint32_t)field usingBlock:(void(^)(ProtobufEncoder *encoder))block {
    ProtobufEncoder *child = [[ProtobufEncoder alloc] init];
    if (block) block(child);
    NSData *d = [child dataRepresentation];
    [self writeKey:field wireType:ProtobufWireTypeLengthDelimited];
    [self writeLengthDelimited:d];
}

@end
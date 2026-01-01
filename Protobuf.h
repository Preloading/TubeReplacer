#import <Foundation/Foundation.h>

typedef NS_ENUM(uint32_t, ProtobufWireType) {
    ProtobufWireTypeVarint = 0,
    ProtobufWireType64Bit = 1,
    ProtobufWireTypeLengthDelimited = 2,
    ProtobufWireType32Bit = 5
};

@interface ProtobufEncoder : NSObject
@property (nonatomic, strong) NSMutableData *buffer;
- (instancetype)init;
- (NSData *)dataRepresentation;

// Primitive writes
- (void)writeVarint:(uint64_t)value;
- (void)writeFixed32:(uint32_t)value;
- (void)writeFixed64:(uint64_t)value;
- (void)writeLengthDelimited:(NSData *)data;

// Field helpers
- (void)writeKey:(uint32_t)field wireType:(ProtobufWireType)wt;
- (void)writeUInt32Field:(uint32_t)field value:(uint32_t)value;
- (void)writeUInt64Field:(uint32_t)field value:(uint64_t)value;
- (void)writeSInt32Field:(uint32_t)field value:(int32_t)value;
- (void)writeSInt64Field:(uint32_t)field value:(int64_t)value;
- (void)writeFixed32Field:(uint32_t)field value:(uint32_t)value;
- (void)writeFixed64Field:(uint32_t)field value:(uint64_t)value;
- (void)writeBytesField:(uint32_t)field data:(NSData *)data;
- (void)writeStringField:(uint32_t)field string:(NSString *)string;
- (void)writeMessageField:(uint32_t)field usingBlock:(void(^)(ProtobufEncoder *encoder))block;
@end

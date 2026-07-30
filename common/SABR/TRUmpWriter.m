#import "TRUmpWriter.h"

@implementation TRUMPWriter : NSObject

-(instancetype)init {
    [super init];
    self.compositeBuffer = [[NSMutableData alloc] init];
    return self;
}


-(void)writeVarInt:(uint)value {
    uint8_t buffer[5];
    NSUInteger length;

    if (value < 128) {
        buffer[0] = (uint8_t)value;
        length = 1;
    } else if (value < 16384) {
        buffer[0] = (uint8_t)((value & 0x3F) | 0x80);
        buffer[1] = (uint8_t)(value >> 6);
        length = 2;
    } else if (value < 2097152) {
        buffer[0] = (uint8_t)((value & 0x1F) | 0xC0);
        buffer[1] = (uint8_t)((value >> 5) & 0xFF);
        buffer[2] = (uint8_t)(value >> 13);
        length = 3;
    } else if (value < 268435456) {
        buffer[0] = (uint8_t)((value & 0x0F) | 0xE0);
        buffer[1] = (uint8_t)((value >> 4) & 0xFF);
        buffer[2] = (uint8_t)((value >> 12) & 0xFF);
        buffer[3] = (uint8_t)(value >> 20);
        length = 4;
    } else {
        buffer[0] = 0xF0;
        uint32_t v = (uint32_t)value;
        buffer[1] = (uint8_t)(v & 0xFF);
        buffer[2] = (uint8_t)((v >> 8) & 0xFF);
        buffer[3] = (uint8_t)((v >> 16) & 0xFF);
        buffer[4] = (uint8_t)((v >> 24) & 0xFF);
        length = 5;
    }

    return [self.compositeBuffer appendBytes:buffer length:length];
}

-(void)writeData:(NSData*)data withPartType:(uint)partType {
    [self writeVarInt:partType];
    [self writeVarInt:[data length]];


    // const partSize = partData.length;
    // this.writeVarInt(partType);
    // this.writeVarInt(partSize);
    // this.compositeBuffer.append(partData);
    [self.compositeBuffer appendData:data];

}


-(void)dealloc {
    [_compositeBuffer release];
    [super dealloc];
}

@end
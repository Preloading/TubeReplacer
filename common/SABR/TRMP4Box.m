#include "TRMP4Box.h"

@implementation TRMP4Box

-(instancetype)parseMP4Box:(NSData*)data atOffset:(int*)boxOffset {
    self = [super init];

    uint32_t boxLength;
    [data getBytes:&boxLength range:NSMakeRange(*boxOffset, 4)];
    boxLength = CFSwapInt32BigToHost(boxLength);
    *boxOffset += 4;

    _type = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(*boxOffset, 4)] encoding:NSUTF8StringEncoding];
    *boxOffset += 4;

    _data = [data subdataWithRange:NSMakeRange(*boxOffset, boxLength-8)];
    return self;
}

-(int)length {
    return [_data length];
}

@end
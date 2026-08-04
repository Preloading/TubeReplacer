#import "TRUmpPart.h"

@implementation TRUmpPart

-(instancetype)initWithType:(uint64_t)type data:(NSData*)data {
    self.type = type;
    self.data = data;
    return self;
}

-(void)dealloc {
    [_data release];
    [super dealloc];
}
@end
#include "video_streaming/UmpPartId.pbobjc.h"
#include <Foundation/Foundation.h>

@interface TRUmpPart : NSObject
@property (nonatomic, assign) UMPPartId type;
@property (nonatomic, strong) NSData *data;

-(instancetype)initWithType:(uint64_t)type data:(NSData*)data;
@end
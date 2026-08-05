#include <Foundation/Foundation.h>

@interface TRMP4Box : NSObject
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSData *data;

-(instancetype)parseMP4Box:(NSData*)data atOffset:(int*)boxOffset;
-(int)length;
@end
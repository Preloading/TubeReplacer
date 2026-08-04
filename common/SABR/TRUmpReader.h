#include "common/SABR/TRUmpPart.h"
#import <Foundation/Foundation.h>

@interface TRUmpReader : NSObject

+(uint64_t)readVarint:(NSData *)data offset:(int*)offset;
+(void)read:(NSData*)data handlePartWith:(void (^)(TRUmpPart *))partHandler;
@end
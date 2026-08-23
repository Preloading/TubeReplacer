#include "common/SABR/TRUmpPart.h"
#import <Foundation/Foundation.h>

@interface TRUmpReader : NSObject
// reads as much SABR data as is presently in the NSData specified.
// @returns amount of data successfully read
+(NSUInteger)read:(NSData*)data handlePartWith:(void (^)(TRUmpPart *))partHandler;
@end
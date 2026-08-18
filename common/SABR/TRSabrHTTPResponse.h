#include "lib/cocoahttpserver/HTTPResponse.h"
#import "TRSabrMedia.h"
#include <objc/NSObjCRuntime.h>

@interface TRSabrHTTPResponse : NSObject <HTTPResponse>
{
	BOOL done;
    NSUInteger offset;
    TRSabrMedia *media;
    NSData *bufferedOut;
    int segment;
}
-(instancetype)initWithMedia:(TRSabrMedia*)mediaIn andSegment:(int)segmentIn;
@end
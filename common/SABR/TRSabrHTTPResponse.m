#include "TRSabrHTTPResponse.h"
#include <Foundation/NSString.h>

@implementation TRSabrHTTPResponse

-(instancetype)initWithMedia:(TRSabrMedia*)mediaIn andSegment:(int)segmentIn {
    if((self = [super init]))
	{
		offset = 0;
        done = NO;
		media = [mediaIn retain];
        segment = segmentIn;
	}
	return self;
}

- (void)dealloc
{
    [bufferedOut release];
    [media release];
	[super dealloc];
}

-(BOOL)isChunked {
    return YES;
}

- (UInt64)contentLength
{
    if (bufferedOut != nil)
        return (UInt64)[bufferedOut length];
    return 0;
}

- (UInt64)offset
{
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
	offset = (unsigned)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
    if (segment == 0) {
        if (!media.isReadyForPlayback && bufferedOut == nil)
            return nil;
        
        if (bufferedOut == nil) {
            bufferedOut = [[media generateHLSManifest] dataUsingEncoding:NSUTF8StringEncoding];
        }
    } else {
        if (media.segmentData[@(segment)] == nil && bufferedOut == nil)
            return nil;

        if (bufferedOut == nil) {
            bufferedOut = [media convertFMP4ToMPEGTSWithIndex:segment];
        }
    }

    done = YES;
    return [bufferedOut retain];
}

- (BOOL)isDone
{
	return done;
}


- (BOOL)isAsynchronous
{
	return YES;
}
@end
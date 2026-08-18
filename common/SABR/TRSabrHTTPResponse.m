#include "TRSabrHTTPResponse.h"
#include <Foundation/NSString.h>

@implementation TRSabrHTTPResponse

-(instancetype)initWithMedia:(TRSabrMedia*)mediaIn andSegment:(int)segmentIn {
    if((self = [super init]))
	{
		offset = 0;
        done = NO;
		media = mediaIn;
        segment = segmentIn;
	}
	return self;
}

- (void)dealloc
{
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
    NSLog(@"read called!");
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
        NSLog(@"read done!");
    return [bufferedOut retain];
    
    // NSUInteger remaining = [bufferedOut length] - offset;
	// NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	// void *bytes = (void *)([bufferedOut bytes] + offset);
	
	// offset += length;
	
	// return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
    NSLog(@"done check!");
	return done;
}


- (BOOL)isAsynchronous
{
	return YES;
}
@end
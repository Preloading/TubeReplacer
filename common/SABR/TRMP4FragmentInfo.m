#include "TRMP4FragmentInfo.h"

@implementation TRMP4FragmentInfo

-(void)dealloc {
    [_data release];
    [_sampleDuration release];
    [_sampleSize release];
    [_sampleCompositionOffsets release];
    [_sampleFlags release];
    [super dealloc];
}

@end
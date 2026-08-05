#include <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <stdint.h>

@interface TRMP4FragmentInfo : NSObject
@property (nonatomic, strong) NSData *data;

@property (nonatomic, assign) uint64_t defaultSampleDuration;
@property (nonatomic, assign) uint64_t defaultSampleSize;
@property (nonatomic, assign) uint64_t defaultSampleFlags;


@property (nonatomic, strong) NSArray *sampleDuration;
@property (nonatomic, strong) NSArray *sampleSize;
@property (nonatomic, strong) NSArray *sampleFlags;

@property (nonatomic, assign) uint64_t sampleCount;
@end
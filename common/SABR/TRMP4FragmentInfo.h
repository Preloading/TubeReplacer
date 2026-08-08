#include <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <stdint.h>

@interface TRMP4FragmentInfo : NSObject
@property (nonatomic, strong) NSData *data;

// tfhd
@property (nonatomic, assign) uint32_t trackId;
@property (nonatomic, assign) BOOL hasDefaultSampleDuration;
@property (nonatomic, assign) uint32_t defaultSampleDuration;
@property (nonatomic, assign) BOOL hasDefaultSampleSize;
@property (nonatomic, assign) uint32_t defaultSampleSize;
@property (nonatomic, assign) BOOL hasDefaultSampleFlags;
@property (nonatomic, assign) uint32_t defaultSampleFlags;

// tfdt
@property (nonatomic, assign) uint64_t baseMediaDecodeTime;

// trun
@property (nonatomic, strong) NSArray<NSNumber*> *sampleDuration;
@property (nonatomic, strong) NSArray<NSNumber*> *sampleSize;
@property (nonatomic, strong) NSArray<NSNumber*> *sampleCompositionOffsets;
@property (nonatomic, strong) NSArray<NSNumber*> *sampleFlags;
@end
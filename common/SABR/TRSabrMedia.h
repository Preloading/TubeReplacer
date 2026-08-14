#include <Foundation/Foundation.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSLock.h>

typedef NS_ENUM(NSInteger, TRSabrMediaType) {
    TRSabrMediaTypeUnknown = 0,
    TRSabrMediaTypeVideo,
    TRSabrMediaTypeAudio,
};

@interface TRSabrMedia : NSObject
// the itag of the specific media
@property (nonatomic, assign) int itag;
@property (nonatomic, assign) TRSabrMediaType mediaType;

@property (nonatomic, assign) BOOL isReadyForPlayback;
@property (nonatomic, strong) NSCondition *manifestReady;

// contains the time duration of each segment, in ticks, including the segments we do not have downloaded yet, starting from 0 
@property (nonatomic, strong) NSArray *segmentIndexes;
// contains the time durations all combined together, starting from 0
@property (nonatomic, strong) NSArray *segmentIndexesCombined;

// the full NSData of each segment (excl. the header), indexed by the sequence number provided by SABR. This starts at 1.
@property (nonatomic, strong) NSMutableDictionary *segmentData;
@property (nonatomic, strong) NSCondition *segmentCondition;

// how many ticks per second.
@property (nonatomic, assign) uint32_t timescale;

/// VIDEO SPECIFIC
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;
@property (nonatomic, assign) int lengthScaleMinusOne;

/// buffer info
@property (nonatomic, assign) double earliestTimestampBuffered;
@property (nonatomic, assign) uint32_t earliestSegmentIndexBuffered;
@property (nonatomic, assign) double latestTimestampBuffered;
@property (nonatomic, assign) uint32_t latestSegmentIndexBuffered;

-(void)parseMP4Header:(NSData*)header;
-(void)addNewFMP4FragmentWithID:(int)fragmentId data:(NSData*)data;
-(NSString*)generateHLSManifest;
-(NSData*)convertFMP4ToMPEGTSWithIndex:(int)index;
-(void)updateBufferTime;
@end
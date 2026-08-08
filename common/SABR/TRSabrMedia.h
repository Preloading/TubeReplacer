#include <Foundation/Foundation.h>
#include <Foundation/NSDictionary.h>

typedef NS_ENUM(NSInteger, TRSabrMediaType) {
    TRSabrMediaTypeUnknown = 0,
    TRSabrMediaTypeVideo,
    TRSabrMediaTypeAudio,
};

@interface TRSabrMedia : NSObject
// the itag of the specific media
@property (nonatomic, assign) int itag;
@property (nonatomic, assign) TRSabrMediaType mediaType;

// @property (nonatomic, assign) BOOL isAudio;
// contains the time duration of each segment, in ticks, including the segments we do not have downloaded yet 
@property (nonatomic, strong) NSArray *segmentIndexes;
// the full NSData of each segment (excl. the header), indexed by the sequence number provided by SABR
@property (nonatomic, strong) NSMutableDictionary *segmentData;

// how many ticks per second.
@property (nonatomic, assign) uint32_t timescale;

/// VIDEO SPECIFIC
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;
@property (nonatomic, assign) int lengthScaleMinusOne;


-(void)parseMP4Header:(NSData*)header;
-(NSString*)generateHLSManifest;
-(NSData*)convertFMP4ToMPEGTSWithIndex:(int)index;
@end
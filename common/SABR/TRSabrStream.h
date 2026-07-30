#import <Foundation/Foundation.h>

@interface TRSabrStream : NSObject
@property (nonatomic, strong) NSString *decipheredStreamURL; // this URL is deciphered
@property (nonatomic, strong) NSData *ustreamConfig;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSData *coldstart;
@property (nonatomic, strong) NSData *poToken;
@property (nonatomic, strong) NSArray *formats;

@property (nonatomic, strong) NSArray *videoFormatsWeHave;
@property (nonatomic, strong) NSArray *audioFormatsWeHave;

@property (nonatomic, assign) int requestNumber;

-(instancetype)initWithStreamUrl:(NSString*)streamURL ustreamConfig:(NSString*)ustreamConfig formats:(NSArray*)formats videoId:(NSString*)videoId;
@end
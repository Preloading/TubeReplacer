#import <Foundation/Foundation.h>

// Youtube accepts a variety of clients, with each having different things they can do
@interface YoutubeClientType : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nameProto;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *screen;
@property (nonatomic, strong) NSString *osName;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSString *platform;
@property (nonatomic, strong) NSString *useragent;
@property (nonatomic, strong) NSDictionary *configData;

// web
+(YoutubeClientType*)webClient;
// +(YoutubeRequestClient*)webEmbeddedPlayer;
+(YoutubeClientType*)webSafariClient;
+(YoutubeClientType*)tvEmbeddedClient;
+(YoutubeClientType*)webMobileClient;
// +(YoutubeRequestClient*)webScreenEmbed;
// +(YoutubeRequestClient*)webCreator;

// android
+(YoutubeClientType*)androidClient;

-(NSDictionary*)makeContext;
@end
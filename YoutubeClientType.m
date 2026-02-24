#import "YoutubeClientType.h"
#include <Foundation/Foundation.h>

@implementation YoutubeClientType

+(YoutubeClientType*)webClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"web";
    client.nameProto = @"1";
    client.version   = @"2.20250222.10.00";
    client.screen    = @"WATCH_FULL_SCREEN";
    client.osName    = @"Windows";
    client.osVersion = @"10.0";
    client.platform  = @"DESKTOP";
    return client;
}

// apparently doesn't need POToken with HLS
+(YoutubeClientType*)webSafariClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"web";
    client.nameProto = @"1";
    client.version   = @"2.20250222.10.00";
    client.useragent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15,gzip(gfe)";
    client.screen    = @"WATCH_FULL_SCREEN";
    return client;
} 

+(YoutubeClientType*)webMobileClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"mweb";
    client.nameProto = @"2";
    client.version   = @"2.20251222.01.00";
    client.osName    = @"iOS";
    client.osVersion = @"18";
    client.platform  = @"MOBILE";
    return client;
}

// +(YoutubeClientType*)webMobileClient {
//     YoutubeClientType *client = [[YoutubeClientType alloc] init];
//     client.name      = @"mweb";
//     client.nameProto = @"2";
//     client.version   = @"2.20250224.01.00";
//     client.osName    = @"Android";
//     client.osVersion = @"11";
//     client.platform  = @"MOBILE";
//     return client;
// }

+(YoutubeClientType*)androidClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"ANDROID";
    client.version   = @"20.10.38";
    client.osName    = @"Android";
    client.osVersion = @"11";
    client.platform  = @"MOBILE";
    return client;
}
+(YoutubeClientType*)iosClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"IOS";
    client.version   = @"21.08.3";
    client.osName    = @"iPhone";
    client.osVersion = @"18.5.0.22F76";
    client.platform  = @"MOBILE";
    return client;
}
+(YoutubeClientType*)tvEmbeddedClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"TVHTML5_SIMPLY_EMBEDDED_PLAYER";
    client.version   = @"2.0";
    client.osName    = @"Android";
    client.osVersion = @"11";
    client.platform  = @"TV";
    return client;
}

-(NSDictionary*)makeContext {
    NSMutableDictionary *clientContext = [[NSMutableDictionary alloc] init];
    [clientContext setObject:@"en" forKey:@"hl"]; // todo: make this a correct language
    [clientContext setObject:@"US" forKey:@"gl"]; // todo: also make this a correct country, since we get given the country.
    [clientContext setObject:[self name] forKey:@"clientName"];
    [clientContext setObject:[self version] forKey:@"clientVersion"];
    if ([self osName]) {
        [clientContext setObject:[self osName] forKey:@"osName"];
    }
    if ([self osVersion]) {
        [clientContext setObject:[self osVersion] forKey:@"osVersion"];
    }
    if ([self platform]) {
        [clientContext setObject:[self platform] forKey:@"platform"];
    }
    if ([self useragent]) {
        [clientContext setObject:[self useragent] forKey:@"userAgent"];
    }
    if ([self configData]) {
        [clientContext setObject:[self configData] forKey:@"configData"];
    }
    
    // there is more, but hopefully this will be fine for now?

    return @{@"client":clientContext};
}
@end

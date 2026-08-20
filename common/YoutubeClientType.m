#import "YoutubeClientType.h"
#include <Foundation/Foundation.h>

@implementation YoutubeClientType

+(YoutubeClientType*)webClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"web";
    client.nameProto = @"1";
    client.version   = @"2.20260623.01.00";
    client.screen    = @"WATCH_FULL_SCREEN";
    client.useragent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15,gzip(gfe)";
    client.platform  = @"DESKTOP";
    return client;
}

+(YoutubeClientType*)webMobileClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"mweb";
    client.nameProto = @"2";
    client.version   = @"2.20260205.04.01";
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
    client.nameProto = @"3";
    client.version   = @"20.10.38";
    client.osName    = @"Android";
    client.osVersion = @"11";
    client.platform  = @"MOBILE";
    return client;
}

+(YoutubeClientType*)androidVrClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"ANDROID_VR";
    client.nameProto = @"28";
    client.version   = @"1.60.19";
    client.osName    = @"Oculus";
    client.osVersion = @"12L";
    client.platform  = @"MOBILE";
    return client;
}

+(YoutubeClientType*)iosClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"IOS";
    client.nameProto = @"5";
    client.version   = @"21.08.3";
    client.osName    = @"iPhone";
    client.osVersion = @"18.5.0.22F76";
    client.platform  = @"MOBILE";
    return client;
}

+(YoutubeClientType*)visionOSClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"VISIONOS";
    client.nameProto = @"101";
    client.version   = @"1.02";
    client.osName    = @"visionOS";
    client.osVersion = @"26.5.23O471";
    client.useragent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15";
    return client;
}

+(YoutubeClientType*)tvEmbeddedClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"TVHTML5_SIMPLY_EMBEDDED_PLAYER";
    client.version   = @"2.0";
    client.nameProto = @"85";
    client.osName    = @"Android";
    client.osVersion = @"11";
    client.platform  = @"TV";
    return client;
}

+(YoutubeClientType*)webStudioClient {
    YoutubeClientType *client = [[YoutubeClientType alloc] init];
    client.name      = @"62";// i dont actually know if this will cause a problem or not.
    client.nameProto = @"62";
    client.version   = @"1.20260518.01.00";
    return client;
}

-(NSDictionary*)makeContext {
    NSMutableDictionary *clientContext = [[NSMutableDictionary alloc] init];
    [clientContext setObject:@"en" forKey:@"hl"]; //[[NSLocale preferredLanguages] objectAtIndex:0] forKey:@"hl"]; // so this also localizes a few other things, like time :)
    [clientContext setObject:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] forKey:@"gl"];
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

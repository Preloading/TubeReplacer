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
    
    // there is more, but hopefully this will be fine for now?

    return @{@"client":clientContext};
}
@end
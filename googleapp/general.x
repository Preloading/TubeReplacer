#include "appheaders.h"
#import <objc/runtime.h>

%hook YTGDataService
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuthenticator:(id)a6 {
    id orig = %orig();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

// 1.1.0+
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuth:(id)a6 requestFactory:(id)a7 {
    id orig = %orig();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

%new
-(YTCache*)channelCache {
    return objc_getAssociatedObject(self, @"channelCache_");
}

%new
- (void)cacheChannel:(YTChannel*)channel
{
//     for (id entry in [channel entries]) {
//         id video = [entry video]; 
    if (channel) {
        NSLog(@"Cached Channel!");
        [[self channelCache] setObject:channel forKey:[channel channelID]];
        NSLog(@"cache count a -> %i", [(NSArray*)[[self channelCache] allKeys] count]);
    }

    // }
}


%end
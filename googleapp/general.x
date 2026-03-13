#include "appheaders.h"
#include "general.h"
#import "sys/utsname.h"
#import <objc/runtime.h>

%hook YTGDataService
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuthenticator:(id)a6 {
    id orig = %orig();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

// 1.1.0
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuth:(id)a6 requestFactory:(id)a7 {
    id orig = %orig();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

// 1.2.1+
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 requestFactory:(id)a7 {
    id orig = %orig();
    if (orig) {
        id channelCache = [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500];
        objc_setAssociatedObject(orig, @"channelCache_", channelCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        [[self channelCache] setObject:channel forKey:[channel channelID]];
    }

    // }
}


%end

%ctor {
    // this is general analytics so I know if people actually use this, and to answer the long awaited question: do people actually use iOS 5?!??!
    NSString *versionFilePath = @"/var/mobile/Library/Preferences/.tubereplacer_lastversion.txt";

    NSError *readError = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:versionFilePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&readError];

    NSString *currentVersion = TRPackageVersion(@"dev.preloading.tubereplacer");
    BOOL was_updated = NO;
    if (fileContent) {
        if ([currentVersion isEqualToString:fileContent]) {
            return;
        }
        was_updated = YES;
    } else if (readError && readError.code != NSFileReadNoSuchFileError) {
        NSLog(@"Error reading version file: %@", readError.localizedDescription);
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://preloading.dev/tweaks/science/firstload.php"]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding];

    [postDict setValue:@"tubereplacer_google" forKey:@"name"];
    [postDict setValue:deviceString forKey:@"devicemodel"];
    [postDict setValue:[[UIDevice currentDevice] systemVersion] forKey:@"deviceversion"];
    [postDict setValue:currentVersion forKey:@"tweakversion"];
    [postDict setValue:version() forKey:@"appversion"];
    [postDict setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] firstObject] forKey:@"language"];
    [postDict setValue:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] forKey:@"country"];
    [postDict setValue:@(was_updated) forKey:@"was_updated"];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:nil];
    request.HTTPBody = jsonData;
    [[NSURLConnection alloc] initWithRequest:request delegate:nil startImmediately:YES];

    NSError *writeError = nil;
    BOOL success = [currentVersion writeToFile:versionFilePath
                                    atomically:YES
                                      encoding:NSUTF8StringEncoding
                                         error:&writeError];

    if (!success) {
        NSLog(@"Error writing to file: %@", writeError.localizedDescription);
    }
}
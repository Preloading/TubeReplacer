#include "appheaders.h"
#include "general.h"
#import "sys/utsname.h"
#import <objc/runtime.h>

static void analytics() {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0UL);
    dispatch_async(queue,^{
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
            if ([currentVersion isEqualToString:@"disable"]) {
                return; // used to prevent my own device from posting useless analytics to my server
            }
            was_updated = YES;
        } else if (readError && readError.code != NSFileReadNoSuchFileError) {
            NSLog(@"Error reading version file: %@", readError.localizedDescription);
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://preloading.dev/tweaks/science/firstload.php"]];
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

        NSURLResponse * response = nil;
        NSError * error = nil;
        [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response
                                                            error:&error];
            
        if (error == nil)
        {
            NSError *writeError = nil;
            BOOL success = [currentVersion writeToFile:versionFilePath
                                            atomically:YES
                                            encoding:NSUTF8StringEncoding
                                                error:&writeError];

            if (!success) {
                NSLog(@"Error writing to file: %@", writeError.localizedDescription);
            }
        }

        
    });
}
static void compat_check() {
    // ipad ios 9+ check
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        if (([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"] || [version() isEqualToString:@"1.2.1"])) {
            NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
            if ([systemVersion floatValue] >= 9.0) {

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Compatibility Alert"
                                                        message:@"iOS 9 and above on iPad have issues when on YouTube versions 1.2.1 and below. It is highly recommended to update to YouTube 1.3.0 or above for complete functionality. See \"Known Issues\" in TubeReplacer\'s cydia description for further info. You can install newer YouTube versions through the \"Install YouTube\" section in the Cydia description."
                                                    delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }
    }
    if ([version() characterAtIndex:0] != '1') {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Compatibility Alert"
                                                message:@"YouTube versions above 1.4.0 are not supported on this version of TubeReplacer. Either check for an update to TubeReplacer, or downgrade to an earlier version of YouTube. You can install compatible YouTube versions through the \"Install YouTube\" section in the Cydia description."
                                            delegate:nil
                                    cancelButtonTitle:@"OK"
                                    otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

%hook YTGDataService
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuthenticator:(id)a6 {
    id orig = %orig();
    compat_check();
    analytics();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

// 1.1.0
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 userAuth:(id)a6 requestFactory:(id)a7 {
    id orig = %orig();
    compat_check();
    analytics();
    if (orig) {
        objc_setAssociatedObject(orig, @"channelCache_", [[%c(YTCache) alloc] initWithExpirationInterval:1086070784 countLimit:500], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orig;
}

// 1.2.1+
-(YTGDataService*)initWithOperationQueue:(id)a3 HTTPFetcherService:(id)a4 deviceAuthorizer:(id)a5 requestFactory:(id)a7 {
    id orig = %orig();
    compat_check();
    analytics();
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

%hook GIPSpeechController 

-(NSString*)serverURL
{
  return @"http://www.google.com/m/voice-search"; // this may be useful for debugging it later, but it's C++ bullshit that frankly, i don't wanna deal with.
}
    
%end


%hook NSAssertionHandler
    
- (void) handleFailureInFunction:(NSString *) functionName 
                            file:(NSString *) fileName 
                      lineNumber:(NSInteger) line 
                     description:(NSString *) format {
    NSLog(@"Assert failed! Function %@ @ %@:%i, %@",functionName,fileName,(int)line,format);
    return %orig;
}

- (void)handleFailureInMethod:(SEL)selector 
                        object:(id)object 
                          file:(NSString *)fileName 
                    lineNumber:(NSInteger)line 
                   description:(NSString *)format, ... {
    
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"[GTM-Assert-Hook] Method: %@ | File: %@:%ld | Error: %@", 
          NSStringFromSelector(selector), 
          fileName.lastPathComponent, 
          (long)line, 
          description);

    %orig;
}

%end

// todo: so i don't forget this, i want to find a way of selectively blocking this.
%hook YTItemListHeader 

-(BOOL)itemCountHidden {
    return YES;
}

%end


%hook YTItemListHeader
-(void)setItemCount:(unsigned int)count
{
    // NSLog(@"the count is %i",count);
    if (count == 2147483647) return;
    return %orig;
}
%end
#import <execinfo.h>



%hook YTPage 
-(int)totalResults
{
//       void *callstack[128];
//   int frames = backtrace(callstack, 128);
//   char **symbols = backtrace_symbols(callstack, frames);
//   NSMutableString *callstackString = [NSMutableString stringWithFormat:@"uwu >_<"];
//   for (int i = 0; i < frames; i++) {
//   [callstackString appendFormat:@"%s\n", symbols[i]];
//   }
    // NSLog(@"%@", callstackString);
    int orig = %orig;
    NSLog(@"total results 2 = %i", orig);
    return orig;
}
%end
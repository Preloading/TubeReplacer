#include <Foundation/Foundation.h>
#import "appheaders.h"

// 1.0.6 -> 2.0.0

%hook YTSplashScreenViewController 

-(void)loadView {
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"StreamType"] isEqualToString:@"adaptive"] || [preferences[@"StreamType"] isEqualToString:@"360p"] || [preferences[@"StreamType"] isEqualToString:@"360pvr"]) {
        preferences[@"StreamType"] = @"web";
        [preferences writeToFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist" atomically:YES];
    }

    preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"StreamType"] isEqualToString:@"adaptive"] || [preferences[@"StreamType"] isEqualToString:@"360p"] || [preferences[@"StreamType"] isEqualToString:@"360pvr"]) {
        [%c(GIPToast) showToast:@"Auto Migration failed! Check FAQ in cydia page for solution." forDuration:10.0];
    }
    return %orig;
}

%end
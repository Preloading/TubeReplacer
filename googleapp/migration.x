#include <Foundation/Foundation.h>

// 1.0.6 -> 2.0.0
%ctor {
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"StreamType"] isEqualToString:@"adaptive"] || [preferences[@"StreamType"] isEqualToString:@"360p"] || [preferences[@"StreamType"] isEqualToString:@"360pvr"]) {
        preferences[@"StreamType"] = @"web";
        [preferences writeToFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist" atomically:YES];
    }
}
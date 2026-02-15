#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import "YTRPRootListController.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"
#define NOTIFY_NAME CFSTR("dev.preloading.tubereplacer.preferences/settingschanged")

@implementation YTRPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        
        // Check current preference value
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
        NSString *selectedValue = prefs[@"StreamType"] ?: @"adaptive";
        
        // Only show text field if "custom" is selected
        if (![selectedValue isEqualToString:@"custom"]) {
            NSInteger indexToRemove = NSNotFound;
            for (NSInteger i = 0; i < specs.count; i++) {
                PSSpecifier *spec = specs[i];
                if ([spec.properties[@"key"] isEqualToString:@"CustomStreamURL"]) {
                    indexToRemove = i;
                    break;
                }
            }
            if (indexToRemove != NSNotFound) {
                [specs removeObjectAtIndex:indexToRemove];
            }
        }
        
        _specifiers = specs;
    }

    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    
    // Reload when list selection changes
    if ([specifier.properties[@"key"] isEqualToString:@"StreamType"]) {
        _specifiers = nil;
        [self reloadSpecifiers];
    }
}

-(void)resetCategorySettings{
    NSLog(@"Resetting category settings");

    // Define all category keys and their default values (from Root.plist)
    NSDictionary *defaultValues = @{
        // Trending
        @"TrendingBrowseId": @"VLPL-p0-Yh03xpi2AsCiyuafMeQrMF6czMoL",
        // Film
        @"FilmName": @"Film & Animation",
        @"FilmBrowseId": @"VLPL-p0-Yh03xpgQgBqDn3T4EZbxoaYXkQjY",
        // Auto
        @"AutoName": @"Autos & Vehicles",
        @"AutoBrowseId": @"VLPL-p0-Yh03xphS0WmPB1u5mQbRJjPRn63U",
        // Music
        @"MusicName": @"Music",
        @"MusicBrowseId": @"VLPL-p0-Yh03xpgeN91B_sPpv4lJY-UfThEi",
        // Animals
        @"AnimalsName": @"Pets & Animals",
        @"AnimalsBrowseId": @"VLPL-p0-Yh03xpgqRqXBDc9DbcCysUjd_CSB",
        // Sports
        @"SportsName": @"Sports",
        @"SportsBrowseId": @"VLPL-p0-Yh03xpg6CLD7MDqzsAiB9aFjssWb",
        // Travel
        @"TravelName": @"Travel",
        @"TravelBrowseId": @"",
        // Games
        @"GamesName": @"Gaming",
        @"GamesBrowseId": @"VLPL-p0-Yh03xpi_x9L-Lqop_Kj6MTY38jqv",
        // Comedy
        @"ComedyName": @"Comedy",
        @"ComedyBrowseId": @"VLPL-p0-Yh03xpj0Js3pnGO20BWWiHVn1oHz",
        // People
        @"PeopleName": @"People & Blogs",
        @"PeopleBrowseId": @"VLPL-p0-Yh03xphi7-iBuIshu7olymbv7lY-",
        // News
        @"NewsName": @"News & Politics",
        @"NewsBrowseId": @"VLPL-p0-Yh03xpgeG3YUmWESSrg84W8ELEUO",
        // Entertainment
        @"EntertainmentName": @"Entertainment",
        @"EntertainmentBrowseId": @"VLPL-p0-Yh03xpjoqDAI46lgo8-TLDnE7mHF",
        // Education
        @"EducationName": @"Education",
        @"EducationBrowseId": @"",
        // Howto
        @"HowtoName": @"Howto & Style",
        @"HowtoBrowseId": @"VLPL-p0-Yh03xphCxNSaXOW09V3pKgRQCFvn",
        // Nonprofit
        @"NonprofitName": @"Nonprofits & Activism",
        @"NonprofitBrowseId": @"",
        // Tech
        @"TechName": @"Science & Technology",
        @"TechBrowseId": @"VLPL-p0-Yh03xpgQgBqDn3T4EZbxoaYXkQjY"
    };

    // Load current prefs
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (!prefs) prefs = [NSMutableDictionary dictionary];

    // Set defaults for all category keys
    [defaultValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        prefs[key] = value;
    }];

    // Save back to disk
    [prefs writeToFile:PREFS_PATH atomically:YES];

    // Notify system of changes
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), NOTIFY_NAME, NULL, NULL, YES);

    // Reload UI
    _specifiers = nil;
    [self reloadSpecifiers];
}

@end
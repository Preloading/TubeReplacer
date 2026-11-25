#import <Foundation/Foundation.h>
#include <spawn.h>
#import <Preferences/PSSpecifier.h>
#import "YTRPRootListController.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"
#define NOTIFY_NAME CFSTR("dev.preloading.tubereplacer.preferences/settingschanged")

@implementation YTRPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
        NSString *selectedValue = [prefs objectForKey:@"StreamType"] ?: @"web";
        
        if (![selectedValue isEqualToString:@"custom"]) {
            NSInteger indexToRemove = NSNotFound;
            for (NSInteger i = 0; i < specs.count; i++) {
                PSSpecifier *spec = [specs objectAtIndex:i];
                if ([[spec.properties objectForKey:@"key"] isEqualToString:@"CustomStreamURL"]) {
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
    if ([[specifier.properties objectForKey:@"key"] isEqualToString:@"StreamType"]) {
        [self killYouTube];
        _specifiers = nil;
        [self reloadSpecifiers];
    }
}

-(void)resetCategorySettings{
    NSLog(@"Resetting category settings");

    // Define all category keys and their default values (from Root.plist)
    NSDictionary *defaultValues = @{
        // Trending
        @"TrendingBrowseId": @"VLPLbgMm37FwiYk",
        // Film
        @"FilmName": @"Film & Animation",
        @"FilmBrowseId": @"VLPLQl1BIAhZO8E",
        // Auto
        @"AutoName": @"Autos & Vehicles",
        @"AutoBrowseId": @"VLPLBw4JXJysQ4s",
        // Music
        @"MusicName": @"Music",
        @"MusicBrowseId": @"VLPLCiHOpZqcEeQ",
        // Animals
        @"AnimalsName": @"Pets & Animals",
        @"AnimalsBrowseId": @"VLPLSzKMzJ51-ts",
        // Sports
        @"SportsName": @"Sports",
        @"SportsBrowseId": @"VLPLT3_gZAgYD0A",
        // Travel
        @"TravelName": @"Travel",
        @"TravelBrowseId": @"VLPLZKugeBmg4Wk",
        // Games
        @"GamesName": @"Gaming",
        @"GamesBrowseId": @"VLPLKleUjYjNPFk",
        // Comedy
        @"ComedyName": @"Comedy",
        @"ComedyBrowseId": @"VLPLXIYrLoXbXbY",
        // People
        @"PeopleName": @"People & Blogs",
        @"PeopleBrowseId": @"VLPLVm4sO2Q3j1I",
        // News
        @"NewsName": @"News & Politics",
        @"NewsBrowseId": @"VLPLZfbKlafuccI",
        // Entertainment
        @"EntertainmentName": @"Entertainment",
        @"EntertainmentBrowseId": @"VLPLaM7bIkoJFVs",
        // Education
        @"EducationName": @"Education",
        @"EducationBrowseId": @"",
        // Howto
        @"HowtoName": @"Howto & Style",
        @"HowtoBrowseId": @"VLPLZSHpCBcDPz8",
        // Nonprofit
        @"NonprofitName": @"Nonprofits & Activism",
        @"NonprofitBrowseId": @"VLPPLQYpFIOJv4Z4",
        // Tech
        @"TechName": @"Science & Technology",
        @"TechBrowseId": @"VLPLTfc2mqePDSY"
    };

    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (!prefs) prefs = [NSMutableDictionary dictionary];

    [defaultValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [prefs setObject:value forKey:key];
    }];

    [prefs writeToFile:PREFS_PATH atomically:YES];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), NOTIFY_NAME, NULL, NULL, YES);

    // Reload UI
    _specifiers = nil;
    [self reloadSpecifiers];
}

-(void)killYouTube {
    pid_t pid;

    char *argv[] = {
        "killall",
        "-9",
        "YouTube",
        NULL
    };

    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, argv, NULL);
}

@end

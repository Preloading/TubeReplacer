#import <Foundation/Foundation.h>
#include <spawn.h>
#import <Preferences/PSSpecifier.h>
#import "YTRPRootListController.h"
#include "common/localizer.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"
#define NOTIFY_NAME CFSTR("dev.preloading.tubereplacer.preferences/settingschanged")

@implementation YTRPRootListController

-(NSDictionary*)defaultValues {
    return @{
        // Trending
        @"TrendingBrowseId": @"VLPLbgMm37FwiYk",
        // Film
        @"FilmName": localizedStringForKeyTR(@"category.film_name"),
        @"FilmBrowseId": @"VLPLQl1BIAhZO8E",
        // Auto
        @"AutoName": localizedStringForKeyTR(@"category.auto_name"),
        @"AutoBrowseId": @"VLPLBw4JXJysQ4s",
        // Music
        @"MusicName": localizedStringForKeyTR(@"category.music_name"),
        @"MusicBrowseId": @"VLPLCiHOpZqcEeQ",
        // Animals
        @"AnimalsName": localizedStringForKeyTR(@"category.animals_name"),
        @"AnimalsBrowseId": @"VLPLSzKMzJ51-ts",
        // Sports
        @"SportsName": localizedStringForKeyTR(@"category.sports_name"),
        @"SportsBrowseId": @"VLPLT3_gZAgYD0A",
        // Travel
        @"TravelName": localizedStringForKeyTR(@"category.travel_name"),
        @"TravelBrowseId": @"VLPLZKugeBmg4Wk",
        // Games
        @"GamesName": localizedStringForKeyTR(@"category.games_name"),
        @"GamesBrowseId": @"VLPLKleUjYjNPFk",
        // Comedy
        @"ComedyName": localizedStringForKeyTR(@"category.comedy_name"),
        @"ComedyBrowseId": @"VLPLXIYrLoXbXbY",
        // People
        @"PeopleName": localizedStringForKeyTR(@"category.people_name"),
        @"PeopleBrowseId": @"VLPLVm4sO2Q3j1I",
        // News
        @"NewsName": localizedStringForKeyTR(@"category.news_name"),
        @"NewsBrowseId": @"VLPLZfbKlafuccI",
        // Entertainment
        @"EntertainmentName": localizedStringForKeyTR(@"category.entertainment_name"),
        @"EntertainmentBrowseId": @"VLPLaM7bIkoJFVs",
        // Education
        @"EducationName": localizedStringForKeyTR(@"category.education_name"),
        @"EducationBrowseId": @"",
        // Howto
        @"HowtoName": localizedStringForKeyTR(@"category.howto_name"),
        @"HowtoBrowseId": @"VLPLZSHpCBcDPz8",
        // Nonprofit
        @"NonprofitName": localizedStringForKeyTR(@"category.nonprofit_name"),
        @"NonprofitBrowseId": @"VLPPLQYpFIOJv4Z4",
        // Tech
        @"TechName": localizedStringForKeyTR(@"category.tech_name"),
        @"TechBrowseId": @"VLPLTfc2mqePDSY"
    };
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        
        for (PSSpecifier *specifier in specs) {
            if ([[specifier propertyForKey:@"default"] isKindOfClass:[NSString class]]) {
                if ([[specifier propertyForKey:@"default"] hasPrefix:@"category"]) {
                    [specifier setProperty:localizedStringForKeyTR([specifier propertyForKey:@"default"]) forKey:@"default"];
                }
            }
        }

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
    NSDictionary *defaultValues = [self defaultValues];

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

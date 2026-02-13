#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import "YTRPRootListController.h"

@implementation YTRPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        
        // Check current preference value
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
        NSString *selectedValue = prefs[@"StreamType"] ?: @"option1";
        
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

@end
#include "localizer.h"

static NSDictionary *localizationData = nil;

void loadLocalizationData() {
    NSArray<NSString *> *availableLanguages = @[@"en", @"es"];
    for (NSString *language in [NSBundle preferredLocalizationsFromArray:availableLanguages]) {
        NSDictionary *localeDataTemp = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/TubeReplacer/locale/%@.strings", language]];
        if (localeDataTemp != nil) {
            #if __has_feature(objc_arc)
            localizationData = localeDataTemp;
            #else
            localizationData = [localeDataTemp retain];
            #endif
            return;
        }
    }
    #if __has_feature(objc_arc)
    localizationData = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/TubeReplacer/locale/en.strings"];
    #else
    localizationData = [[NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/TubeReplacer/locale/en.strings"] retain];
    #endif
}

NSString *localizedStringForKeyTR(NSString *key) {
    if (localizationData == nil) {
        loadLocalizationData();
    }
    NSString *out = localizationData[key];
    if (out == nil) {
        return key;
    }
    return out;
}
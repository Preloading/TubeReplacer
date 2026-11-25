#include "localizer.h"

static NSDictionary *localizationData = nil;

void loadLocalizationData() {
    for (NSString *language in [NSLocale preferredLanguages]) {
        NSDictionary *localeDataTemp = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/TubeReplacer/locale/%@.strings", language]];
        if (localeDataTemp != nil) {
            localizationData = localeDataTemp;
            return;
        }
    }
    localizationData = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/TubeReplacer/locale/en.strings"];
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
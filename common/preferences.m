#include "preferences.h"

bool PreferencesBoolValue(NSDictionary* preferences, NSString *key, bool defaultValue) {
    id value = [preferences objectForKey:key]; 
    
    if (value == nil || value == [NSNull null]) {
        return defaultValue;
    }
    
    return [value boolValue];
}

NSString *PreferencesGetVideoStreamPreference(NSDictionary* preferences) {
    id value = [preferences objectForKey:@"StreamType"]; 
    
    if (value == nil || value == [NSNull null]) {
        return @"android";
    }
    
    return value;
}
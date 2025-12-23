#include <Foundation/Foundation.h>

%hook __NSArrayM //NSArray 

%new
- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    // Check if the original implementation exists
    // id original = %orig;
    // if (original) {
    //     return original;
    // }
    // Fall back to objectAtIndex: if original doesn't exist
    return [self objectAtIndex:idx];
}

%end

%hook __NSCFDictionary

%new
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

%end
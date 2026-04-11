// MIT License

// Copyright (c) 2025 Preloading

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// This polyfill lets you use some more modern syntax for looking up array objects & dictionary objects.


#include <Foundation/Foundation.h>

@interface __NSArrayM : NSMutableArray
@end

@interface __NSCFDictionary : NSMutableDictionary
@end

%hook __NSArrayM

%new
- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        return [self objectAtIndex:idx];
    }
    return %orig;
}

%new
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        [self replaceObjectAtIndex:idx withObject:obj];
    }
    return %orig;
}

%end

%hook __NSCFDictionary

%new
- (id)objectForKeyedSubscript:(id)key {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        return [self objectForKey:key];
    }
    return %orig;
}

%new
- (void)setObject:(id)obj forKeyedSubscript:(id)key {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        [self setObject:obj forKey:key];
    }
    return %orig;
}

%end
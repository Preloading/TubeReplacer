#import "general.h"
#include <Foundation/Foundation.h>

@interface NSBundle (YouTube)
-(NSString*)localizedQuantityStringForKey:(NSString*)key quantity:(NSUInteger)quantity table:(NSString*)table;
@end

NSString* localizedStringForKey(NSString *key)
{
  NSBundle *v2 = [NSBundle mainBundle];
  return [v2 localizedStringForKey:key value:key table:0];
}

NSString* localizedStringForKey2(NSString *key, NSUInteger quantity) {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle localizedQuantityStringForKey:key quantity:quantity table:@"Localizable"];
}

NSString* localizedStringForKey2UILib(NSString *key, NSUInteger quantity) {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle localizedQuantityStringForKey:key quantity:quantity table:@"UILib"];
}

NSString* localizedStringForKeyUILib(NSString *key) {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle localizedStringForKey:key value:key table:@"UILib"];
}



// youtube has a built in version checker... but they changed the version checker name between versions.... soooooooo
NSString* version() {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

// i want to kill you youtube, or apple for this

// creates the local variable version (variable_), since the compiler or youtube changed this, and it's in too many places to do my normal checking of version.
NSString* l(NSString *local) {
  if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"] || [version() isEqualToString:@"1.2.1"]) {
    return [NSString stringWithFormat:@"%@_", local];
  } else {
    return [NSString stringWithFormat:@"_%@", local];
  }
}

NSString *TRPackageVersion(NSString *packageID) {
    NSError *err = nil;
    NSString *status = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/status"
                                                 encoding:NSUTF8StringEncoding
                                                    error:&err];
    if (!status.length) return nil;

    NSArray<NSString *> *blocks = [status componentsSeparatedByString:@"\n\n"];
    NSString *needle = [NSString stringWithFormat:@"Package: %@", packageID];

    for (NSString *block in blocks) {
        if ([block rangeOfString:needle].location != NSNotFound) {
            for (NSString *line in [block componentsSeparatedByString:@"\n"]) {
                if ([line hasPrefix:@"Version: "]) {
                    return [line substringFromIndex:@"Version: ".length];
                }
            }
        }
    }
    return nil;
}

NSString *URLDecode(NSString *string) {
    if (!string) return nil;
    
    NSMutableString *result = [NSMutableString string];
    NSUInteger length = [string length];
    NSUInteger i = 0;
    
    while (i < length) {
        unichar c = [string characterAtIndex:i];
        if (c == '%' && i + 2 < length) {
            // Try to parse the hex value
            NSString *hexStr = [string substringWithRange:NSMakeRange(i + 1, 2)];
            NSScanner *scanner = [NSScanner scannerWithString:hexStr];
            unsigned int hexValue;
            
            if ([scanner scanHexInt:&hexValue]) {
                [result appendFormat:@"%C", (unichar)hexValue];
                i += 3; // Skip the '%' and the two hex digits
            } else {
                // If it's not a valid hex sequence, just add the '%'
                [result appendString:@"%"];
                i++;
            }
        } else if (c == '+') {
            // '+' is decoded as space
            [result appendString:@" "];
            i++;
        } else {
            // Not encoded, add as is
            [result appendFormat:@"%C", c];
            i++;
        }
    }
    
    return result;
}
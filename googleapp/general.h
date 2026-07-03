#include <Foundation/Foundation.h>

NSString* localizedStringForKey(NSString *key);
NSString* localizedStringForKey2(NSString *key, NSUInteger quantity);
NSString* localizedStringForKey2UILib(NSString *key, NSUInteger quantity);
NSString* version();
NSString* l(NSString *local);
NSString *TRPackageVersion(NSString *packageID);
bool PreferencesBoolValue(NSDictionary* preferences, NSString *key, bool defaultValue);
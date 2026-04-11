#include <Foundation/Foundation.h>

NSString* localizedStringForKey(NSString *key);
NSString* version();
NSString* l(NSString *local);
NSString *TRPackageVersion(NSString *packageID);
bool PreferencesBoolValue(NSDictionary* preferences, NSString *key, bool defaultValue);
#import "general.h"

NSString* localizedStringForKey(NSString *key)
{
  NSBundle *v2 = [NSBundle mainBundle];
  return [v2 localizedStringForKey:key value:key table:0];
}


// youtube has a built in version checker... but they changed the version checker name between versions.... soooooooo
NSString* version() {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
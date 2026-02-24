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

// i want to kill you youtube, or apple for this

// creates the local variable version (variable_), since the compiler or youtube changed this, and it's in too many places to do my normal checking of version.
NSString* l(NSString *local) {
  if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"] || [version() isEqualToString:@"1.2.1"]) {
    return [NSString stringWithFormat:@"%@_", local];
  } else {
    return [NSString stringWithFormat:@"_%@", local];
  }
}
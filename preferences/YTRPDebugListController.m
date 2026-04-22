#import "YTRPDebugListController.h"
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>

@implementation YTRPDebugListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Debug" target:self];
    }
    return _specifiers;
}
@end
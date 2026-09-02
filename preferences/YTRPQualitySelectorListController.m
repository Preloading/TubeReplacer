#import "YTRPQualitySelectorListController.h"
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <MessageUI/MessageUI.h>

@implementation YTRPQualitySelectorListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"QualitySelector" target:self];
    }
    return _specifiers;
}
@end
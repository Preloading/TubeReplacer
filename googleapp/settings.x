#import <Foundation/Foundation.h>
#import "appheaders.h"

@interface YTSettingsPickerViewController : YTContainerViewController <UITableViewDataSource, UITableViewDelegate>
- (void)tableView:(id)fp8 didSelectRowAtIndexPath:(id)fp12;
- (int)tableView:(id)fp8 numberOfRowsInSection:(int)fp12;
- (int)numberOfSectionsInTableView:(id)fp8;
- (id)tableView:(id)fp8 cellForRowAtIndexPath:(id)fp12;
- (void)setChoiceTarget:(id)fp8 action:(SEL)fp12;
- (void)dealloc;
- (id)init;
- (id)initWithResourceLoader:(id)fp8 title:(id)fp12 items:(id)fp16 selectedItemIndex:(unsigned int)fp20;

@end


// %hook YTSettingsViewController
// -(YTSettingsViewController*) initWithServices:(YTServices*)services navigation:(YTLiveServices*)navigation {
//     YTSettingsViewController *controller = %orig;

//     [[%c(YTSettingsPickerViewController) alloc] initWithResourceLoader:[services resourceLoader] title:@"tubereplacer" items:@[@"red pill", @"blue pill"] selectedItemIndex:0];
    
//     return controller;
// }


// %end


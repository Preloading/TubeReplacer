#import <Preferences/PSListController.h>
#import <MessageUI/MessageUI.h>

@interface YTRPDebugListController : PSListController <MFMailComposeViewControllerDelegate>
-(void)emailLogs;
-(void)clearLogs;
@end

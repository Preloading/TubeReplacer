#import "YTRPDebugListController.h"
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <MessageUI/MessageUI.h>

@implementation YTRPDebugListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Debug" target:self];
    }
    return _specifiers;
}
-(void)emailLogs {
    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/tubereplacer_network_log.txt"  options:0 error:&error];
    if (error) {
        NSLog(@"error loading log contents! error -> %@", error);
        return;
    }
    MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
    mcvc.mailComposeDelegate = self;
    NSString *toAddress = @"me@preloading.dev";
    [mcvc setToRecipients:[NSArray arrayWithObjects:toAddress,nil]];
    [mcvc setSubject:@"TubeReplacer Network Dump"];
    [mcvc setMessageBody:@"This email contains responses from YouTube that the TubeReplacer tweak recieved. This may contain sensitive information, be careful with sharing it!\n\nYouTube version (fill this in):\n\nTubeReplacer Version (fill this in):\n\nWhat is the issue you are having? (fill this in):" isHTML:NO];
    [mcvc addAttachmentData:data mimeType:@"text/plain" fileName:@"networkdump.txt"];
    [self presentViewController:mcvc animated:YES completion:NULL];

} 

-(void)clearLogs {
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/Library/Preferences/tubereplacer_network_log.txt" contents:[NSData data] attributes:nil];

}

- (void)mailComposeController:(MFMailComposeViewController *)controller 
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
@end
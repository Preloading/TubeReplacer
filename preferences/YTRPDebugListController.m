#import "YTRPDebugListController.h"
#include <Foundation/NSString.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <MessageUI/MessageUI.h>
#import "lib/zip/src/zip.h"

NSString *TRPackageVersion(NSString *packageID) {
    NSError *err = nil;
    NSString *status = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/status"
                                                 encoding:NSUTF8StringEncoding
                                                    error:&err];
    if (!status.length) return nil;

    NSArray<NSString *> *blocks = [status componentsSeparatedByString:@"\n\n"];
    NSString *needle = [NSString stringWithFormat:@"Package: %@", packageID];
    NSLog(@"status -> %@", status);

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
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    char *outbuf = NULL;
    size_t outbufsize = 0;
    // from the readme of kuba--'s zip
    struct zip_t *zip = zip_stream_open(NULL, 0, ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');
    {
        zip_entry_open(zip, "tubereplacer_network_log.txt");
        {
            zip_entry_write(zip, [dataString UTF8String], [dataString length]);
        }
        zip_entry_close(zip);
        /* copy compressed stream into outbuf */
        zip_stream_copy(zip, (void **)&outbuf, &outbufsize);
    }
    zip_stream_close(zip);

    NSData *compressedData = [[NSData alloc] initWithBytes:outbuf length:outbufsize];
    free(outbuf);

    MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
    mcvc.mailComposeDelegate = self;
    NSString *toAddress = @"me+tubereplacernetworkdump@preloading.dev";
    [mcvc setToRecipients:[NSArray arrayWithObjects:toAddress,nil]];
    [mcvc setSubject:@"TubeReplacer Network Dump"];
    [mcvc setMessageBody:[NSString stringWithFormat:@"This email contains responses from YouTube that the TubeReplacer tweak recieved. This may contain sensitive information, be careful with sharing it!\n\nYouTube version (fill this in):\n\nTubeReplacer Version: %@\n\nWhat is the issue you are having? (fill this in):", TRPackageVersion(@"dev.preloading.tubereplacer")] isHTML:NO];
    [mcvc addAttachmentData:compressedData mimeType:@"application/zip" fileName:@"networkdump.zip"];
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
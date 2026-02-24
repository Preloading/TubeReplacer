#import <Foundation/Foundation.h>
#import "appheaders.h"

@interface SomeProtobufClassIDontWantToRE

-(NSData*)data;

@end

@interface GIPFeedbackCollectedData

-(id)crashReport;
-(SomeProtobufClassIDontWantToRE*)exportAsProto;

@end

@interface GIPCrashReportData

-(void)setReportStatus:(int)a1;

@end

@interface GIPFeedback

-(BOOL)hasInternetConnection;

@end


@interface GIPFeedbackLocalizedString

+(id)sendMessageString;
+(id)sendMessageLaterString;

@end



%hook GIPFeedback

+ (void)submitFeedbackWithCollectedData:(GIPFeedbackCollectedData *)collectedData
{
    // Grab crash report from collected data
    GIPCrashReportData *crashReport = [collectedData crashReport];

    // Build request
    NSURL *url = [NSURL URLWithString:
        @"https://preloading.dev/tweaks/tubereplacer/crashreports.php"];

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url];

    [request setValue:@"application/x-protobuf"
        forHTTPHeaderField:@"Content-Type"];

    // Create fetcher
    GTMHTTPFetcher *fetcher =
        [%c(GTMHTTPFetcher) fetcherWithRequest:request];

    // Attach protobuf payload
    NSData *postData = [[collectedData exportAsProto] data];
    [fetcher setPostData:postData];

    // Show toast depending on connectivity
    if ([self hasInternetConnection]) {
        NSString *message =
            [%c(GIPFeedbackLocalizedString) sendMessageString];
        [%c(GIPToast) showToast:message forDuration:3.0];
    } else {
        NSString *message =
            [%c(GIPFeedbackLocalizedString) sendMessageLaterString];
        [%c(GIPToast) showToast:message forDuration:3.0];

        // Mark crash report as "pending"
        [crashReport setReportStatus:0];
    }

    // Begin async fetch
    [fetcher beginFetchWithCompletionHandler:
     ^(NSData *data, NSError *error) {

         // NOTE: In your decompilation this pointer type
         // looks slightly off, but behavior is clear:
         // status = 2 on error, 1 on success

         if (error) {
             [crashReport setReportStatus:2];   // failed
         } else {
             [crashReport setReportStatus:1];   // success
         }
     }];

    // Post notification
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"kGIPFeedbackDidSubmitFeedbackNotification"
                      object:self];
}

%end
#import <Foundation/Foundation.h>
#import "appheaders.h"
#import "common/Protobuf.h"
#import "general.h"
#import <execinfo.h>
#import <mach-o/dyld.h>

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
    GIPCrashReportData *crashReport = [collectedData crashReport];

    NSURL *url = [NSURL URLWithString:
        @"http://preloading.dev/tweaks/tubereplacer/crashreports.php"];

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url];

    [request setValue:@"application/x-protobuf"
        forHTTPHeaderField:@"Content-Type"];
        
    GTMHTTPFetcher *fetcher =
        [%c(GTMHTTPFetcher) fetcherWithRequest:request];

    NSData *postData = [[collectedData exportAsProto] data];

    // patching the protobuf to add some extra info about tubereplacer
    ProtobufEncoder *pb = [[ProtobufEncoder alloc] initWithExistingData:postData];

    [pb writeMessageField:5 usingBlock:^(ProtobufEncoder *tbSpecific) {
        [tbSpecific writeStringField:1 string:TRPackageVersion(@"dev.preloading.tubereplacer")];
    }];

    [fetcher setPostData:[[pb dataRepresentation] retain]];

    if ([self hasInternetConnection]) {
        NSString *message =
            [%c(GIPFeedbackLocalizedString) sendMessageString];
        [%c(GIPToast) showToast:message forDuration:3.0];
    } else {
        NSString *message =
            [%c(GIPFeedbackLocalizedString) sendMessageLaterString];
        [%c(GIPToast) showToast:message forDuration:3.0];

        [crashReport setReportStatus:0];
    }

    [fetcher beginFetchWithCompletionHandler:
     ^(NSData *data, NSError *error) {
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

// %hook GIPFeedbackCrashReportHandler

// - (id)initWithViewController:(id)controller categoryTag:(id)categoryTag
// {
//     intptr_t slide = _dyld_get_image_vmaddr_slide(0);
//     NSLog(@"ASLR Slide Offset: 0x%lx", (unsigned long)slide);

//     NSLog(@"controller = %@", controller);
//     NSLog(@"controller class = %@", [controller class]);

//     void *callstack[128];
//     int frames = backtrace(callstack, 128);
//     char **symbols = backtrace_symbols(callstack, frames);

//     NSMutableString *callstackString =
//         [NSMutableString stringWithString:@"uwu >_<"];

//     for (int i = 0; i < frames; i++)
//         [callstackString appendFormat:@"%s\n", symbols[i]];

//     free(symbols);

//     NSLog(@"%@", callstackString);

//     return %orig(controller, categoryTag);
// }

// - (void)alertView:(id)alertView clickedButtonAtIndex:(int)clickedButtonIndex
// {
//     NSLog(@"alert aaaaaaa");
//     NSLog(@"view controller -> %@", [self valueForKey:@"viewController_"]);

//     %orig(alertView, clickedButtonIndex);
// }

// %end
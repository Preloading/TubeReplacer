#import "common/SABR/TRUmpPart.h"
#include <stdint.h>
#import <Foundation/Foundation.h>
#import "googleapp/appheaders.h"

@interface TRSabrRequest : NSObject<NSURLConnectionDelegate> {
    NSMutableData *sabrBuffer;
    void (^partCallback)(TRUmpPart *);
    // error, isFatal
    void (^completionCallback)(NSError*,BOOL);
    uint32_t bytesDownloaded;
    NSDate *timeStarted;
}
@property (nonatomic, assign) uint32_t bandwidthAvailable;

- (void)startRequestWithURL:(NSURL*)requestURL body:(NSData*)body auth:(GTMOAuth2Authentication*)auth 
        partCallback:(void (^)(TRUmpPart *))partHandler completionCallback:(void (^)(NSError*,BOOL))setCompletionCallback;
@end
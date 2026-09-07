#import "common/SABR/TRUmpPart.h"
#import <Foundation/Foundation.h>
#import "googleapp/appheaders.h"

@interface TRSabrRequest : NSObject<NSURLConnectionDelegate> {
    NSMutableData *sabrBuffer;
    void (^partCallback)(TRUmpPart *);
    // error, isFatal
    void (^completionCallback)(NSError*,BOOL);
}

- (void)startRequestWithURL:(NSURL*)requestURL body:(NSData*)body auth:(GTMOAuth2Authentication*)auth 
        partCallback:(void (^)(TRUmpPart *))partHandler completionCallback:(void (^)(NSError*,BOOL))setCompletionCallback;

@end
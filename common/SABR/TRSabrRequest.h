#import "common/SABR/TRUmpPart.h"
#import <Foundation/Foundation.h>
#import "googleapp/appheaders.h"

@interface TRSabrRequest : NSObject<NSURLConnectionDelegate> {
    NSMutableData *sabrBuffer;
    void (^partCallback)(TRUmpPart *);
    void (^completionCallback)(NSError*);
}

- (void)startRequestWithURL:(NSURL*)requestURL body:(NSData*)body auth:(GTMOAuth2Authentication*)auth 
        partCallback:(void (^)(TRUmpPart *))partHandler completionCallback:(void (^)(NSError*))setCompletionCallback;

@end
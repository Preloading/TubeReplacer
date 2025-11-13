#include <Foundation/Foundation.h>

/// This is where we put headers that are used in more than one section/.x file

@interface YTUserAuthenticator: NSObject
- (id)authentication;
@end

@interface YTServices : NSObject
- (id)userAuthenticator;
@end

@interface YTFeedController : NSObject
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12 extraRequest:(id)fp16 extraServiceSelector:(SEL)fp20;
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12;
@end

@interface YTGuideFeedController: YTFeedController
- (void)loadAccountThumbnail;
- (void)handleEntries:(id)fp8;

@end 

@interface YTUtils
+ (id)userLanguageCode;
+ (id)userCountryCode;
@end

@interface YTGDataRequest
+ (id)requestForCategoriesWithLanguageCode:(id)fp8;
+ (id)requestForMySubscriptionsWithAuth:(id)fp8;
+ (id)requestForChannelsWithStandardFeed:(int)fp8;
@end
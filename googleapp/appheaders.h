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
+ (void)setUploadDateFilter:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setQueryParametersToURLBuilder:(id)fp8 withSafeSearch:(int)fp12;
+ (void)setFormatsToURLBuilder:(id)fp8;
+ (id)requestWithURLString:(id)fp8 authentication:(id)fp12 body:(id)fp16;
+ (id)requestWithURLString:(id)fp8 authentication:(id)fp12;
+ (id)requestWithURLString:(id)fp8;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12 body:(id)fp16 noCache:(BOOL)fp20;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12 body:(id)fp16;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12;
+ (id)requestForVideoWithVideoID:(id)fp8;
@end

@interface YTBaseService : NSObject
- (void)didReceiveMemoryWarning;
- (void)performMASFRequest:(id)fp8 serviceURI:(id)fp12 dataBlock:(id)fp errorBlock:(void)fp16;
- (void)performHTTPRequest:(id)fp8 parser:(id)fp12 responseBlock:(id)fp errorBlock:(void)fp16;
- (void)performHTTPRequest:(id)fp8 withAuthorizer:(id)fp12 parser:(id)fp16 responseBlock:(id)fp errorBlock:(void)fp20;
- (void)performHTTPRequest:(id)fp8 dataBlock:(id)fp errorBlock:(void)fp12;
- (void)performHTTPRequest:(id)fp8 withAuthorizer:(id)fp12 dataBlock:(id)fp errorBlock:(void)fp16;
- (void)performHTTPRequest:(id)fp8 withAuthorizer:(id)fp12 completionBlock:(id)fp;
- (void)performErrorBlock:(id)fp error:(void)fp8;
- (void)performResponseBlock:(id)fp response:(id)fp8;
- (void)performBackgroundBlock:(id)fp;
- (void)dealloc;
- (id)init;
- (id)initWithOperationQueue:(id)fp8;
- (id)initWithOperationQueue:(id)fp8 HTTPFetcherService:(id)fp12;

@end

@interface YTGDataService : YTBaseService
- (void)makeDELETERequest:(YTGDataRequest*)request withParser:(id)fp12 responseBlock:(id)fp errorBlock:(id)fp16;
- (void)makePOSTRequest:(YTGDataRequest*)request withParser:(id)parser responseBlock:(id)responseBlock errorBlock:(id)errorBlock;
- (void)makeWriteRequest:(YTGDataRequest*)request method:(NSString*)method parser:(id)fp16 responseBlock:(id)fp errorBlock:(id)fp20;
- (void)makeGETRequest:(YTGDataRequest*)request withParser:(id)fp12 responseBlock:(id)fp errorBlock:(id)fp16;
- (void)makeGETRequest:(id)request withParser:(id)fp12 cache:(id)fp16 responseBlock:(id)fp errorBlock:(id)fp20;
@end

@interface GTMURLBuilder : NSObject
{
    NSMutableDictionary *params_;
    NSString *baseURLString_;
}

+ (id)builderWithURL:(id)fp8;
+ (id)builderWithString:(id)fp8;
- (id)baseURLString;
- (BOOL)isEqual:(id)fp8;
- (id)URLString;
- (id)URL;
- (id)parameters;
- (void)setParameters:(id)fp8;
- (void)removeParameter:(id)fp8;
- (id)valueForParameter:(id)fp8;
- (void)setIntegerValue:(int)fp8 forParameter:(id)fp12;
- (void)setValue:(id)fp8 forParameter:(id)fp12;
- (void)dealloc;
- (id)initWithString:(id)fp8;
- (id)init;

@end

typedef struct _TBXMLElement {
	char * name;
	char * text;
	
	id firstAttribute; // TBXMLAttribute
	
	struct _TBXMLElement * parentElement;
	
	struct _TBXMLElement * firstChild;
	struct _TBXMLElement * currentChild;
	
	struct _TBXMLElement * nextSibling;
	struct _TBXMLElement * previousSibling;
	
} TBXMLElement;

@interface YTTBXMLElement : NSObject
// + (id)description:(id)fp8 indent:(int)fp12;//struct _TBXMLElement *
- (id)description;
- (id)textForChildNamed:(id)fp8 withAttributeNamed:(id)fp12 ofValue:(id)fp16;
- (id)valueOfAttributeNamed:(id)fp8 ofChildNamed:(id)fp12 withAttributeNamed:(id)fp16 ofValue:(id)fp20;
- (id)valueOfAttributeNamed:(id)fp8 ofChildNamed:(id)fp12 ofChildNamed:(id)fp16;
- (id)valueOfAttributeNamed:(id)fp8 ofChildNamed:(id)fp12;
- (id)URLValueOfAttributeNamed:(id)fp8;
- (id)valueOfAttributeNamed:(id)fp8;
- (BOOL)hasAttributeNamed:(id)fp8;
- (id)URLForChildNamed:(id)fp8;
- (id)URLForChildNamed:(id)fp8 ofChildNamed:(id)fp12;
- (id)textForChildNamed:(id)fp8 ofChildNamed:(id)fp12;
- (id)textForChildNamed:(id)fp8;
- (id)text;
- (id)name;
- (void)iterateChildrenNamed:(id)fp8 withBlock:(id)fp;
- (void)iterateChildrenWithBlock:(id)fp;
- (BOOL)hasChildNamed:(id)fp8;
- (id)nextSiblingNamed:(id)fp8;
- (id)nextSibling;
- (id)firstChild;
- (id)childElementNamed:(id)fp8 withAttributeNamed:(id)fp12 ofValue:(id)fp16;
- (id)childElementNamed:(id)fp8;
- (unsigned int)hash;
- (BOOL)isEqual:(id)fp8;
- (id)initWithElement:(struct _TBXMLElement *)fp8;

@end

@interface YTTBParser : NSObject // YTParser
- (id)parseElement:(id)fp8 error:(id *)fp12;
- (id)dateOrNilFromString:(id)fp8 error:(id *)fp12;
- (id)dateFromString:(id)fp8 error:(id *)fp12;
- (id)parse:(id)fp8 error:(id *)fp12;
- (void)dealloc;
- (id)init;

@end

@interface YTVideo : NSObject
// {
//     BOOL monetized_;
//     NSSet *monetizedCountries_;
//     NSSet *allowedCountries_;
//     NSSet *deniedCountries_;
//     NSString *ID_;
//     NSString *title_;
//     NSString *videoDescription_;
//     NSString *uploaderDisplayName_;
//     NSString *uploaderChannelID_;
//     NSDate *uploadedDate_;
//     NSDate *publishedDate_;
//     unsigned int duration_;
//     unsigned long long viewCount_;
//     unsigned long long likesCount_;
//     unsigned long long dislikesCount_;
//     YTVideoState *state_;
//     NSArray *streams_;
//     NSDictionary *thumbnailURLs_;
//     NSURL *subtitlesTracksURL_;
//     BOOL commentsAllowed_;
//     NSURL *commentsURL_;
//     unsigned long long commentsCountHint_;
//     NSURL *relatedURL_;
//     BOOL claimed_;
//     NSString *categoryLabel_;
//     NSString *categoryTerm_;
//     NSArray *tags_;
//     BOOL adultContent_;
//     YTVideoPro *videoPro_;
// }

- (id)videoPro;
- (BOOL)isAdultContent;
- (id)tags;
- (id)categoryTerm;
- (id)categoryLabel;
- (BOOL)isClaimed;
- (id)relatedURL;
- (unsigned long long)commentsCountHint;
- (id)commentsURL;
- (BOOL)isCommentsAllowed;
- (id)subtitlesTracksURL;
- (id)thumbnailURLs;
- (id)streams;
- (id)state;
- (unsigned long long)dislikesCount;
- (unsigned long long)likesCount;
- (unsigned long long)viewCount;
- (unsigned int)duration;
- (id)publishedDate;
- (id)uploadedDate;
- (id)uploaderChannelID;
- (id)uploaderDisplayName;
- (id)videoDescription;
- (id)title;
- (id)ID;
- (BOOL)isEncrypted;
- (BOOL)isMonetizedWithCountryCode:(id)fp8;
- (BOOL)couldBeMusic;
- (unsigned int)hash;
- (BOOL)isEqual:(id)fp8;
// - (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)init;
- (id)initWithID:(id)fp8 title:(id)fp12 description:(id)fp16 uploaderDisplayName:(id)fp20 uploaderChannelID:(id)fp24 uploadedDate:(id)fp28 publishedDate:(id)fp32 duration:(unsigned int)fp36 viewCount:(unsigned long long)fp40 likesCount:(unsigned long long)fp48 dislikesCount:(unsigned long long)fp56 state:(id)fp64 streams:(id)fp68 thumbnailURLs:(id)fp72 subtitlesTracksURL:(id)fp76 commentsAllowed:(BOOL)fp80 commentsURL:(id)fp84 commentsCountHint:(unsigned long long)fp88 relatedURL:(id)fp96 claimed:(BOOL)fp100 monetized:(BOOL)fp104 monetizedCountries:(id)fp108 allowedCountries:(id)fp112 deniedCountries:(id)fp116 categoryLabel:(id)fp120 categoryTerm:(id)fp124 tags:(id)fp128 adultContent:(BOOL)fp132 videoPro:(id)fp136;

@end

@interface YTVideoState : NSObject
- (id)reason;
- (int)code;
- (void)dealloc;
- (id)init;
- (id)initWithCode:(int)fp8 reason:(id)fp12;

@end



// @interface YTWatchViewController_iPhone : YTBaseViewController_iPhone <YTPlayerControllerDelegate, YTStackViewControllerDelegate, YTTabsViewDelegate, UIGestureRecognizerDelegate, YTWatchViewDelegate_iPhone, YTAddCommentViewDelegate>
// - (void)playVideo;
// - (void)confirmVideo;
// - (void)setBranding:(id)fp8;
// - (void)loadVideo;
// - (void)layoutViewForOrientation:(int)fp8;
// - (void)receivedRotation:(id)fp8;
// - (void)animateToInterfaceOrientation:(int)fp8;
// - (void)releasePortraitOrientation:(id)fp8;
// - (void)requestPortraitOrientation:(id)fp8;
// - (void)handlePanWithRecognizer:(id)fp8;
// - (BOOL)gestureRecognizer:(id)fp8 shouldReceiveTouch:(id)fp12;
// - (BOOL)gestureRecognizer:(id)fp8 shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)fp12;
// - (void)didCommentInputLoseFocus;
// - (void)didCommentInputGainFocus;
// - (void)didTouchStageShield;
// - (void)didChangeToTab:(id)fp8;
// - (void)willPushSubviewWithIndex:(unsigned int)fp8;
// - (void)willPopSubviewWithIndex:(unsigned int)fp8;
// - (void)showVideoPlaybackSmallscreen;
// - (void)showVideoPlaybackFullscreen;
// - (void)pushViewController:(id)fp8 animated:(BOOL)fp12;
// - (void)popViewControllerAnimated;
// - (BOOL)shouldAutorotateToInterfaceOrientation:(int)fp8;
// - (void)didRotateFromInterfaceOrientation:(int)fp8;
// - (void)willAnimateRotationToInterfaceOrientation:(int)fp8 duration:(double)fp12;
// - (void)willRotateToInterfaceOrientation:(int)fp8 duration:(double)fp12;
// - (void)viewDidDisappear:(BOOL)fp8;
// - (void)viewWillDisappear:(BOOL)fp8;
// - (void)viewDidAppear:(BOOL)fp8;
// - (void)viewWillAppear:(BOOL)fp8;
// - (void)viewDidUnload;
// - (void)loadView;
// - (void)dealloc;
// - (id)initWithVideoID:(id)fp8 source:(int)fp12 services:(id)fp16 navigation:(id)fp20;

// @end


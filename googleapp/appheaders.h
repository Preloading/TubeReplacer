#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

/// This is where we put headers that are used in more than one section/.x file

@interface YTUserAuthenticator: NSObject
- (id)authentication;
@end

@interface YTServices : NSObject
- (void)didReceiveMemoryWarning;
- (id)settings;
- (id)reachability;
- (id)resourceLoader;
- (id)userAuthenticator;
- (id)PTrackingServiceWithAdVideo:(id)fp8 video:(id)fp12 CPN:(id)fp16;
- (id)PTrackingServiceWithVideo:(id)fp8 CPN:(id)fp12;
- (id)videoStatsServiceWithSource:(int)fp8;
- (id)subtitlesService;
- (id)suggestService;
- (id)searchHistory;
- (id)musicService;
- (id)imageService;
- (id)gDataService;
- (id)adTrackingServiceForAd:(id)fp8;
- (id)adsService;
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
- (void)makeVideoRequestWithVideoID:(id)fp8 responseBlock:(id)fp errorBlock:(id)fp12;
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

@interface YTContainerViewController : NSObject
- (BOOL)viewVisible;
- (void)realignChildNavigationBars;
- (void)didRotateFromInterfaceOrientation:(int)fp8;
- (void)willAnimateRotationToInterfaceOrientation:(int)fp8 duration:(double)fp12;
- (void)willRotateToInterfaceOrientation:(int)fp8 duration:(double)fp12;
- (void)viewDidDisappear:(BOOL)fp8;
- (void)viewWillDisappear:(BOOL)fp8;
- (void)viewDidAppear:(BOOL)fp8;
- (void)viewWillAppear:(BOOL)fp8;
- (BOOL)childVisibleInView:(id)fp8;
- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers;
- (void)willRemoveChildController:(id)fp8;
- (void)didAddChildController:(id)fp8;
- (void)removeChildController:(id)fp8;
- (void)addChildController:(id)fp8;
- (id)childControllers;
- (void)viewDidUnload;
- (void)dealloc;
- (void)observeValueForKeyPath:(id)fp8 ofObject:(id)fp12 change:(id)fp16 context:(void *)fp20;
- (id)initWithNibName:(id)fp8 bundle:(id)fp12;
- (id)init;

@end

@interface YTBaseViewController_iPhone : YTContainerViewController
- (id)view;
- (id)services;
- (id)navigation;
- (void)didPressSearchButton:(id)fp8;
- (void)setNavigationBarTitle:(id)fp8;
- (void)viewWillAppear:(BOOL)fp8;
- (void)dealloc;
- (id)init;
- (id)initWithServices:(id)fp8 navigation:(id)fp12;
- (id)initWithServices:(id)fp8 navigation:(id)fp12 rightView:(id)fp16;
- (id)initWithServices:(id)fp8 navigation:(id)fp12 leftView:(id)fp16 rightView:(id)fp20;

@end



@interface YTWatchViewController_iPhone : YTBaseViewController_iPhone <UIGestureRecognizerDelegate> // <YTPlayerControllerDelegate, YTStackViewControllerDelegate, YTTabsViewDelegate, UIGestureRecognizerDelegate, YTWatchViewDelegate_iPhone, YTAddCommentViewDelegate>
- (void)playVideo;
- (void)confirmVideo;
- (void)setBranding:(id)fp8;
- (void)loadVideo;
- (void)layoutViewForOrientation:(int)fp8;
- (void)receivedRotation:(id)fp8;
- (void)animateToInterfaceOrientation:(int)fp8;
- (void)releasePortraitOrientation:(id)fp8;
- (void)requestPortraitOrientation:(id)fp8;
- (void)handlePanWithRecognizer:(id)fp8;
- (BOOL)gestureRecognizer:(id)fp8 shouldReceiveTouch:(id)fp12;
- (BOOL)gestureRecognizer:(id)fp8 shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)fp12;
- (void)didCommentInputLoseFocus;
- (void)didCommentInputGainFocus;
- (void)didTouchStageShield;
- (void)didChangeToTab:(id)fp8;
- (void)willPushSubviewWithIndex:(unsigned int)fp8;
- (void)willPopSubviewWithIndex:(unsigned int)fp8;
- (void)showVideoPlaybackSmallscreen;
- (void)showVideoPlaybackFullscreen;
- (void)pushViewController:(id)fp8 animated:(BOOL)fp12;
- (void)popViewControllerAnimated;
- (BOOL)shouldAutorotateToInterfaceOrientation:(int)fp8;
- (void)didRotateFromInterfaceOrientation:(int)fp8;
- (void)willAnimateRotationToInterfaceOrientation:(int)fp8 duration:(double)fp12;
- (void)willRotateToInterfaceOrientation:(int)fp8 duration:(double)fp12;
- (void)viewDidDisappear:(BOOL)fp8;
- (void)viewWillDisappear:(BOOL)fp8;
- (void)viewDidAppear:(BOOL)fp8;
- (void)viewWillAppear:(BOOL)fp8;
- (void)viewDidUnload;
- (void)loadView;
- (void)dealloc;
- (id)initWithVideoID:(id)fp8 source:(int)fp12 services:(id)fp16 navigation:(id)fp20;

// missing in classdump
-(void)setView:(id)fp8;
@end

@interface YTStackViewController : YTContainerViewController
- (id)scrollViewContainingTouch:(id)fp8;
- (void)popView:(id)fp8 animated:(BOOL)fp12 completion:(id)fp;
- (void)pushView:(id)fp8 isRootView:(BOOL)fp12 animated:(BOOL)fp16 completion:(id)fp;
- (id)topView;
- (void)handlePanFrom:(id)fp8;
- (BOOL)gestureRecognizer:(id)fp8 shouldReceiveTouch:(id)fp12;
- (BOOL)gestureRecognizer:(id)fp8 shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)fp12;
- (void)setDelegate:(id)fp8;
- (void)pushViewController:(id)fp8 animated:(BOOL)fp12;
- (void)popViewControllerAnimated:(BOOL)fp8;
- (void)viewDidUnload;
- (void)loadView;
- (void)dealloc;
- (id)init;
- (id)initWithMaximumDepth:(unsigned int)fp8;

// doesnt appear in the classdump, this is kinda getting annoying
- (id)view;

@end

@interface GIPResourceLoader : NSObject
+ (id)imageNamed:(id)fp8 inBundle:(id)fp12;
+ (id)imageNamed:(id)fp8 fromLoader:(id)fp12 shouldCache:(BOOL)fp16;
+ (id)imageNamed:(id)fp8 fromLoader:(id)fp12;
+ (id)sharedLoaderForBundleNamed:(id)fp8;
+ (void)setSharedLoader:(id)fp8 forBundleNamed:(id)fp12;
+ (void)initialize;
- (void)setBundleName:(id)fp8;
- (id)bundleName;
- (void)flush;
- (void)put:(id)fp8 forKey:(id)fp12;
- (id)contentsOfFileNamed:(id)fp8 ofType:(id)fp12 inDirectory:(id)fp16 fromBundle:(id)fp20;
- (id)imageNamed:(id)fp8 cache:(BOOL)fp12;
- (id)imageNamed:(id)fp8;
- (void)dealloc;
- (id)initWithCacheSize:(int)fp8 bundleName:(id)fp12;
- (id)initWithCacheSize:(int)fp8;
- (id)initWithBundleName:(id)fp8;
- (id)init;

@end

@interface YTTabsView : NSObject
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)updateScrollsToTop;
- (unsigned int)currentVisibleTabIndex;
- (void)updateTabIndex:(unsigned int)fp8;
- (void)scrollViewDidScroll:(id)fp8;
- (void)didTouchTitleAtIndex:(int)fp8;
- (void)setScrollsToTop:(BOOL)fp8;
- (id)currentTabView;
- (id)tabTitlesView;
- (void)addTabView:(id)fp8 withTitle:(id)fp12;
- (void)insertTabView:(id)fp8 withTitle:(id)fp12 atIndex:(int)fp16;
- (void)layoutSubviews;
- (void)setFrame:(struct CGRect)fp8;
- (void)dealloc;
- (id)initWithResourceLoader:(id)fp8;

@end

@interface YTAddCommentView : NSObject
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (id)inputField;
- (void)setUserThumbnail:(id)fp8;
- (void)setShowLoading:(BOOL)fp8;
- (BOOL)hasFocus;
- (BOOL)resignFirstResponder;
- (struct CGSize)sizeThatFits:(struct CGSize)fp8;
- (void)layoutSubviews;
- (id)initWithFrame:(struct CGRect)fp8;
- (id)initWithResourceLoader:(id)fp8;

@end

@interface GTMLogger : NSObject
+ (id)logger;
+ (id)loggerWithWriter:(id)fp8 formatter:(id)fp12 filter:(id)fp16;
+ (id)standardLoggerWithPath:(id)fp8;
+ (id)standardLoggerWithStdoutAndStderr;
+ (id)standardLoggerWithStderr;
+ (id)standardLogger;
+ (void)setSharedLogger:(id)fp8;
+ (id)sharedLogger;
- (void)logAssert:(id)fp8;
- (void)logError:(id)fp8;
- (void)logInfo:(id)fp8;
- (void)logDebug:(id)fp8;
- (void)setFilter:(id)fp8;
- (id)filter;
- (void)setFormatter:(id)fp8;
- (id)formatter;
- (void)setWriter:(id)fp8;
- (id)writer;
- (void)dealloc;
- (id)initWithWriter:(id)fp8 formatter:(id)fp12 filter:(id)fp16;
- (id)init;
- (void)logFuncError:(NSString*)func msg:(NSString*)msg;

@end

@interface YTNavigation : NSObject // actually a protocol but who's counting
- (BOOL)isLastSender:(id)fp8;
- (void)setNavigationBarHidden:(BOOL)fp8;
- (void)toastWithError:(id)fp8 message:(id)fp12;
- (void)toastWithMessage:(id)fp8;
- (void)hideGuide;
- (void)showGuide;
- (void)back;
- (void)showSettingsFromView:(id)fp8;
- (void)showSignInFromRect:(struct CGRect)fp8 inView:(id)fp24 auth:(id)fp28 authedBlock:(id)fp2 failedBlock:(void)fp32 canceledBlock:(id)fp64;
- (void)showChannelStoreFromView:(id)fp8;
- (void)showAccountFromView:(id)fp8;
- (void)showArtistWithArtistID:(id)fp8 fromView:(id)fp12;
- (void)showArtistWithArtistBundle:(id)fp8 fromView:(id)fp12;
- (void)showRiverFromView:(id)fp8;
- (void)showCategory:(id)fp8 fromView:(id)fp12;
- (void)showChannel:(id)fp8 fromView:(id)fp12;
- (void)showChannelWithID:(id)fp8 fromView:(id)fp12;
- (void)showPlaylist:(id)fp8 source:(int)fp12 fromView:(id)fp16;
- (void)showMyWatchLaterFromView:(id)fp8;
- (void)showMyWatchHistoryFromView:(id)fp8;
- (void)showMyUploadsFromView:(id)fp8;
- (void)showMyPurchasesFromView:(id)fp8;
- (void)showMyPlaylistsFromView:(id)fp8;
- (void)showMyFavoritesFromView:(id)fp8;
- (void)showWatchWithVideoID:(id)fp8 source:(int)fp12 fromView:(id)fp16;
- (void)showWatchWithVideo:(id)fp8 source:(int)fp12 fromView:(id)fp16;
- (void)showAddPlaylistFromView:(id)fp8 target:(id)fp12 action:(SEL)fp16;
- (void)showSearchFilters:(id)fp8 target:(id)fp12 action:(SEL)fp16;
- (void)showSearchResultsForQuery:(id)fp8 fromView:(id)fp12;
- (void)showSearchForQuery:(id)fp8 fromView:(id)fp12;
- (void)showHome;
- (void)shutdown;
- (void)loadWithWindow:(id)fp8;
@end

@interface NSError (YouTubeAdditions)
- (NSString *)logDescription;
@end

@interface YTStream : NSObject
{
    NSURL *URL_;
    int format_;
    BOOL encrypted_;
}

+ (int)selectAdSenseiTagOnWiFi:(BOOL)fp8;
+ (id)selectStreamForVideo:(id)fp8 onWiFi:(BOOL)fp12;
+ (id)streamWithURL:(id)fp8 format:(int)fp12 encrypted:(BOOL)fp16;
- (BOOL)encrypted;
- (int)format;
- (id)URL;
- (id)description;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithURL:(id)fp8 format:(int)fp12 encrypted:(BOOL)fp16;

@end

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
- (void)setRefreshExtraRequest:(id)fp8;
- (id)refreshExtraRequest;
- (void)setRefreshRequest:(id)fp8;
- (id)refreshRequest;
- (void)setExtraRequest:(id)fp8;
- (id)extraRequest;
- (void)setNextRequest:(id)fp8;
- (id)nextRequest;
- (void)onError:(id)fp8;
- (void)onResponse:(id)fp8;
- (void)maybeMakeNextRequest;
- (void)feedViewDidAskForRefresh:(id)fp8;
- (void)feedViewDidAskForMore:(id)fp8;
- (void)feedView:(id)fp8 didSelectEntryAtIndex:(int)fp12;
- (void)updateCell:(id)fp8 atIndex:(int)fp12;
- (id)entryAtIndex:(int)fp8;
- (int)entryCount;
- (void)clear;
- (void)refresh;
- (void)updateCell:(id)fp8 forEntry:(id)fp12 animated:(BOOL)fp16;
- (void)handleEntries:(id)fp8;
- (void)makeThumbnailRequestWithURL:(id)fp8 forEntry:(id)fp12;
- (void)removeEntriesMatchingBlock:(id)fp;
- (void)insertEntry:(id)fp8 atIndex:(unsigned int)fp12;
- (void)addEntry:(id)fp8;
- (void)insertEntriesFromArray:(id)fp8 atIndex:(unsigned int)fp12;
- (void)addEntriesFromArray:(id)fp8;
- (void)updateCellForEntry:(id)fp8 animated:(BOOL)fp12;
- (id)cellForEntry:(id)fp8;
- (id)thumbnailForEntry:(id)fp8;
- (void)setSelectedThumbnail:(id)fp8 forEntry:(id)fp12;
- (void)setThumbnail:(id)fp8 forEntry:(id)fp12;
- (void)setDidSelectEntryTarget:(id)fp8 action:(SEL)fp12;
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12 extraRequest:(id)fp16 extraServiceSelector:(SEL)fp20;
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12;
- (void)setAllowDuplicates:(BOOL)fp8;
- (BOOL)allowDuplicates;
- (void)reset;
- (void)dealloc;
- (id)init;
- (id)initWithFeedView:(id)fp8 services:(id)fp12;

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

+ (void)setSafeSearchFilter:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setCCFilter:(BOOL)fp8 toURLBuilder:(id)fp12;
+ (void)setDurationFilter:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setUploadDateFilter:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setSortByFilter:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setFormatsToURLBuilder:(id)fp8;
+ (void)setPageSize:(int)fp8 toURLBuilder:(id)fp12;
+ (void)setDefaultPageSizeToURLBuilder:(id)fp8;
+ (void)setQueryParametersToURLBuilder:(id)fp8 withSafeSearch:(int)fp12;
+ (void)setDirectAccessParametersToURLBuilder:(id)fp8;
+ (BOOL)regionHasLocalizedStandardFeeds:(id)fp8;
+ (id)requestWithURLString:(id)fp8 authentication:(id)fp12 body:(id)fp16;
+ (id)requestWithURLString:(id)fp8 authentication:(id)fp12;
+ (id)requestWithURLString:(id)fp8;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12 body:(id)fp16 noCache:(BOOL)fp20;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12 body:(id)fp16;
+ (id)requestWithURL:(id)fp8 authentication:(id)fp12;
+ (id)requestToAddCommentWithVideoID:(id)fp8 authentication:(id)fp12 content:(id)fp16;
+ (id)requestToFlagWithVideoID:(id)fp8 authentication:(id)fp12;
+ (id)requestForMyPurchases:(id)fp8;
+ (id)requestForBrandingWithChannelID:(id)fp8;
+ (id)requestForMyChannelRecommendationsWithAuth:(id)fp8;
+ (id)requestToAddToFavoritesWithVideoID:(id)fp8 authentication:(id)fp12;
+ (id)requestToRateWithVideoID:(id)fp8 authentication:(id)fp12 like:(BOOL)fp16;
+ (id)requestForEventsWithChannelID:(id)fp8;
+ (id)requestToUnsubscribeWithSubscription:(id)fp8 authentication:(id)fp12;
+ (id)requestToSubscribeWithChannelID:(id)fp8 authentication:(id)fp12;
+ (id)requestToAddToWatchLaterWithVideoID:(id)fp8 authentication:(id)fp12;
+ (id)requestForMyWatchLaterVideosWithAuth:(id)fp8;
+ (id)requestToClearWatchHistoryWithAuth:(id)fp8;
+ (id)requestToAddToWatchHistoryWithVideoID:(id)fp8 authentication:(id)fp12;
+ (id)requestForMyWatchHistoryVideosWithAuth:(id)fp8;
+ (id)requestForMySubscriptionWithChannelID:(id)fp8 auth:(id)fp12;
+ (id)requestForMySubscriptionsWithAuth:(id)fp8;
+ (id)requestToAddToPlaylistWithVideoID:(id)fp8 contentURL:(id)fp12 auth:(id)fp16;
+ (id)requestToAddPlaylistWithTitle:(id)fp8 description:(id)fp12 isPrivate:(BOOL)fp16 auth:(id)fp20;
+ (id)requestForMyPlaylistsWithAuth:(id)fp8;
+ (id)requestForPlaylistsWithChannelID:(id)fp8;
+ (id)requestForPlaylistWithURL:(id)fp8;
+ (id)requestForMyUserProfileWithAuth:(id)fp8;
+ (id)requestForChannelWithID:(id)fp8;
+ (id)requestForMyPlaylistVideosWithURL:(id)fp8 authentication:(id)fp12;
+ (id)requestForPlaylistVideosWithPlaylistID:(id)fp8;
+ (id)requestForPlaylistVideosWithURL:(id)fp8;
+ (id)requestForMySubscriptionUploadsWithAuth:(id)fp8 safeSearch:(int)fp12;
+ (id)requestForMySubscriptionUpdatesWithAuth:(id)fp8;
+ (id)requestForMyUploadedVideosWithAuth:(id)fp8;
+ (id)requestForUploadedVideosWithChannelID:(id)fp8;
+ (id)requestForMyFavoriteVideosWithAuth:(id)fp8;
+ (id)requestForFavoriteVideosWithURL:(id)fp8;
+ (id)requestForVideosWithStandardFeed:(int)fp8 categoryTerm:(id)fp12 uploadDate:(int)fp16 safeSearch:(int)fp20;
+ (id)requestForRelatedVideosWithURL:(id)fp8 safeSearch:(int)fp12;
+ (id)requestForChannelsWithStandardFeed:(int)fp8;
+ (id)requestForChannelsWithSearchQuery:(id)fp8;
+ (id)requestForVideosWithSearchQuery:(id)fp8 languageCode:(id)fp12 filters:(id)fp16 safeSearch:(int)fp20;
+ (id)requestForVideoWithVideoID:(id)fp8;
+ (id)requestForCategoriesWithLanguageCode:(id)fp8;
+ (id)requestWithRequest:(id)fp8 noCache:(BOOL)fp12;
+ (id)requestWithRequest:(id)fp8 URL:(id)fp12;
+ (id)requestWithURL:(id)fp8;
- (BOOL)noCache;
- (id)body;
- (id)authentication;
- (id)URL;
- (id)initWithURL:(id)fp8;
- (BOOL)isPathIdenticalToRequest:(id)fp8;
- (unsigned int)hash;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (BOOL)isEqual:(id)fp8;
- (void)dealloc;
- (id)initWithURL:(id)fp8 authentication:(id)fp12 body:(id)fp16 noCache:(BOOL)fp20;
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

@interface YTChannel : NSObject
// {
//     NSString *summary_;
//     NSString *displayName_;
//     NSString *channelID_;
//     NSDate *updated_;
//     unsigned long long videoCount_;
//     NSURL *thumbnailURL_;
//     unsigned long long subscribersCount_;
// }

- (unsigned long long)subscribersCount;
- (id)thumbnailURL;
- (unsigned long long)videoCount;
- (id)updated;
- (id)channelID;
- (id)displayName;
- (id)summary;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithDisplayName:(id)fp8 channelID:(id)fp12 summary:(id)fp16 updated:(id)fp20 videoCount:(unsigned long long)fp24 thumbnailURL:(id)fp32 subscribersCount:(unsigned long long)fp36;

@end

@interface GIPToast : NSObject
{
    UILabel *message_;
    UIActivityIndicatorView *spinner_;
}

+ (void)showTodo;
+ (void)hide;
+ (void)showToastWithSpinner:(id)fp8;
+ (void)showToast:(id)fp8 forDuration:(double)fp12;
+ (id)toast;
- (void)showMessage:(id)fp8 forDuration:(double)fp12 showIndicator:(BOOL)fp20;
- (void)createView;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)fp8;

@end

@interface GTMOAuth2Authentication : NSObject
+ (id)scopeWithStrings:(id)fp8;
+ (id)dictionaryWithResponseData:(id)fp8;
+ (id)dictionaryWithResponseString:(id)fp8;
+ (id)unencodedOAuthParameterForString:(id)fp8;
+ (void)invokeDelegate:(id)fp8 selector:(SEL)fp12 object:(id)fp16 object:(id)fp20 object:(id)fp24;
+ (id)encodedQueryParametersForDictionary:(id)fp8;
+ (id)encodedOAuthValueForString:(id)fp8;
+ (id)authenticationWithServiceProvider:(id)fp8 tokenURL:(id)fp12 redirectURI:(id)fp16 clientID:(id)fp20 clientSecret:(id)fp24;
- (void)setAuthorizationQueue:(id)fp8;
- (id)authorizationQueue;
- (void)setProperties:(id)fp8;
- (id)properties;
- (void)setUserData:(id)fp8;
- (id)userData;
- (void)setShouldAuthorizeAllRequests:(BOOL)fp8;
- (BOOL)shouldAuthorizeAllRequests;
- (void)setParserClass:(Class)fp8;
- (Class)parserClass;
- (void)setFetcherService:(id)fp8;
- (id)fetcherService;
- (void)setRefreshFetcher:(id)fp8;
- (id)refreshFetcher;
- (void)setAdditionalTokenRequestParameters:(id)fp8;
- (id)additionalTokenRequestParameters;
- (void)setExpirationDate:(id)fp8;
- (id)expirationDate;
- (void)setTokenURL:(id)fp8;
- (id)tokenURL;
- (void)setParameters:(id)fp8;
- (id)parameters;
- (void)setRedirectURI:(id)fp8;
- (id)redirectURI;
- (void)setClientSecret:(id)fp8;
- (id)clientSecret;
- (void)setClientID:(id)fp8;
- (id)clientID;
- (id)propertyForKey:(id)fp8;
- (void)setProperty:(id)fp8 forKey:(id)fp12;
- (void)setUserEmailIsVerified:(id)fp8;
- (id)userEmailIsVerified;
- (void)setUserEmail:(id)fp8;
- (id)userEmail;
- (void)setServiceProvider:(id)fp8;
- (id)serviceProvider;
- (void)updateExpirationDate;
- (void)setExpiresIn:(id)fp8;
- (id)expiresIn;
- (void)setScope:(id)fp8;
- (id)scope;
- (void)setTokenType:(id)fp8;
- (id)tokenType;
- (void)setErrorString:(id)fp8;
- (id)errorString;
- (void)setAssertion:(id)fp8;
- (id)assertion;
- (void)setCode:(id)fp8;
- (id)code;
- (void)setRefreshToken:(id)fp8;
- (id)refreshToken;
- (void)setAccessToken:(id)fp8;
- (id)accessToken;
- (void)reset;
- (BOOL)primeForRefresh;
- (id)persistenceResponseString;
- (void)setKeysForPersistenceResponseString:(id)fp8;
- (void)notifyFetchIsRunning:(BOOL)fp8 fetcher:(id)fp12 type:(id)fp16;
- (void)tokenFetcher:(id)fp8 finishedWithData:(id)fp12 error:(id)fp16;
- (id)beginTokenFetchWithDelegate:(id)fp8 didFinishSelector:(SEL)fp12;
- (id)userAgent;
- (void)waitForCompletionWithTimeout:(double)fp8;
- (BOOL)shouldRefreshAccessToken;
- (BOOL)canAuthorize;
- (BOOL)authorizeRequest:(id)fp8;
- (void)invokeCallbackArgs:(id)fp8;
- (BOOL)authorizeRequestImmediateArgs:(id)fp8;
- (void)stopAuthorization;
- (BOOL)isAuthorizedRequest:(id)fp8;
- (BOOL)isAuthorizingRequest:(id)fp8;
- (void)auth:(id)fp8 finishedRefreshWithFetcher:(id)fp12 error:(id)fp16;
- (BOOL)authorizeRequestArgs:(id)fp8;
- (void)authorizeRequest:(id)fp8 delegate:(id)fp12 didFinishSelector:(SEL)fp16;
- (void)authorizeRequest:(id)fp8 completionHandler:(id)fp;
- (id)dictionaryWithJSONData:(id)fp8;
- (void)setKeysForResponseJSONData:(id)fp8;
- (void)setKeysForResponseString:(id)fp8;
- (void)setKeysForResponseDictionary:(id)fp8;
- (void)dealloc;
- (id)description;
- (id)init;

@end

@interface GTMOAuth2ViewControllerTouch : NSObject
+ (void)revokeTokenForGoogleAuthentication:(id)fp8;
+ (void)setSignInClass:(Class)fp8;
+ (Class)signInClass;
+ (BOOL)saveParamsToKeychainForName:(id)fp8 accessibility:(void *)fp12 authentication:(id)fp16;
+ (BOOL)saveParamsToKeychainForName:(id)fp8 authentication:(id)fp12;
+ (BOOL)removeAuthFromKeychainForName:(id)fp8;
+ (BOOL)authorizeFromKeychainForName:(id)fp8 authentication:(id)fp12;
+ (id)authForGoogleFromKeychainForName:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16;
+ (id)authNibBundle;
+ (id)authNibName;
+ (id)controllerWithAuthentication:(id)fp8 authorizationURL:(id)fp12 keychainItemName:(id)fp16 completionHandler:(id)fp;
+ (id)controllerWithAuthentication:(id)fp8 authorizationURL:(id)fp12 keychainItemName:(id)fp16 delegate:(id)fp20 finishedSelector:(SEL)fp24;
+ (id)controllerWithScope:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16 keychainItemName:(id)fp20 completionHandler:(id)fp;
+ (id)controllerWithScope:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16 keychainItemName:(id)fp20 delegate:(id)fp24 finishedSelector:(SEL)fp28;
- (void)setPopViewBlock:(id)fp;
- (id)popViewBlock;
- (void)setProperties:(id)fp8;
- (id)properties;
- (void)setUserData:(id)fp8;
- (id)userData;
- (id)signIn;
- (void)setBrowserCookiesURL:(id)fp8;
- (id)browserCookiesURL;
- (void)setInitialHTMLString:(id)fp8;
- (id)initialHTMLString;
- (void)setKeychainItemAccessibility:(void *)fp8;
- (void *)keychainItemAccessibility;
- (void)setKeychainItemName:(id)fp8;
- (id)keychainItemName;
- (void)setWebView:(id)fp8;
- (id)webView;
- (void)setRightBarButtonItem:(id)fp8;
- (id)rightBarButtonItem;
- (void)setNavButtonsView:(id)fp8;
- (id)navButtonsView;
- (void)setForwardButton:(id)fp8;
- (id)forwardButton;
- (void)setBackButton:(id)fp8;
- (id)backButton;
- (void)setRequest:(id)fp8;
- (id)request;
- (BOOL)shouldAutorotateToInterfaceOrientation:(int)fp8;
- (void)webView:(id)fp8 didFailLoadWithError:(id)fp12;
- (void)webViewDidFinishLoad:(id)fp8;
- (void)webViewDidStartLoad:(id)fp8;
- (void)updateUI;
- (BOOL)webView:(id)fp8 shouldStartLoadWithRequest:(id)fp12 navigationType:(int)fp16;
- (void)viewWillDisappear:(BOOL)fp8;
- (void)viewDidAppear:(BOOL)fp8;
- (void)viewWillAppear:(BOOL)fp8;
- (BOOL)isNavigationBarTranslucent;
- (void)moveWebViewFromUnderNavigationBar;
- (void)signIn:(id)fp8 finishedWithAuth:(id)fp12 error:(id)fp16;
- (void)signIn:(id)fp8 displayRequest:(id)fp12;
- (id)propertyForKey:(id)fp8;
- (void)setProperty:(id)fp8 forKey:(id)fp12;
- (BOOL)shouldUseKeychain;
- (double)networkLossTimeoutInterval;
- (void)setNetworkLossTimeoutInterval:(double)fp8;
- (void)clearBrowserCookies;
- (id)authentication;
- (void)cancelSigningIn;
- (void)notifyWithName:(id)fp8 webView:(id)fp12 kind:(id)fp16;
- (void)popView;
- (void)viewDidLoad;
- (void)loadView;
- (void)dealloc;
- (id)initWithAuthentication:(id)fp8 authorizationURL:(id)fp12 keychainItemName:(id)fp16 completionHandler:(id)fp;
- (id)initWithAuthentication:(id)fp8 authorizationURL:(id)fp12 keychainItemName:(id)fp16 delegate:(id)fp20 finishedSelector:(SEL)fp24;
- (id)initWithScope:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16 keychainItemName:(id)fp20 completionHandler:(id)fp;
- (id)initWithScope:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16 keychainItemName:(id)fp20 delegate:(id)fp24 finishedSelector:(SEL)fp28;

@end

@interface GTMOAuth2SignIn : NSObject
+ (void)revokeTokenForGoogleAuthentication:(id)fp8;
+ (id)userInfoFetcherWithAuth:(id)fp8;
+ (id)mutableURLRequestWithURL:(id)fp8 paramString:(id)fp12;
+ (id)standardGoogleAuthenticationForScope:(id)fp8 clientID:(id)fp12 clientSecret:(id)fp16;
+ (id)nativeClientRedirectURI;
+ (id)googleUserInfoURL;
+ (id)googleRevocationURL;
+ (id)googleTokenURL;
+ (id)googleAuthorizationURL;
- (void)setNetworkLossTimeoutInterval:(double)fp8;
- (double)networkLossTimeoutInterval;
- (void)setUserProfile:(id)fp8;
- (id)userProfile;
- (void)setShouldFetchGoogleUserProfile:(BOOL)fp8;
- (BOOL)shouldFetchGoogleUserProfile;
- (void)setShouldFetchGoogleUserEmail:(BOOL)fp8;
- (BOOL)shouldFetchGoogleUserEmail;
- (void)setUserData:(id)fp8;
- (id)userData;
- (void)setPendingFetcher:(id)fp8;
- (id)pendingFetcher;
- (void)setHasHandledCallback:(BOOL)fp8;
- (BOOL)hasHandledCallback;
- (void)setFinishedSelector:(SEL)fp8;
- (SEL)finishedSelector;
- (void)setWebRequestSelector:(SEL)fp8;
- (SEL)webRequestSelector;
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)setAdditionalAuthorizationParameters:(id)fp8;
- (id)additionalAuthorizationParameters;
- (void)setAuthorizationURL:(id)fp8;
- (id)authorizationURL;
- (void)setAuthentication:(id)fp8;
- (id)authentication;
- (void)stopReachabilityCheck;
- (void)reachabilityTimerFired:(id)fp8;
// - (void)reachabilityTarget:(struct __SCNetworkReachability *)fp8 changedFlags:(unsigned int)fp12;
- (void)destroyUnreachabilityTimer;
- (void)startReachabilityCheck;
- (void)invokeFinalCallbackWithError:(id)fp8;
- (void)finishSignInWithError:(id)fp8;
- (void)infoFetcher:(id)fp8 finishedWithData:(id)fp12 error:(id)fp16;
- (void)fetchGoogleUserInfo;
- (void)auth:(id)fp8 finishedWithFetcher:(id)fp12 error:(id)fp16;
- (void)handleCallbackReached;
- (BOOL)loadFailedWithError:(id)fp8;
- (BOOL)cookiesChanged:(id)fp8;
- (BOOL)titleChanged:(id)fp8;
- (BOOL)requestRedirectedToRequest:(id)fp8;
- (void)closeTheWindow;
- (void)windowWasClosed;
- (BOOL)startWebRequest;
- (id)parametersForWebRequest;
- (BOOL)startSigningIn;
- (void)cancelSigningIn;
- (void)dealloc;
- (id)initWithAuthentication:(id)fp8 authorizationURL:(id)fp12 delegate:(id)fp16 webRequestSelector:(SEL)fp20 finishedSelector:(SEL)fp24;

@end

@interface GTMCookieStorage : NSObject
- (void)removeAllCookies;
- (void)removeExpiredCookies;
- (id)cookieMatchingCookie:(id)fp8;
- (id)cookiesForURL:(id)fp8;
- (void)deleteCookie:(id)fp8;
- (void)setCookies:(id)fp8;
- (void)dealloc;
- (id)init;

@end

@protocol GTMHTTPFetcherServiceProtocol <NSObject>
- (BOOL)isDelayingFetcher:(id)fp8;
- (id)fetcherWithRequest:(id)fp8;
- (void)fetcherDidStop:(id)fp8;
- (BOOL)fetcherShouldBeginFetching:(id)fp8;
@end

@interface GTMHTTPFetcher : NSObject
+ (void)setConnectionClass:(Class)fp8;
+ (Class)connectionClass;
+ (BOOL)doesSupportSentDataCallback;
+ (id)staticCookieStorage;
+ (void)initialize;
+ (id)fetcherWithURLString:(id)fp8;
+ (id)fetcherWithURL:(id)fp8;
+ (id)fetcherWithRequest:(id)fp8;
- (void)setShouldFetchInBackground:(BOOL)fp8;
- (BOOL)shouldFetchInBackground;
- (void)setRetryBlock:(id)fp;
- (id)retryBlock;
- (void)setReceivedDataBlock:(id)fp;
- (id)receivedDataBlock;
- (void)setSentDataBlock:(id)fp;
- (id)sentDataBlock;
- (void)setCompletionBlock:(id)fp;
- (id)completionBlock;
- (void)setCookieStorage:(id)fp8;
- (id)cookieStorage;
- (void)setLog:(id)fp8;
- (id)log;
- (void)setComment:(id)fp8;
- (id)comment;
- (void)setRunLoopModes:(id)fp8;
- (id)runLoopModes;
- (void)setDownloadFileHandle:(id)fp8;
- (id)downloadFileHandle;
- (void)setTemporaryDownloadPath:(id)fp8;
- (id)temporaryDownloadPath;
- (void)setDownloadPath:(id)fp8;
- (id)downloadPath;
- (void)setDownloadedData:(id)fp8;
- (id)downloadedData;
- (unsigned long long)downloadedLength;
- (void)setResponse:(id)fp8;
- (id)response;
- (void)setRetryFactor:(double)fp8;
- (double)retryFactor;
- (void)setRetrySelector:(SEL)fp8;
- (SEL)retrySelector;
- (void)setReceivedDataSelector:(SEL)fp8;
- (SEL)receivedDataSelector;
- (void)setSentDataSelector:(SEL)fp8;
- (SEL)sentDataSelector;
- (void)setThread:(id)fp8;
- (id)thread;
- (void)setServicePriority:(int)fp8;
- (int)servicePriority;
- (void)setServiceHost:(id)fp8;
- (id)serviceHost;
- (void)setService:(id)fp8;
- (id)service;
- (void)setAuthorizer:(id)fp8;
- (id)authorizer;
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)setPostStream:(id)fp8;
- (id)postStream;
- (void)setPostData:(id)fp8;
- (id)postData;
- (void)setProxyCredential:(id)fp8;
- (id)proxyCredential;
- (void)setCredential:(id)fp8;
- (id)credential;
- (void)setMutableRequest:(id)fp8;
- (id)mutableRequest;
- (void)setCommentWithFormat:(id)fp8;
- (void)addPropertiesFromDictionary:(id)fp8;
- (id)propertyForKey:(id)fp8;
- (void)setProperty:(id)fp8 forKey:(id)fp12;
- (id)properties;
- (void)setProperties:(id)fp8;
- (void)setUserData:(id)fp8;
- (id)userData;
- (void)setFetchHistory:(id)fp8;
- (id)fetchHistory;
- (void)setCookieStorageMethod:(int)fp8;
- (int)cookieStorageMethod;
- (void)setMinRetryInterval:(double)fp8;
- (double)minRetryInterval;
- (void)setMaxRetryInterval:(double)fp8;
- (double)maxRetryInterval;
- (void)setRetryEnabled:(BOOL)fp8;
- (BOOL)isRetryEnabled;
- (double)nextRetryInterval;
- (unsigned int)retryCount;
- (void)destroyRetryTimer;
- (void)retryTimerFired:(id)fp8;
- (void)primeRetryTimerWithNewTimeInterval:(double)fp8;
- (void)beginRetryTimer;
- (BOOL)shouldRetryNowForStatus:(int)fp8 error:(id)fp12;
- (BOOL)isRetryError:(id)fp8;
- (void)logNowWithError:(id)fp8;
- (void)connection:(id)fp8 didFailWithError:(id)fp12;
- (BOOL)shouldReleaseCallbacksUponCompletion;
- (void)connectionDidFinishLoading:(id)fp8;
- (int)statusAfterHandlingNotModifiedError;
- (void)connection:(id)fp8 didReceiveData:(id)fp12;
- (void)connection:(id)fp8 didSendBodyData:(int)fp12 totalBytesWritten:(int)fp16 totalBytesExpectedToWrite:(int)fp20;
- (BOOL)invokeRetryCallback:(SEL)fp8 target:(id)fp12 willRetry:(BOOL)fp16 error:(id)fp20;
- (void)invokeSentDataCallback:(SEL)fp8 target:(id)fp12 didSendBodyData:(int)fp16 totalBytesWritten:(int)fp20 totalBytesExpectedToWrite:(int)fp24;
- (void)invokeFetchCallback:(SEL)fp8 target:(id)fp12 data:(id)fp16 error:(id)fp20;
- (void)invokeFetchCallbacksWithData:(id)fp8 error:(id)fp12;
- (void)connection:(id)fp8 didReceiveAuthenticationChallenge:(id)fp12;
- (void)handleCookiesForResponse:(id)fp8;
- (void)connection:(id)fp8 didReceiveResponse:(id)fp12;
- (id)connection:(id)fp8 willSendRequest:(id)fp12 redirectResponse:(id)fp16;
- (id)fileManager;
- (void)waitForCompletionWithTimeout:(double)fp8;
- (void)retryFetch;
- (void)sendStopNotificationIfNeeded;
- (void)stopFetching;
- (void)stopFetchReleasingCallbacks:(BOOL)fp8;
- (void)releaseCallbacks;
- (id)responseHeaders;
- (int)statusCode;
- (BOOL)isFetching;
- (void)addCookiesToRequest:(id)fp8;
- (id)createTempDownloadFilePathForPath:(id)fp8;
- (BOOL)beginFetchWithCompletionHandler:(id)fp;
- (void)authorizer:(id)fp8 request:(id)fp12 finishedWithError:(id)fp16;
- (BOOL)authorizeRequest;
- (void)endBackgroundTask;
- (void)backgroundFetchExpired;
- (void)failToBeginFetchWithError:(id)fp8;
- (BOOL)beginFetchMayDelay:(BOOL)fp8 mayAuthorize:(BOOL)fp12;
- (BOOL)beginFetchWithDelegate:(id)fp8 didFinishSelector:(SEL)fp12;
- (void)dealloc;
- (id)description;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)initWithRequest:(id)fp8;
- (id)init;

@end

@interface YTUserProfile : NSObject
- (unsigned long long)subscribersCount;
- (unsigned long long)channelViewsCount;
- (unsigned long long)uploadViewsCount;
- (unsigned long long)subscriptionsCount;
- (unsigned long long)favoritesCount;
- (unsigned long long)uploadedCount;
- (id)thumbnailURL;
- (unsigned int)age;
- (id)playlistsURL;
- (id)uploadsURL;
- (id)displayName;
- (id)username;
- (BOOL)hasLegalAge;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithUsername:(id)fp8 displayName:(id)fp12 age:(unsigned int)fp16 thumbnailURL:(id)fp20 uploadsURL:(id)fp24 playlistsURL:(id)fp28 uploadedCount:(unsigned long long)fp32 favoritesCount:(unsigned long long)fp40 subscriptionsCount:(unsigned long long)fp48 uploadViewsCount:(unsigned long long)fp56 channelViewsCount:(unsigned long long)fp64 subscribersCount:(unsigned long long)fp72;

@end


@interface YTSubscription : NSObject
- (id)updatedDate;
- (id)publishedDate;
- (unsigned long long)countHint;
- (id)thumbnailURL;
- (id)editURL;
- (int)type;
- (id)channelID;
- (id)displayName;
- (id)username;
- (BOOL)isSupported;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithUsername:(id)fp8 displayName:(id)fp12 channelID:(id)fp16 type:(int)fp20 publishedDate:(id)fp24 updatedDate:(id)fp28 countHint:(unsigned long long)fp32 editURL:(id)fp40 thumbnailURL:(id)fp44;

@end

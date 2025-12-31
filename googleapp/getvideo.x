#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"


%hook YTGDataRequest
+(YTGDataRequest*)requestForVideoWithVideoID:(NSString*)videoId {
    // NSString *baseUrl = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"videos/%@", videoId];
    // GTMURLBuilder *urlBuilder = [GTMURLBuilder builderWithString:baseUrl];
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/player?noauth=1"];
    NSURL *fullURL = [urlBuilder URL];
    return [self requestWithURL:fullURL authentication:nil body:[YoutubeRequestClient getVideoWithID:videoId]];//[YoutubeRequestClient browseBody:browseId params:params]];
}
%end

%hook YTGDataService

-(void)makeVideoRequestWithVideoID:(NSString*)videoId responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  %log;
  id videoCache = [self valueForKey:@"videoCache_"]; // I don't think we want to use the video cache for the most part due to missing information we may need for things to look right (video stream, etc), but we will see!
  id cachedVideo = [videoCache objectForKey:videoId];
  
  if (cachedVideo)
  {
    [self performResponseBlock:responseBlock response:cachedVideo];
  }
  else
  {
    YTGDataRequest *request = [%c(YTGDataRequest) requestForVideoWithVideoID:videoId];
    // [self makeGETRequest:request withParser:[self valueForKey:@"videoParser_"] cache:videoCache responseBlock:responseBlock errorBlock:errorBlock];
    // it looks like cache isn't built into post requests, so we may want to do that ourselves
    [self makePOSTRequest:request withParser:[self valueForKey:@"videoParser_"] responseBlock:responseBlock errorBlock:errorBlock];
  }
}
%end

%hook YTVideoParser
-(YTVideo*)parseElement:(id)body error:(NSError*)error {
  if ([body isKindOfClass:[NSDictionary class]] ) {
    NSDictionary *data = body;

    NSMutableDictionary *thumbnails = [NSMutableDictionary new];
    NSDictionary *unparsedThumbnails = data[@"videoDetails"][@"thumbnails"][@"thumbnails"];
    for (NSDictionary *unparsedThumbnail in unparsedThumbnails) {
        [thumbnails setObject:[NSURL URLWithString:unparsedThumbnail[@"url"]] forKey:[NSValue valueWithBytes:&(CGSize){[unparsedThumbnail[@"height"] intValue],[unparsedThumbnail[@"width"] intValue]} objCType:@encode(CGSize)]];
    }

    NSURL *captionURL = nil;

    // its xml data so it will try to parse and fail (and crash & burn)
    // if ([data[@"captions"][@"playerCaptionsTracklistRenderer"][@"captionTracks"] length] > 0) {
    //   captionURL = [NSURL URLWithString:data[@"captions"][@"playerCaptionsTracklistRenderer"][@"captionTracks"]];
    // }

    NSMutableArray *availableCountries = [NSMutableArray array];

    for (NSString *country in data[@"microformat"][@"playerMicroformatRenderer"][@"availableCountries"]) {
      [availableCountries addObject:[country lowercaseString]];
    }

    NSMutableArray *ytStreams = [NSMutableArray array];
    for (NSDictionary *ytStream in data[@"streamingData"][@"formats"]) { // TODO: Some filtering would probably be nice for this
      [ytStreams addObject:[%c(YTStream) streamWithURL:[NSURL URLWithString:ytStream[@"url"]] // NSURL
                format:3 // [ytStream[@"itag"] intValue] //  can be 0, 2, 3, 4, 5, however i'm probably going to change it so it matches with the itag when i get to streaming
                encrypted:false // this is if google widevine is used
              ]];
    }

    return [[%c(YTVideo) alloc] initWithID:data[@"videoDetails"][@"videoId"]
                  title:data[@"videoDetails"][@"title"]
                  description:data[@"videoDetails"][@"shortDescription"]
                  uploaderDisplayName:data[@"videoDetails"][@"author"]
                  uploaderChannelID:data[@"videoDetails"][@"channelId"]
                  uploadedDate:RFC3339toNSDate(data[@"microformat"][@"playerMicroformatRenderer"][@"uploadDate"])  // does not work w/ android client
                  publishedDate:RFC3339toNSDate(data[@"microformat"][@"playerMicroformatRenderer"][@"publishDate"]) // does not work w/ android client
                  duration:[data[@"microformat"][@"playerMicroformatRenderer"][@"lengthSeconds"] intValue]  // does not work w/ android client
                  viewCount:[data[@"videoDetails"][@"viewCount"] intValue]
                  likesCount:[data[@"microformat"][@"playerMicroformatRenderer"][@"likeCount"] intValue]  // does not work w/ android client
                  dislikesCount:0 // hate
                  state:[[%c(YTVideoState) alloc] initWithCode:0 reason:@""] 
                  streams:ytStreams
                  thumbnailURLs:thumbnails
                  subtitlesTracksURL:captionURL
                  commentsAllowed:YES // rahhhhh
                  commentsURL:[NSURL URLWithString:@"https://example.com/commentsdummy/"]
                  commentsCountHint:0
                  relatedURL:data[@"videoDetails"][@"videoId"]
                  claimed:NO
                  monetized:NO 
                  monetizedCountries:@[] 
                  allowedCountries:availableCountries
                  deniedCountries:@[] 
                  categoryLabel:@"Gaming" // todo: this really needs category localization stuff
                  categoryTerm:data[@"microformat"][@"playerMicroformatRenderer"][@"category"] // does not work w/ android client
                  tags:@[] // gueeeessss what? we dont get this >:(
                  adultContent:NO 
                  videoPro:nil
              ];
  } else {
      NSLog(@"PANIK WE DIDNT GET JSON!!!!!!");
      // todo: actually throw an error instead of sending nil to the user
      return nil;
  }
  
}
%end

/// START DEFINITIONS
@interface YTWatchView_iPhone : NSObject 
- (id)guardView;
- (id)stageView;
- (int)layout;
- (void)didTouchStageShield;
- (void)adjustFrames;
- (void)endPanWithOffset:(float)fp8;
- (void)adjustScollViewInsetsFromView:(id)fp8;
- (BOOL)isOffsetNearestTopEdge:(float)fp8;
- (void)panWithOffset:(float)fp8;
- (void)panDown;
- (void)panUp;
- (void)setDelegate:(id)fp8;
- (void)setLayout:(int)fp8;
- (void)layoutSubviews;
- (id)initWithResourceLoader:(id)fp8 stackView:(id)fp12;

- (void)addGestureRecognizer:(id)fp8;
@end

@interface YTVideoView_iPhone : NSObject
- (YTAddCommentView*)addCommentView;
- (id)commentsFeedView;
- (id)suggestionsFeedView;
- (id)videoInfoView;
- (YTTabsView*)tabsView;
- (void)setCommentsAllowed:(BOOL)fp8;
- (void)dealloc;
- (id)initWithResourceLoader:(id)fp8;
@end

/// END DEFINITONS




// so uhhh i decompiled the wrong function... oops! Even worse, i had already decompiled the right function why am i bad at this????
// %hook YTWatchViewController_iPhone
// -(void)loadView {
//   // [super loadView];

//   [self setValue:[[%c(YTStackViewController) alloc] initWithMaximumDepth:4] forKey:@"stackController_"];
//   YTStackViewController *stackController = [self valueForKey:@"stackController_"];
//   [self addChildController:stackController];
//   [self didAddChildController:stackController];
  
//   [stackController setDelegate:self];
//   id stackViewController = [stackController view];

//   YTServices *services = [self services];
//   GIPResourceLoader *resourceLoader = [services resourceLoader];

//   [self setValue:[[%c(YTWatchView_iPhone) alloc] initWithResourceLoader:resourceLoader stackView:stackViewController] forKey:@"watchView_"];
//   YTWatchView_iPhone *watchView = [self valueForKey:@"watchView_"];
//   [watchView setDelegate:self];
//   [self setView:watchView];



//   YTVideoViewController_iPhone *videoViewController = [%c(YTVideoViewController_iPhone) alloc];
//   YTServices *superServices = [self valueForKey:@"services_"];
//   id superNavigation = [self valueForKey:@"navigation_"];
  
//   videoViewController = [[%c(YTVideoViewController_iPhone) alloc] initWithServices:superServices navigation:superNavigation];
//   [self setValue:videoViewController forKey:@"videoViewController_"];

//   YTVideoView_iPhone *videoView = [videoViewController view];

//   [self setValue:[videoView retain] forKey:@"videoView_"];
//   [[videoView tabsView] setDelegate:self];
//   [[videoView addCommentView] setDelegate:self];

//   [stackController pushViewController:[self valueForKey:@"videoViewController_"] animated:0];

//   UIPanGestureRecognizer *panGesture = [%c(UIPanGestureRecognizer) alloc];
//   panGesture = [panGesture initWithTarget:self action:@selector(handlePanWithRecognizer:)];
//   [panGesture setDelegate:self];
//   [self setValue:panGesture forKey:@"verticalPanRecognizer_"];
  
  
//   [watchView addGestureRecognizer:[self valueForKey:@"verticalPanRecognizer_"]];
//   if ([self valueForKey:@"video_"])
//   {
//     [self loadVideo];
//   }
//   else
//   {
//     YTGDataService *gdataService = [services gDataService];
//     NSString *videoID = [self valueForKey:@"videoID_"];
//     [gdataService makeVideoRequestWithVideoID:videoID responseBlock:^{
//       [self loadVideo];
//     } errorBlock:^(NSError *error){
//         GTMLogger *logger = [%c(GTMLogger) sharedLogger];
//         NSString *errorMsg = [error logDescription];
//         [logger logFuncError:@"__40-[YTWatchViewController_iPhone loadView]_block_invoke_072" msg:[NSString stringWithFormat:@"%@", errorMsg]];

//         YTNavigation *navigation = [self valueForKey:@"navigation_"];
//         [navigation toastWithError:error message:localizedStringForKey(@"error.video")];
//     }];
//   }
// }

// %end

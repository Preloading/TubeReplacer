#import <Foundation/Foundation.h>
#include "appheaders.h"

%hook YTGDataRequest
+(YTGDataRequest*)requestForVideoWithVideoID:(NSString*)videoId {
    // NSString *baseUrl = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"videos/%@", videoId];
    // GTMURLBuilder *urlBuilder = [GTMURLBuilder builderWithString:baseUrl];
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/player"];
    NSURL *fullURL = [urlBuilder URL];
    return [self requestWithURL:fullURL];
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


%hook YTWatchViewController_iPhone
-(void)loadView {
  // [super loadView];

  [self setValue:[[%c(YTStackViewController) alloc] initWithMaximumDepth:4] forKey:@"stackController_"];
  YTStackViewController *stackController = [self valueForKey:@"stackController_"];
  [self addChildController:stackController];
  [self didAddChildController:stackController];
  
  [stackController setDelegate:self];
  id stackViewController = [stackController view];

  YTServices *services = [self services];
  GIPResourceLoader *resourceLoader = [services resourceLoader];

  [self setValue:[[%c(YTWatchView_iPhone) alloc] initWithResourceLoader:resourceLoader stackView:stackViewController] forKey:@"watchView_"];
  YTWatchView_iPhone *watchView = [self valueForKey:@"watchView_"];
  [watchView setDelegate:self];
  [self setView:watchView];



  YTVideoViewController_iPhone *videoViewController = [%c(YTVideoViewController_iPhone) alloc];
  YTServices *superServices = [self valueForKey:@"services_"];
  id superNavigation = [self valueForKey:@"navigation_"];
  
  videoViewController = [[%c(YTVideoViewController_iPhone) alloc] initWithServices:superServices navigation:superNavigation];
  [self setValue:videoViewController forKey:@"videoViewController_"];

  YTVideoView_iPhone *videoView = [videoViewController view];

  [self setValue:[videoView retain] forKey:@"videoView_"];
  [[videoView tabsView] setDelegate:self];
  [[videoView addCommentView] setDelegate:self];

  [stackController pushViewController:[self valueForKey:@"videoViewController_"] animated:0];

  UIPanGestureRecognizer *panGesture = [%c(UIPanGestureRecognizer) alloc];
  panGesture = [panGesture initWithTarget:self action:@selector(handlePanWithRecognizer:)];
  [panGesture setDelegate:self];
  [self setValue:panGesture forKey:@"verticalPanRecognizer_"];
  
  
  [watchView addGestureRecognizer:[self valueForKey:@"verticalPanRecognizer_"]];
  // if (self->video_ )
  // {
  //   [self loadVideo];
  // }
  // else
  // {
  //   gdataService = [self->super.services_ gDataService];
  //   NSString *videoID = self->videoID_;
  //   requestResponceBlock = _stack_block_init(1107296256, &stru_4A4370, sub_E7A8);
  //   requestResponceBlock.superSelf = self;
  //   requestErrorBlock = _stack_block_init(1107296256, &stru_4A4390, sub_E81C);
  //   requestErrorBlock.superSelf = self;
  //   [gdataService makeVideoRequestWithVideoID:videoID responseBlock:&requestResponceBlock errorBlock:&requestErrorBlock];
  // }
}

%end
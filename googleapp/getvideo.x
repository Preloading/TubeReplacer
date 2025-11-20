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

%hook YTWatchViewController_iPhone
-(void)loadView {
  // [super loadView];

  self->stackController_ = [[%c(YTStackViewController) alloc] initWithMaximumDepth:4];
  [self addChildController:self->stackController_];
  [self didAddChildController:self->stackController_];
  [self->stackController_ setDelegate:self];
  id stackViewController = [self->stackController_ view];


  self->watchView_ = [[%c(YTWatchView_iPhone) alloc] initWithResourceLoader:[[self services] resourceLoader] stackView:stackViewController];
  [self->watchView_ setDelegate:self];
  [self setView:self->watchView_];

  self->videoViewController_ = [[%c(YTVideoViewController_iPhone) alloc] initWithServices:self->super.services_ navigation:self->super.navigation_];
  self->videoView_ = [[self->videoViewController_ view] retain];
  [[self->videoView_ tabsView] setDelegate:self];
  [[self->videoView_ addCommentView] setDelegate:self];

  [self->stackController_ pushViewController:self->videoViewController_ animated:0];

  self->verticalPanRecognizer_ = [[%c(UIPanGestureRecognizer) alloc] initWithTarget:self action:selector(handlePanWithRecognizer:)];
  [self->verticalPanRecognizer_ setDelegate:self];

  [self->watchView_ addGestureRecognizer:self->verticalPanRecognizer_];
  // if ( self->video_ )
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
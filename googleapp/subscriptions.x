#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest
+(id)requestForMySubscriptionsWithAuth:(id)authentication
{
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" authentication:authentication body:[YoutubeRequestClient browseBody:@"FEchannels" params:nil]];
}

+(id)requestForMySubscriptionWithChannelID:(NSString*)channelId auth:(id)authentication {
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" authentication:authentication body:[YoutubeRequestClient browseBody:channelId params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" withClient:[YoutubeClientType webMobileClient]]];
//   return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" authentication:authentication body:[YoutubeRequestClient browseBody:@"FEchannels" params:nil]];
}

+(id)requestToSubscribeWithChannelID:(NSString*)channelId authentication:(id)authentication {
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/subscription/subscribe?prettyPrint=false" authentication:authentication body:[YoutubeRequestClient subscribeToChannelId:channelId withClient:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataService

-(void)makeMySubscriptionRequestWithChannelID:(NSString*)channelId authentication:(id)authentication responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  id cache = [[self valueForKey:@"subscriptionCache_"] objectForKey:channelId];
  if (cache)
  {
    if (cache == [NSNull null])
        cache = nil;
    [self performResponseBlock:responseBlock response:cache];
  }
  else
  {
    id request = [%c(YTGDataRequest) requestForMySubscriptionWithChannelID:channelId auth:authentication];
    [self makePOSTRequest:request withParser:[self valueForKey:@"subscriptionParser_"] responseBlock:responseBlock errorBlock:errorBlock];
  }
}

-(void)makeMySubscriptionsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    [self makePOSTRequest:request withParser:[self valueForKey:@"subscriptionPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}
%end

%hook YTSubscriptionParser
    
-(id)parseElement:(id)body error:(NSError *)onError {
    if ([body isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *data = body;
        if (body[@"i"]) {
            NSDictionary *subscription = data[@"i"][@"channelListItemRenderer"];
            NSString *channelID = subscription[@"channelId"];
            NSString *displayName = subscription[@"title"][@"runs"][0][@"text"];
            NSString *thumbnail = [NSString stringWithFormat:@"https:%@", subscription[@"thumbnail"][@"thumbnails"][0][@"url"]];
            YTSubscription *sub = [[[%c(YTSubscription) alloc] initWithUsername:displayName // ugh
                displayName:displayName
                channelID:channelID
                type:1
                publishedDate:[NSDate date]
                updatedDate:[NSDate date]
                countHint:6969420
                editURL:[NSURL URLWithString:@"https://example.com/subediturl"]
                thumbnailURL:[NSURL URLWithString:thumbnail]
            ] autorelease];
            NSLog(@"YTSubscriptionParser");
            return sub;
        } else if (body[@"header"]) {
            // is the user subbed?
            // header.pageHeaderRenderer.content.pageHeaderViewModel.actions.flexibleActionsViewModel.acheader.pageHeaderRenderer.content.pageHeaderViewModel.actions.flexibleActionsViewModel.actionsRows[0].actions[0].subscribeButtonViewModel.subscribeButtonContent.subscribeStatetionsRows[0].actions[0].subscribeButtonViewModel.subscribeButtonContent.subscribeState
            NSLog(@"is subscribed to channel? -> %@", body[@"frameworkUpdates"][@"entityBatchUpdate"][@"mutations"][0][@"payload"][@"subscriptionStateEntity"][@"subscribed"]);
            if ([body[@"frameworkUpdates"][@"entityBatchUpdate"][@"mutations"][0][@"payload"][@"subscriptionStateEntity"][@"subscribed"] isEqual:@1]) {
                NSLog(@"subscribed!");
                NSString *thumbnail = [NSString stringWithFormat:@"%@", body[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"image"][@"decoratedAvatarViewModel"][@"avatar"][@"avatarViewModel"][@"image"][@"sources"][0][@"url"]];
                YTSubscription *sub = [[[%c(YTSubscription) alloc] initWithUsername:body[@"header"][@"pageHeaderRenderer"][@"pageTitle"] // ugh
                    displayName:body[@"header"][@"pageHeaderRenderer"][@"pageTitle"]
                    channelID:body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"browseEndpoint"][@"browseId"]
                    type:1
                    publishedDate:[NSDate date]
                    updatedDate:[NSDate date]
                    countHint:6969420
                    editURL:[NSURL URLWithString:@"https://example.com/subediturl"]
                    thumbnailURL:[NSURL URLWithString:thumbnail]
                ] autorelease];
                return sub;
            }
            
            NSLog(@"YTSubscriptionParser");
            // NSLog(@"channel name -> %@", body[@"header"][@"pageHeaderRenderer"][@"pageTitle"]);
            // onError = [NSError errorWithDomain:@"something i odnt know" code:1 userInfo:nil]; // help i dont know how to do that.
            return nil;
        } else {
            // if you just subscribed:
            YTSubscription *sub = [[[%c(YTSubscription) alloc] initWithUsername:nil
                displayName:@"is this visible?"
                channelID:body[@"actions"][2][@"updateSubscribeButtonAction"][@"channelId"]
                type:1
                publishedDate:[NSDate date]
                updatedDate:[NSDate date]
                countHint:6969420
                editURL:[NSURL URLWithString:@"https://example.com/subediturl"]
                thumbnailURL:[NSURL URLWithString:@"https://example.com/thumbnailurl"]
            ] autorelease];
            return sub;
        }
        //    
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }
}

%end

// we shouldn't need to implement /feeds/api/users/default/subscriptions?channel-id=, because our caching.

@interface YTChannelHeaderView_iPhone : NSObject
+ (float)preferredHeight;
- (void)setDisplayname:(id)fp8 subscribersCount:(unsigned long long)fp12;
- (id)subscribeSwitch;
- (void)resetThumbnailToPlaceholder;
- (void)setThumbnail:(id)fp8 animated:(BOOL)fp12;
- (void)setChannel:(id)fp8;
- (void)setDisplayName:(id)fp8;
- (void)setUserProfile:(id)fp8;
- (struct CGSize)sizeThatFits:(struct CGSize)fp8;
- (void)layoutSubviews;
- (id)initWithFrame:(struct CGRect)fp8;
- (id)initWithResourceLoader:(id)fp8 createSubscribeSwitch:(BOOL)fp12;
@end

@interface YTVideoInfoChannelCell_iPhone : NSObject
- (id)headerView;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (id)initWithStyle:(int)fp8 reuseIdentifier:(id)fp12;
- (id)initWithReuseIdentifier:(id)fp8 resourceLoader:(id)fp12;
@end

// static id ErrorBlockFactory(void)
// {
//     return nil;//[[stru_4A4A60 copy] autorelease];
// }


// %hook YTVideoInfoTableController_iPhone
// -(void)loadWithChannelID:(NSString*)channelId {
//     %log;
//   [[self valueForKey:@"subscribeSwitchController_"] autorelease];
//   YTSubscribeSwitchController* switchController = [%c(YTSubscribeSwitchController) alloc];
//   switchController = [switchController initWithChannelID:channelId navigation:[self valueForKey:@"navigation_"] services:[self valueForKey:@"services_"]];
//   YTVideoInfoChannelCell_iPhone *channelCell = [self valueForKey:@"channelCell_"];
//   [switchController setSubscribeSwitch:[[channelCell headerView] subscribeSwitch]];
//   [self setValue:switchController forKey:@"subscribeSwitchController_"];
// // YTSubscribeSwitchController

// //   responseBlock = _stack_block_init(1107296256, &stru_4A5340, sub_572F4);
// //   responseBlock.superSelf = self;
// //   errorBlock = sub_30824();
//   YTServices *service = [self valueForKey:@"services_"];
//   YTGDataService *gdata = [service gDataService];
//       id errorBlock = ErrorBlockFactory();
      
//   [gdata makeChannelRequestWithID:channelId responseBlock:^(id response) {
//     NSLog(@"rahhhhh");
//     } errorBlock:errorBlock];
//   //     ,
// //     &responseBlock,
// //     errorBlock);
// }
// %end
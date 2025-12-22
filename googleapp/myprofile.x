#include <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

+(id)requestForMyUserProfileWithAuth:(id)authentication
{
    // return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" authentication:authentication body:[YoutubeRequestClient browseBody:@"FElibrary" params:nil]];
    return [self requestWithURLString:@"https://m.youtube.com/getAccountSwitcherEndpoint" authentication:authentication];
}
// FElibrary
%end

%hook YTGDataService 

-(void)makeMyUserProfileRequestWithAuth:(id)auth responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  id request = [%c(YTGDataRequest) requestForMyUserProfileWithAuth:auth];
  [self makeGETRequest:request withParser:[self valueForKey:@"userProfileParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

%hook YTUserProfileParser
    
-(id)parseElement:(id)body error:(NSError *)onError {
    if ([body isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *data = body;

        NSDictionary *accountInfo = data[@"data"][@"actions"][0][@"getMultiPageMenuAction"][@"menu"][@"multiPageMenuRenderer"][@"sections"][0][@"accountSectionListRenderer"][@"contents"][0][@"accountItemSectionRenderer"][@"contents"][0][@"accountItem"];
        NSString *displayName = accountInfo[@"accountName"][@"simpleText"];
        NSString *channelHandle = [accountInfo[@"channelHandle"][@"simpleText"] substringFromIndex:1];
        int subscribersCount = YTTextToNumber(accountInfo[@"accountByline"][@"simpleText"]);
        NSURL *thumbnail = [NSURL URLWithString:accountInfo[@"accountPhoto"][@"thumbnails"][0][@"url"]];
        YTUserProfile *profile = [[[%c(YTUserProfile) alloc] initWithUsername:channelHandle
            displayName:displayName
            age:0
            thumbnailURL:thumbnail
            uploadsURL:[NSURL URLWithString:@"https://example.com/uploadsurl"]
            playlistsURL:[NSURL URLWithString:@"https://example.com/playlistsurl"]
            uploadedCount:0
            favoritesCount:0
            subscriptionsCount:0
            uploadViewsCount:0
            channelViewsCount:0
            subscribersCount:subscribersCount
        ] autorelease];
        return profile;
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }
}

%end
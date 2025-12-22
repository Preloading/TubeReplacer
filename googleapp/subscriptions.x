#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest
+(id)requestForMySubscriptionsWithAuth:(id)authentication
{
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" authentication:authentication body:[YoutubeRequestClient browseBody:@"FEchannels" params:nil]];
}
%end

%hook YTGDataService

-(void)makeMySubscriptionsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    [self makePOSTRequest:request withParser:[self valueForKey:@"subscriptionPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

%hook YTUserProfileParser
    
-(id)parseElement:(id)body error:(NSError *)onError {
    if ([body isKindOfClass:[NSDictionary class]] ) {
        // NSDictionary *data = body;

        // NSDictionary *accountInfo = data[@"data"][@"actions"][0][@"getMultiPageMenuAction"][@"menu"][@"multiPageMenuRenderer"][@"sections"][0][@"accountSectionListRenderer"][@"contents"][0][@"accountItemSectionRenderer"][@"contents"][0][@"accountItem"];
        // NSString *displayName = accountInfo[@"accountName"][@"simpleText"];
        // NSString *channelHandle = [accountInfo[@"channelHandle"][@"simpleText"] substringFromIndex:1];
        // int subscribersCount = YTTextToNumber(accountInfo[@"accountByline"][@"simpleText"]);
        // NSURL *thumbnail = [NSURL URLWithString:accountInfo[@"accountPhoto"][@"thumbnails"][0][@"url"]];
        YTSubscription *sub = [[[%c(YTSubscription) alloc] initWithUsername:@"michaelpenisgaming"
            displayName:@"michaelpenisgaming"
            channelID:@"michaelpenisgaming"
            type:1
            publishedDate:[NSDate date]
            updatedDate:[NSDate date]
            countHint:6969420
            editURL:[NSURL URLWithString:@"https://example.com/subediturl"]
            thumbnailURL:[NSURL URLWithString:@"https://example.com/subediturl"]
        ] autorelease];
        return sub;
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }
}

%end
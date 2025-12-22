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

%hook YTSubscriptionParser
    
-(id)parseElement:(id)body error:(NSError *)onError {
    if ([body isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *data = body;

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
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }
}

%end
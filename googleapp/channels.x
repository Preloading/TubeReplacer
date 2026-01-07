#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"


%hook YTGDataRequest
+(id)requestForChannelWithID:(NSString*)channelId
{
// this request is WAYYYYY overkill fir what we use it for
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" authentication:nil body:[YoutubeRequestClient browseBody:channelId params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" withClient:[YoutubeClientType webMobileClient]]];
}
%end

%hook YTGDataService
-(void)makeChannelRequestWithID:(NSString*)channelId responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  id url = [%c(YTGDataRequest) requestForChannelWithID:channelId];
  [self makePOSTRequest:url withParser:[self valueForKey:@"channelParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}
%end

%hook YTChannelParser

-(id)parseElement:(id)body error:(NSError*)error {
    if ([body isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *data = body;
        long subs = -1;
        long videoCount = -1;
        if ([data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"] count] >= 2) {
            if ([data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"][1][@"metadataParts"] count] >= 2) {
                subs = YTTextToNumber(data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"][1][@"metadataParts"][0][@"text"][@"content"]);
                videoCount = YTTextToNumber(data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"][1][@"metadataParts"][1][@"text"][@"content"]);
            } else if ([data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"][1][@"metadataParts"] count] == 1) {
                subs = YTTextToNumber(data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"metadata"][@"contentMetadataViewModel"][@"metadataRows"][1][@"metadataParts"][0][@"text"][@"content"]);
            }
        }
        YTChannel *channel = [[[%c(YTChannel) alloc] initWithDisplayName:data[@"header"][@"pageHeaderRenderer"][@"pageTitle"]
            channelID:data[@"metadata"][@"channelMetadataRenderer"][@"externalId"]
            summary:data[@"metadata"][@"channelMetadataRenderer"][@"description"]
            updated:[NSDate date] // todo: we aren't provided this, but since this is way overkill, we can get the latest video as the date
            videoCount:videoCount 
            thumbnailURL:[NSURL URLWithString:data[@"header"][@"pageHeaderRenderer"][@"content"][@"pageHeaderViewModel"][@"image"][@"decoratedAvatarViewModel"][@"avatar"][@"avatarViewModel"][@"image"][@"sources"][0][@"url"]] 
            subscribersCount:subs
        ] autorelease];

        return channel;
    } else {
        // welp. this 100% needs error handling: todo: fix this
        NSLog(@"ytchannel != NSDictionary, crash and burning time!");
        return nil;
    }
}

%end
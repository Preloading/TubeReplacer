#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataService

-(void)makeCommentsRequest:(id)originalRequest responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    NSString* videoId = [originalRequest valueForKey:@"URL_"];
    NSLog(@"videoId -> %@", videoId);
    YTGDataRequest *request = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
            authentication:nil 
            body:[YoutubeRequestClient commentsBody:videoId sortBy:@"top" withClient:[YoutubeClientType webMobileClient]]
        ];
    [self makePOSTRequest:request withParser:[self valueForKey:@"commentPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

@interface YTComment : NSObject
- (id)publishedDate;
- (id)authorDisplayName;
- (id)content;
- (id)title;
- (unsigned int)hash;
- (BOOL)isEqual:(id)fp8;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithTitle:(id)fp8 content:(id)fp12 authorDisplayName:(id)fp16 publishedDate:(id)fp20;

@end


%hook YTCommentParser

-(id)parseElement:(NSDictionary*)body error:(NSError *)onError
{
    NSString *commentText = @"";
    for (NSDictionary *textSection in body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"contentText"][@"runs"]) {
        commentText = [NSString stringWithFormat:@"%@%@", commentText, textSection[@"text"]];
    }

    return [[[%c(YTComment) alloc] initWithTitle:body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"authorText"][@"runs"][0][@"text"]
        content:commentText
        authorDisplayName:body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"authorText"][@"runs"][0][@"text"]
        publishedDate:YTTimeAgoToDate(body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"publishedTimeText"][@"runs"][0][@"text"])
    ] autorelease];
}

%end
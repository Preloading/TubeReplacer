#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

+(id)requestToAddCommentWithVideoID:(NSString*)videoId authentication:(id)authentication content:(NSString*)content {
  return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/comment/create_comment?prettyPrint=false" 
            authentication:authentication 
            body:[YoutubeRequestClient addComment:videoId commentText:content withClient:[YoutubeClientType webMobileClient]]
        ];
}

%end

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
    if (body[@"i"]) {
        NSString *commentText = @"";
        for (NSDictionary *textSection in body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"contentText"][@"runs"]) {
            commentText = [NSString stringWithFormat:@"%@%@", commentText, textSection[@"text"]];
        }

        NSString *username = body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"authorText"][@"runs"][0][@"text"];

        return [[[%c(YTComment) alloc] initWithTitle:username
            content:commentText
            authorDisplayName:username
            publishedDate:YTTimeAgoToDate(body[@"i"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"publishedTimeText"][@"runs"][0][@"text"])
        ] autorelease];
    } else {
        // probably add comment
        NSString *username = body[@"actions"][1][@"createCommentAction"][@"contents"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"authorThumbnail"][@"accessibility"][@"accessibilityData"][@"label"];
        return [[[%c(YTComment) alloc] initWithTitle:username
            content:body[@"actions"][1][@"createCommentAction"][@"contents"][@"commentThreadRenderer"][@"comment"][@"commentRenderer"][@"contentText"][@"runs"][0][@"text"]
            authorDisplayName:username
            publishedDate:[NSDate date] // considering it was just made, i'm enclined to say this is good enough.
        ] autorelease];
    }
}

%end

// %hook YTCommentsFeedController
// -(void)addComment {
//   [[[self valueForKey:@"services_"] userAuthenticator] authenticateWithBlock:^(id authentication){
//     NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
//   }];
// }
// %end
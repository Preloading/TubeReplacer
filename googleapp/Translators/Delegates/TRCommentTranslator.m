// TRCommentTranslator.m
// TubeReplacer
//
// Comment translator implementation

#import "TRCommentTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"
#import "../general.h"

@interface YTComment : NSObject
- (id)initWithTitle:(id)title content:(id)content authorDisplayName:(id)displayName publishedDate:(id)date;
// 1.2.1+
- (id)initWithTitle:(id)title content:(id)content authorDisplayName:(id)displayName publishedDate:(id)date isSpam:(BOOL)isSpam;
@end

@implementation TRCommentTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeComment;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    // Feed comment format (wrapped in "i" key from page parser)
    if ([json objectForKey:@"i"]) {
        NSDictionary *inner = [json objectForKey:@"i"];
        if ([inner objectForKey:@"commentThreadRenderer"]) {
            return YES;
        }
    }
    // Created comment response
    if ([TRJSONUtils dictFromJSON:json keyPath:@"actions[1].createCommentAction"]) {
        return YES;
    }
    return NO;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRCommentTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    if ([json objectForKey:@"i"]) {
        return [self translateFeedComment:json error:error];
    }
    
    return [self translateCreatedComment:json error:error];
}

#pragma mark - Feed Comment (from page parser)

- (id)translateFeedComment:(NSDictionary *)json error:(NSError **)error {
    NSDictionary *commentData = [TRJSONUtils dictFromJSON:json 
        keyPath:@"i.commentThreadRenderer.comment.commentRenderer"];
    
    if (!commentData) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRCommentTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing comment data"}];
        }
        return nil;
    }
    
    NSMutableString *commentText = [NSMutableString string];
    NSArray *runs = [TRJSONUtils arrayFromJSON:commentData keyPath:@"contentText.runs"];
    for (NSDictionary *run in runs) {
        NSString *text = [run objectForKey:@"text"];
        if (text) {
            [commentText appendString:text];
        }
    }
    
    NSString *username = [TRJSONUtils stringFromJSON:commentData keyPath:@"authorText.runs[0].text"];
    NSString *timeAgo = [TRJSONUtils stringFromJSON:commentData keyPath:@"publishedTimeText.runs[0].text"];
    NSDate *publishedDate = [TRJSONUtils dateFromTimeAgo:timeAgo];
    
    id comment = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
        comment = [[[NSClassFromString(@"YTComment") alloc] 
            initWithTitle:username
            content:commentText
            authorDisplayName:username
            publishedDate:publishedDate
        ] autorelease];
    } else {
        comment = [[[NSClassFromString(@"YTComment") alloc] 
            initWithTitle:username
            content:commentText
            authorDisplayName:username
            publishedDate:publishedDate
            isSpam:NO // well i hope not :)
        ] autorelease];
    }

    return comment;
}

#pragma mark - Created Comment (just posted)

- (id)translateCreatedComment:(NSDictionary *)json error:(NSError **)error {
    // Path: actions[1].createCommentAction.contents.commentThreadRenderer.comment.commentRenderer
    NSDictionary *commentData = [TRJSONUtils dictFromJSON:json 
        keyPath:@"actions[1].createCommentAction.contents.commentThreadRenderer.comment.commentRenderer"];
    
    if (!commentData) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRCommentTranslator" code:3 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing created comment data"}];
        }
        return nil;
    }
    
    // Author from accessibility label
    NSString *username = [TRJSONUtils stringFromJSON:commentData 
        keyPath:@"authorThumbnail.accessibility.accessibilityData.label"];
    
    // Comment text
    NSString *content = [TRJSONUtils stringFromJSON:commentData keyPath:@"contentText.runs[0].text"];
    
    // Just created, so use current date
    NSDate *publishedDate = [NSDate date];
    
    id comment = [[[NSClassFromString(@"YTComment") alloc] 
        initWithTitle:username
        content:content ?: @""
        authorDisplayName:username ?: @""
        publishedDate:publishedDate
    ] autorelease];
    
    return comment;
}

@end

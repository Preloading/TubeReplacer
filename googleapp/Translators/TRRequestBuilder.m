// TRRequestBuilder.m
// TubeReplacer
//
// Unified request builder implementation

#import "TRRequestBuilder.h"
#import "../../YoutubeClientType.h"
#import "../../Protobuf.h"
#import "../../base64/NSData+Base64.h"

@implementation TRRequestBuilder

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static TRRequestBuilder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TRRequestBuilder alloc] init];
    });
    return instance;
}

#pragma mark - Base Request Building

+ (NSMutableDictionary *)baseBodyWithClient:(YoutubeClientType *)client {
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    
    if (client) {
        [body setObject:[client makeContext] forKey:@"context"];
    }
    
    return body;
}

+ (NSData *)serializeBody:(NSDictionary *)body {
    if (!body) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    
    if (error) {
        NSLog(@"TRRequestBuilder: JSON serialization failed: %@", error);
        return nil;
    }
    
    return data;
}

+ (NSData *)bodyWithClient:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    return [self serializeBody:body];
}

#pragma mark - Browse Requests

+ (NSData *)browseBodyWithId:(NSString *)browseId 
                      params:(NSString *)params 
                      client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (browseId) {
        [body setObject:browseId forKey:@"browseId"];
    }
    
    if (params) {
        [body setObject:params forKey:@"params"];
    }
    
    return [self serializeBody:body];
}

#pragma mark - Continuation

+ (NSData *)continueWithContext:(NSString *)context 
                      client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    [body setObject:context forKey:@"continuation"];
    
    return [self serializeBody:body];
}

#pragma mark - Player Requests

+ (NSData *)playerBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (videoId) {
        [body setObject:videoId forKey:@"videoId"];
    }
    
    return [self serializeBody:body];
}

+ (NSData *)nextBodyWithVideoId:(NSString *)videoId 
                         client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (videoId) {
        [body setObject:videoId forKey:@"videoId"];
    }
    
    // racyCheckOk and contentCheckOk allow mature content
    [body setObject:@YES forKey:@"racyCheckOk"];
    [body setObject:@YES forKey:@"contentCheckOk"];
    
    return [self serializeBody:body];
}

#pragma mark - Search Requests

+ (NSData *)searchBodyWithQuery:(NSString *)query
                    channelOnly:(BOOL)channelOnly
                    sortBy:(int)sortBy  // 0 - relevance, 1 = rating, 2 = date, 3 = views
                    duration:(int)duration //duration 1 == under 4 minutes, 3 == 4-20 minutes, 2 == 20+ minutes
                    hasCC:(BOOL)hasCC
                    posted:(int)posted  // posted 2 == today, 3 == This week, 4 ==  this month, 5 == this year
                    client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (query) {
        [body setObject:query forKey:@"query"];
    }
    
    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    
    [enc writeMessageField:2 usingBlock:^(ProtobufEncoder *a) {
        [a writeUInt64Field:2 value:channelOnly ? 2 : 1];
        if (posted != 0)
            [a writeUInt64Field:1 value:posted]; // posted 2 == today, 3 == This week, 4 ==  this month, 5 == this year
        if (duration != 0)
            [a writeUInt64Field:3 value:1]; //duration 1 == under 4 minutes, 3 == 4-20 minutes, 2 == 20+ minutes
        if (hasCC)
            [a writeUInt64Field:5 value:1]; // has closed captions

    }];

    if (sortBy != 0)
        [enc writeUInt64Field:1 value:sortBy] ;// 0 - relevance, 1 = rating, 2 = date, 3 = views
        
    // [enc writeMessageField:6 usingBlock:^(ProtobufEncoder *a) {
    //     [a writeMessageField:4 usingBlock:^(ProtobufEncoder *b) {
    //         [b writeStringField:4 string:videoId];
    //         [b writeUInt64Field:6 value:sortByVal];
    //     }];
    //     [a writeUInt64Field:6 value:1];
    //     [a writeStringField:8 string:@"engagement-panel-comments-section"];
    // }];
    
    NSData *out = [enc dataRepresentation];
    [enc release];
    NSLog(@"param -> %@", [self urlEncodeBase64:out]);

    // Filter params: EgIQAg%3D%3D = channels, EgIQAQ%3D%3D = videos
    // NSString *filterParams = channelOnly ? @"EgIQAg%3D%3D" : @"EgIQAQ%3D%3D";
    [body setObject:[self urlEncodeBase64:out] forKey:@"params"];
    
    return [self serializeBody:body];
}

#pragma mark - Action Requests

+ (NSData *)subscribeBodyWithChannelId:(NSString *)channelId 
                                client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    [body setObject:@"EgIIAxgAIgtxQ0dUX0NLR2dGRQ%3D%3D" forKey:@"params"];
    
    if (channelId) {
        [body setObject:@[channelId] forKey:@"channelIds"];
    }
    
    return [self serializeBody:body];
}

+ (NSData *)addCommentBodyWithVideoId:(NSString *)videoId 
                          commentText:(NSString *)commentText 
                               client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (commentText) {
        [body setObject:commentText forKey:@"commentText"];
    }
    
    // Build protobuf-encoded params
    if (videoId) {
        NSString *encodedParams = [self encodeCommentParams:videoId];
        if (encodedParams) {
            [body setObject:encodedParams forKey:@"createCommentParams"];
        }
    }
    
    return [self serializeBody:body];
}

+ (NSData *)getPopularVideosFromChannelId:(NSString *)channelId 
                               client:(YoutubeClientType *)client {    
    return [self continueWithContext:[self encodePopularChannelVideos:channelId] client:client];
}


#pragma mark - Comments/Continuation Requests

+ (NSData *)commentsBodyWithVideoId:(NSString *)videoId 
                             sortBy:(NSString *)sortBy 
                             client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    // Build protobuf continuation token
    if (videoId) {
        NSString *continuation = [self encodeCommentsContinuation:videoId sortBy:sortBy];
        if (continuation) {
            [body setObject:continuation forKey:@"continuation"];
        }
    }
    
    return [self serializeBody:body];
}

#pragma mark - Protobuf Encoding Helpers

+ (NSString *)encodeCommentParams:(NSString *)videoId {
    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    [enc writeStringField:2 string:videoId];
    
    NSData *out = [enc dataRepresentation];
    [enc release];
    
    return [self urlEncodeBase64:out];
}

+ (NSString *)encodeCommentsContinuation:(NSString *)videoId sortBy:(NSString *)sortBy {
    uint64_t sortByVal = 0;
    if ([sortBy isEqualToString:@"newest"]) {
        sortByVal = 1;
    }
    
    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    
    [enc writeMessageField:2 usingBlock:^(ProtobufEncoder *a) {
        [a writeStringField:2 string:videoId];
    }];
    
    [enc writeUInt64Field:3 value:6];
    
    [enc writeMessageField:6 usingBlock:^(ProtobufEncoder *a) {
        [a writeMessageField:4 usingBlock:^(ProtobufEncoder *b) {
            [b writeStringField:4 string:videoId];
            [b writeUInt64Field:6 value:sortByVal];
        }];
        [a writeUInt64Field:6 value:1];
        [a writeStringField:8 string:@"engagement-panel-comments-section"];
    }];
    
    NSData *out = [enc dataRepresentation];
    [enc release];
    
    return [self urlEncodeBase64:out];
}

+ (NSString *)encodePopularChannelVideos:(NSString *)channelId {
    ProtobufEncoder *enc = [[ProtobufEncoder alloc] init];
    
    [enc writeMessageField:110 usingBlock:^(ProtobufEncoder *a) {
        [a writeMessageField:3 usingBlock:^(ProtobufEncoder *b) {
            [b writeMessageField:15 usingBlock:^(ProtobufEncoder *c) {
                [c writeMessageField:2 usingBlock:^(ProtobufEncoder *d) {
                    [d writeStringField:1 string:@"6e2801c0-0000-28a8-ac69-582429a74ce0"];
                }];
                [c writeUInt64Field:4 value:2];
                [c writeMessageField:8 usingBlock:^(ProtobufEncoder *d) {
                    [d writeStringField:1 string:@"6e2801c0-0000-28a8-ac69-582429a74ce0"];
                    [d writeUInt64Field:3 value:2];
                }];
            }];
        }];

    }];
    
    ProtobufEncoder *enc2 = [[ProtobufEncoder alloc] init];
    
    [enc2 writeMessageField:80226972 usingBlock:^(ProtobufEncoder *a) {
        [a writeStringField:2 string:channelId];
        [a writeStringField:3 string:[self urlEncodeBase64:[enc dataRepresentation]]];
    }];

    [enc release];
    
    NSData *out = [enc2 dataRepresentation];
    [enc2 release];
    
    return [self urlEncodeBase64:out];
}

+ (NSString *)urlEncodeBase64:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    NSString *b64 = [data base64EncodedString];
    
    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(
        NULL, 
        (CFStringRef)b64, 
        NULL, 
        CFSTR(":/?#[]@!$&'()*+,;="), 
        kCFStringEncodingUTF8
    );
    
    // Transfer ownership to ARC-compatible autorelease
    return [(NSString *)escaped autorelease];
}

#pragma mark - Like/Unlike Requests

+ (NSData *)likeBodyWithVideoId:(NSString *)videoId 
                         client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (videoId) {
        // The target structure for like endpoint
        NSDictionary *target = @{
            @"videoId": videoId
        };
        [body setObject:target forKey:@"target"];
    }
    
    return [self serializeBody:body];
}

+ (NSData *)unlikeBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client {
    
    // Same body structure as like
    return [self likeBodyWithVideoId:videoId client:client];
}

#pragma mark - Playlist Management

+ (NSData *)addVideoToPlaylistBodyWithVideoIds:(NSArray *)videoIds playlistId:(NSString*)playlistId
                         client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (videoIds && [videoIds count] != 0) {
        // The target structure for like endpoint
        NSMutableArray *actions = [[NSMutableArray alloc] init];
        for (NSString *videoId in videoIds) {
            [actions addObject:@{
                @"addedVideoId":videoId,
                @"action":@"ACTION_ADD_VIDEO"
            }];
        }

        [body setObject:actions forKey:@"actions"];
        [body setObject:playlistId forKey:@"playlistId"];

    }
    
    return [self serializeBody:body];
}

@end

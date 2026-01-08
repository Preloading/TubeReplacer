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

#pragma mark - Player Requests

+ (NSData *)playerBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (videoId) {
        [body setObject:videoId forKey:@"videoId"];
    }
    
    return [self serializeBody:body];
}

#pragma mark - Search Requests

+ (NSData *)searchBodyWithQuery:(NSString *)query
                    channelOnly:(BOOL)channelOnly
                         client:(YoutubeClientType *)client {
    
    NSMutableDictionary *body = [self baseBodyWithClient:client];
    
    if (query) {
        [body setObject:query forKey:@"query"];
    }
    
    // Filter params: EgIQAg%3D%3D = channels, EgIQAQ%3D%3D = videos
    NSString *filterParams = channelOnly ? @"EgIQAg%3D%3D" : @"EgIQAQ%3D%3D";
    [body setObject:filterParams forKey:@"params"];
    
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

@end

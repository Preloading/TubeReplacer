// TRRequestBuilder.h
// TubeReplacer
//
// Base request builder that handles common patterns for YouTube API requests

#import <Foundation/Foundation.h>
#import "TREndpointType.h"

@class YoutubeClientType;

@interface TRRequestBuilder : NSObject

#pragma mark - Singleton

+ (instancetype)sharedInstance;

#pragma mark - Base Request Building

/**
 * Create a base request body with just the client context.
 * All YouTube API requests require this.
 */
+ (NSMutableDictionary *)baseBodyWithClient:(YoutubeClientType *)client;

/**
 * Serialize a dictionary to JSON NSData.
 * Handles errors gracefully, returns nil on failure.
 */
+ (NSData *)serializeBody:(NSDictionary *)body;

#pragma mark - Browse Requests

/**
 * Build body for browse endpoint (channels, feeds, playlists, etc.)
 */
+ (NSData *)browseBodyWithId:(NSString *)browseId 
                      params:(NSString *)params 
                      client:(YoutubeClientType *)client;

#pragma mark - Player Requests

/**
 * Build body for player endpoint (video playback info)
 */
+ (NSData *)playerBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client;

#pragma mark - Search Requests

/**
 * Build body for search endpoint
 */
+ (NSData *)searchBodyWithQuery:(NSString *)query
                    channelOnly:(BOOL)channelOnly
                         client:(YoutubeClientType *)client;

#pragma mark - Action Requests

/**
 * Build body for subscription action
 */
+ (NSData *)subscribeBodyWithChannelId:(NSString *)channelId 
                                client:(YoutubeClientType *)client;

/**
 * Build body for adding a comment
 */
+ (NSData *)addCommentBodyWithVideoId:(NSString *)videoId 
                          commentText:(NSString *)commentText 
                               client:(YoutubeClientType *)client;

#pragma mark - Comments/Continuation Requests

/**
 * Build body for fetching comments with continuation
 */
+ (NSData *)commentsBodyWithVideoId:(NSString *)videoId 
                             sortBy:(NSString *)sortBy 
                             client:(YoutubeClientType *)client;

@end

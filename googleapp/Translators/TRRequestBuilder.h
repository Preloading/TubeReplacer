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
+ (NSData *)bodyWithClient:(YoutubeClientType *)client;
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

+ (NSData *)continueWithContext:(NSString *)context 
                      client:(YoutubeClientType *)client;

#pragma mark - Player Requests

/**
 * Build body for player endpoint (video playback info)
 */
+ (NSData *)playerBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client;

/**
 * Build body for next endpoint (video UI info including likes)
 */
+ (NSData *)nextBodyWithVideoId:(NSString *)videoId 
                         client:(YoutubeClientType *)client;

+ (NSData *)getPopularVideosFromChannelId:(NSString *)channelId 
                                   client:(YoutubeClientType *)client;

#pragma mark - Search Requests

/**
 * Build body for search endpoint
 */
+ (NSData *)searchBodyWithQuery:(NSString *)query
                    channelOnly:(BOOL)channelOnly
                    sortBy:(int)sortBy  // 0 - relevance, 1 = rating, 2 = date, 3 = views
                    duration:(int)duration //duration 1 == under 4 minutes, 3 == 4-20 minutes, 2 == 20+ minutes
                    hasCC:(BOOL)hasCC
                    posted:(int)posted  // posted 2 == today, 3 == This week, 4 ==  this month, 5 == this year
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

#pragma mark - Like/Unlike Requests

/**
 * Build body for liking a video
 */
+ (NSData *)likeBodyWithVideoId:(NSString *)videoId 
                         client:(YoutubeClientType *)client;

/**
 * Build body for removing a like from a video
 */
+ (NSData *)unlikeBodyWithVideoId:(NSString *)videoId 
                           client:(YoutubeClientType *)client;

@end

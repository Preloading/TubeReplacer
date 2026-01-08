#import "YoutubeRequestClient.h"
#import "googleapp/Translators/TRRequestBuilder.h"
#import "googleapp/Translators/TRJSONUtils.h"

@implementation YoutubeRequestClient

// All request building is now delegated to TRRequestBuilder.
// These methods remain for backward compatibility with existing hook code.

+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params {
    return [TRRequestBuilder browseBodyWithId:browseId 
                                       params:params 
                                       client:[YoutubeClientType webMobileClient]];
}

+(NSData*)browseBody:(NSString*)browseId params:(NSString*)params withClient:(YoutubeClientType*)client {
    return [TRRequestBuilder browseBodyWithId:browseId 
                                       params:params 
                                       client:client];
}

+(NSData*)getVideoWithID:(NSString*)videoId {
    return [TRRequestBuilder playerBodyWithVideoId:videoId 
                                            client:[YoutubeClientType androidClient]];
}

+(NSData*)getVideoWithID:(NSString*)videoId withClient:(YoutubeClientType*)client {
    return [TRRequestBuilder playerBodyWithVideoId:videoId 
                                            client:client];
}

+(NSData*)searchBody:(NSString*)query sortBy:(NSString*)sortBy uploadDateFilter:(NSString*)uploadDateFilter duration:(NSString*)duration hasCC:(BOOL)hasCC withClient:(YoutubeClientType*)client isChannelLookup:(BOOL)isChannelLookup {
    // TODO: sortBy, uploadDateFilter, duration, hasCC are not yet implemented in TRRequestBuilder
    // For now, just using basic search
    return [TRRequestBuilder searchBodyWithQuery:query 
                                     channelOnly:isChannelLookup 
                                          client:client];
}

+(NSData*)commentsBody:(NSString*)videoId sortBy:(NSString*)sortBy withClient:(YoutubeClientType*)client {
    return [TRRequestBuilder commentsBodyWithVideoId:videoId 
                                              sortBy:sortBy 
                                              client:client];
}

+(NSData*)addComment:(NSString*)videoId commentText:(NSString*)commentText withClient:(YoutubeClientType*)client {
    return [TRRequestBuilder addCommentBodyWithVideoId:videoId 
                                           commentText:commentText 
                                                client:client];
}

+(NSData*)clientOnlyWithClient:(YoutubeClientType*)client {
    return [TRRequestBuilder serializeBody:[TRRequestBuilder baseBodyWithClient:client]];
}

+(NSData*)subscribeToChannelId:(NSString*)channelId withClient:(YoutubeClientType*)client {
    return [TRRequestBuilder subscribeBodyWithChannelId:channelId 
                                                 client:client];
}

@end

// Helper functions now delegate to TRJSONUtils
// These remain for backward compatibility with code that hasn't been migrated yet

NSDate *RFC3339toNSDate(NSString *rfc3339DateTimeString) {
    return [TRJSONUtils dateFromRFC3339:rfc3339DateTimeString];
}

NSDate *YTTimeAgoToDate(NSString *timeAgo) {
    return [TRJSONUtils dateFromTimeAgo:timeAgo];
}

long YTTextToNumber(NSString *string) {
    return [TRJSONUtils numberFromText:string];
}
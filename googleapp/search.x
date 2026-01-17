// search.x
// TubeReplacer
//
// Search video and channel hooks

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

@interface YTSearchFilters : NSObject {
    int sortBy_;
    int uploadDate_;
    int duration_;
    BOOL CC_;
}

- (void)setCC:(BOOL)cc;
- (BOOL)hasCC;
- (void)setDuration:(int)duration;
- (id)duration;
- (void)setUploadDate:(int)uploadDate;
- (id)uploadDate;
- (void)setSortBy:(int)sortBy;
- (id)sortBy;
- (id)copyWithZone:(struct _NSZone *)zone;

@end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForVideosWithSearchQuery:(NSString*)query 
                        languageCode:(NSString*)language 
                             filters:(YTSearchFilters*)filters 
                          safeSearch:(NSString*)safeSearchLevel {
    // TODO: Implement full filter support in TRRequestBuilder
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:NO 
                                                               client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForChannelsWithSearchQuery:(NSString*)query {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:YES 
                                                               client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeSearchVideosRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil // i hope this wont cause issues... 
                           body:[TRRequestBuilder continueWithContext:[request URL] 
                                                            client:[YoutubeClientType webMobileClient]]];
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makeSearchChannelsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil // i hope this wont cause issues... 
                           body:[TRRequestBuilder continueWithContext:[request URL] 
                                                            client:[YoutubeClientType webMobileClient]]];
    }
    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"channelPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

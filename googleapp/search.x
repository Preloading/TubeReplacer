// search.x
// TubeReplacer
//
// Search video and channel hooks

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

@interface YTSearchFilters : NSObject {
    int sortBy_;
    int uploadDate_;
    int duration_;
    BOOL CC_;
}

- (void)setCC:(BOOL)cc;
- (BOOL)hasCC;
- (void)setDuration:(int)duration;
- (int)duration;
- (void)setUploadDate:(int)uploadDate;
- (int)uploadDate;
- (void)setSortBy:(int)sortBy;
- (int)sortBy;
- (id)copyWithZone:(struct _NSZone *)zone;

@end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForVideosWithSearchQuery:(NSString*)query 
                        languageCode:(NSString*)language 
                             filters:(YTSearchFilters*)filters 
                          safeSearch:(NSString*)safeSearchLevel {

    int sortBy = 0;
    int uploadDate = 0;
    int duration = 0;

    switch ([filters sortBy]) {
        case 1: // upload date
            sortBy = 2;
            break;
        case 2: // view count
            sortBy = 3;
            break;
        case 3: // rating
            sortBy = 1;
            break;
    }

    switch ([filters uploadDate]) {
        case 1: // today
            uploadDate = 2;
            break;
        case 2: // this week
            uploadDate = 3;
            break;
        case 3: // this month
            uploadDate = 4;
            break;
    }


    switch ([filters duration]) {
        case 1: // <4 minutes
            duration = 1;
            break;
        case 2: // 20+ minutes
            duration = 2;
            break;
    }
    NSLog(@"sortBy #2 -> %i", sortBy);

    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:NO 
                                                          sortBy:sortBy
                                                          duration:duration
                                                          hasCC:[filters hasCC]
                                                          posted:uploadDate
                                                               client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForChannelsWithSearchQuery:(NSString*)query {

    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:YES 
                                                          sortBy:0
                                                          duration:0
                                                          hasCC:NO
                                                          posted:0
                                                               client:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataRequestFactory

-(id)requestForVideosWithSearchQuery:(NSString*)query 
                        languageCode:(NSString*)language 
                             filters:(YTSearchFilters*)filters 
                          safeSearch:(NSString*)safeSearchLevel {

    int sortBy = 0;
    int uploadDate = 0;
    int duration = 0;

    switch ([filters sortBy]) {
        case 1: // upload date
            sortBy = 2;
            break;
        case 2: // view count
            sortBy = 3;
            break;
        case 3: // rating
            sortBy = 1;
            break;
    }

    switch ([filters uploadDate]) {
        case 1: // today
            uploadDate = 2;
            break;
        case 2: // this week
            uploadDate = 3;
            break;
        case 3: // this month
            uploadDate = 4;
            break;
    }


    switch ([filters duration]) {
        case 1: // <4 minutes
            duration = 1;
            break;
        case 2: // 20+ minutes
            duration = 2;
            break;
    }
    NSLog(@"sortBy #2 -> %i", sortBy);

    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:NO 
                                                          sortBy:sortBy
                                                          duration:duration
                                                          hasCC:[filters hasCC]
                                                          posted:uploadDate
                                                               client:[YoutubeClientType webMobileClient]]];
}

-(id)requestForChannelsWithSearchQuery:(NSString*)query {

    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                 authentication:nil 
                           body:[TRRequestBuilder searchBodyWithQuery:query 
                                                          channelOnly:YES 
                                                          sortBy:0
                                                          duration:0
                                                          hasCC:NO
                                                          posted:0
                                                               client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeSearchVideosRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        }
    }

    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

-(void)makeSearchChannelsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                    body:[TRRequestBuilder continueWithContext:[request URL] 
                    client:[YoutubeClientType webMobileClient]]];
        }
    }
    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"channelPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

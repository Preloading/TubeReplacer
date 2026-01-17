// frontfeed.x
// TubeReplacer
//
// Standard/category video feeds (front page, categories)

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeVideosStandardFeedRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] 
                 authentication:nil // i hope this wont cause issues... 
                           body:[TRRequestBuilder continueWithContext:[request URL] 
                                                            client:[YoutubeClientType webMobileClient]]];
    }
    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:@"videoPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForVideosWithStandardFeed:(int)requestingForInt categoryTerm:(NSString*)category uploadDate:(int)uploadFilter safeSearch:(int)safeSearch {
    // Map category to pre-defined playlist browse IDs
    // These are curated "trending" style playlists for each category
    NSString *browseId = @"VLPL-p0-Yh03xpi2AsCiyuafMeQrMF6czMoL"; // default
    
    if ([category isEqualToString:@"Games"]) {
        browseId = @"VLPL-p0-Yh03xpi_x9L-Lqop_Kj6MTY38jqv";
    } else if ([category isEqualToString:@"Film"]) {
        browseId = @"VLPL-p0-Yh03xpgQgBqDn3T4EZbxoaYXkQjY";
    } else if ([category isEqualToString:@"Autos"]) {
        browseId = @"VLPL-p0-Yh03xphS0WmPB1u5mQbRJjPRn63U";
    } else if ([category isEqualToString:@"Music"]) {
        browseId = @"VLPL-p0-Yh03xpgeN91B_sPpv4lJY-UfThEi";
    } else if ([category isEqualToString:@"Animals"]) {
        browseId = @"VLPL-p0-Yh03xpgqRqXBDc9DbcCysUjd_CSB";
    } else if ([category isEqualToString:@"Sports"]) {
        browseId = @"VLPL-p0-Yh03xpg6CLD7MDqzsAiB9aFjssWb";
    } else if ([category isEqualToString:@"Comedy"]) {
        browseId = @"VLPL-p0-Yh03xpj0Js3pnGO20BWWiHVn1oHz";
    } else if ([category isEqualToString:@"People"]) {
        browseId = @"VLPL-p0-Yh03xphi7-iBuIshu7olymbv7lY-";
    } else if ([category isEqualToString:@"News"]) {
        browseId = @"VLPL-p0-Yh03xpgeG3YUmWESSrg84W8ELEUO";
    } else if ([category isEqualToString:@"Entertainment"]) {
        browseId = @"VLPL-p0-Yh03xpjoqDAI46lgo8-TLDnE7mHF";
    } else if ([category isEqualToString:@"Howto"]) {
        browseId = @"VLPL-p0-Yh03xphCxNSaXOW09V3pKgRQCFvn";
    } else if ([category isEqualToString:@"Tech"]) {
        browseId = @"VLPL-p0-Yh03xpgQgBqDn3T4EZbxoaYXkQjY";
    }
    
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/browse"];
    NSURL *fullURL = [urlBuilder URL];
    
    return [self requestWithURL:fullURL 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:browseId 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

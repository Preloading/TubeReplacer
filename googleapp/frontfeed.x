// frontfeed.x
// TubeReplacer
//
// Standard/category video feeds (front page, categories)

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeVideosStandardFeedRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id actualRequest = request;
    if ([[request URL] isKindOfClass:[NSString class]]) {
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            actualRequest = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        } else {
            actualRequest = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"] 
                    authentication:nil // i hope this wont cause issues... 
                            body:[TRRequestBuilder continueWithContext:[request URL] 
                                                                client:[YoutubeClientType webMobileClient]]];
        }


                                                            
    }
    [self makePOSTRequest:actualRequest 
               withParser:[self valueForKey:l(@"videoPageParser")] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForVideosWithStandardFeed:(int)requestingForInt categoryTerm:(NSString*)category uploadDate:(int)uploadFilter safeSearch:(int)safeSearch {
    // Map category to pre-defined playlist browse IDs
    // These are curated "trending" style playlists for each category
    NSString *browseId = @""; // default
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];

    if ([category isEqualToString:@"Games"]) {
        if (preferences[@"GamesBrowseId"]) {
            browseId = preferences[@"GamesBrowseId"];
        } else {
            browseId = @"VLPLKleUjYjNPFk";
        }
    } else if ([category isEqualToString:@"Film"]) {
        if (preferences[@"FilmBrowseId"]) {
            browseId = preferences[@"FilmBrowseId"];
        } else {
            browseId = @"VLPLQl1BIAhZO8E";
        }
    } else if ([category isEqualToString:@"Autos"]) {
        if (preferences[@"AutosBrowseId"]) {
            browseId = preferences[@"AutosBrowseId"];
        } else {
            browseId = @"VLPLBw4JXJysQ4s";
        }
    } else if ([category isEqualToString:@"Music"]) {
        if (preferences[@"MusicBrowseId"]) {
            browseId = preferences[@"MusicBrowseId"];
        } else {
            browseId = @"VLPLCiHOpZqcEeQ";
        }
    } else if ([category isEqualToString:@"Animals"]) {
        if (preferences[@"AnimalsBrowseId"]) {
            browseId = preferences[@"AnimalsBrowseId"];
        } else {
            browseId = @"VLPLSzKMzJ51-ts";
        }
    } else if ([category isEqualToString:@"Sports"]) {
        if (preferences[@"SportsBrowseId"]) {
            browseId = preferences[@"SportsBrowseId"];
        } else {
            browseId = @"VLPLT3_gZAgYD0A";
        }
    } else if ([category isEqualToString:@"Comedy"]) {
        if (preferences[@"ComedyBrowseId"]) {
            browseId = preferences[@"ComedyBrowseId"];
        } else {
            browseId = @"VLPLXIYrLoXbXbY";
        }
    } else if ([category isEqualToString:@"People"]) {
        if (preferences[@"PeopleBrowseId"]) {
            browseId = preferences[@"PeopleBrowseId"];
        } else {
            browseId = @"VLPLVm4sO2Q3j1I";
        }
    } else if ([category isEqualToString:@"News"]) {
        if (preferences[@"NewsBrowseId"]) {
            browseId = preferences[@"NewsBrowseId"];
        } else {
            browseId = @"VLPLZfbKlafuccI";
        }
    } else if ([category isEqualToString:@"Entertainment"]) {
        if (preferences[@"EntertainmentBrowseId"]) {
            browseId = preferences[@"EntertainmentBrowseId"];
        } else {
            browseId = @"VLPLaM7bIkoJFVs";
        }
    } else if ([category isEqualToString:@"Howto"]) {
        if (preferences[@"HowtoBrowseId"]) {
            browseId = preferences[@"HowtoBrowseId"];
        } else {
            browseId = @"VLPLZSHpCBcDPz8";
        }
    } else if ([category isEqualToString:@"Tech"]) {
        if (preferences[@"TechBrowseId"]) {
            browseId = preferences[@"TechBrowseId"];
        } else {
            browseId = @"VLPLTfc2mqePDSY";
        }
    } else if ([category isEqualToString:@"Travel"]) {
        if (preferences[@"TravelBrowseId"]) {
            browseId = preferences[@"TravelBrowseId"];
        } else {
            browseId = @"VLPLZKugeBmg4Wk";
        }
    } else if ([category isEqualToString:@"Education"]) {
        if (preferences[@"EducationBrowseId"]) {
            browseId = preferences[@"EducationBrowseId"];
        } else {
            browseId = @"";
        }
    } else if ([category isEqualToString:@"Nonprofit"]) {
        if (preferences[@"NonprofitBrowseId"]) {
            browseId = preferences[@"NonprofitBrowseId"];
        } else {
            browseId = @"VLPPLQYpFIOJv4Z4";
        }
    } else {
        // trending
        if (preferences[@"TrendingBrowseId"]) {
            browseId = preferences[@"TrendingBrowseId"];
        } else {
            browseId = @"VLPLbgMm37FwiYk";
        }
    }
    
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"];
    NSURL *fullURL = [urlBuilder URL];
    
    return [self requestWithURL:fullURL 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:browseId 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end


%hook YTGDataRequestFactory

-(id)requestForVideosWithStandardFeed:(int)requestingForInt categoryTerm:(NSString*)category uploadDate:(int)uploadFilter safeSearch:(int)safeSearch {
    // Map category to pre-defined playlist browse IDs
    // These are curated "trending" style playlists for each category
    NSString *browseId = @""; // default
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];

    if ([category isEqualToString:@"Games"]) {
        if (preferences[@"GamesBrowseId"]) {
            browseId = preferences[@"GamesBrowseId"];
        } else {
            browseId = @"VLPLKleUjYjNPFk";
        }
    } else if ([category isEqualToString:@"Film"]) {
        if (preferences[@"FilmBrowseId"]) {
            browseId = preferences[@"FilmBrowseId"];
        } else {
            browseId = @"VLPLQl1BIAhZO8E";
        }
    } else if ([category isEqualToString:@"Autos"]) {
        if (preferences[@"AutosBrowseId"]) {
            browseId = preferences[@"AutosBrowseId"];
        } else {
            browseId = @"VLPLBw4JXJysQ4s";
        }
    } else if ([category isEqualToString:@"Music"]) {
        if (preferences[@"MusicBrowseId"]) {
            browseId = preferences[@"MusicBrowseId"];
        } else {
            browseId = @"VLPLCiHOpZqcEeQ";
        }
    } else if ([category isEqualToString:@"Animals"]) {
        if (preferences[@"AnimalsBrowseId"]) {
            browseId = preferences[@"AnimalsBrowseId"];
        } else {
            browseId = @"VLPLSzKMzJ51-ts";
        }
    } else if ([category isEqualToString:@"Sports"]) {
        if (preferences[@"SportsBrowseId"]) {
            browseId = preferences[@"SportsBrowseId"];
        } else {
            browseId = @"VLPLT3_gZAgYD0A";
        }
    } else if ([category isEqualToString:@"Comedy"]) {
        if (preferences[@"ComedyBrowseId"]) {
            browseId = preferences[@"ComedyBrowseId"];
        } else {
            browseId = @"VLPLXIYrLoXbXbY";
        }
    } else if ([category isEqualToString:@"People"]) {
        if (preferences[@"PeopleBrowseId"]) {
            browseId = preferences[@"PeopleBrowseId"];
        } else {
            browseId = @"VLPLVm4sO2Q3j1I";
        }
    } else if ([category isEqualToString:@"News"]) {
        if (preferences[@"NewsBrowseId"]) {
            browseId = preferences[@"NewsBrowseId"];
        } else {
            browseId = @"VLPLZfbKlafuccI";
        }
    } else if ([category isEqualToString:@"Entertainment"]) {
        if (preferences[@"EntertainmentBrowseId"]) {
            browseId = preferences[@"EntertainmentBrowseId"];
        } else {
            browseId = @"VLPLaM7bIkoJFVs";
        }
    } else if ([category isEqualToString:@"Howto"]) {
        if (preferences[@"HowtoBrowseId"]) {
            browseId = preferences[@"HowtoBrowseId"];
        } else {
            browseId = @"VLPLZSHpCBcDPz8";
        }
    } else if ([category isEqualToString:@"Tech"]) {
        if (preferences[@"TechBrowseId"]) {
            browseId = preferences[@"TechBrowseId"];
        } else {
            browseId = @"VLPLTfc2mqePDSY";
        }
    } else if ([category isEqualToString:@"Travel"]) {
        if (preferences[@"TravelBrowseId"]) {
            browseId = preferences[@"TravelBrowseId"];
        } else {
            browseId = @"VLPLZKugeBmg4Wk";
        }
    } else if ([category isEqualToString:@"Education"]) {
        if (preferences[@"EducationBrowseId"]) {
            browseId = preferences[@"EducationBrowseId"];
        } else {
            browseId = @"";
        }
    } else if ([category isEqualToString:@"Nonprofit"]) {
        if (preferences[@"NonprofitBrowseId"]) {
            browseId = preferences[@"NonprofitBrowseId"];
        } else {
            browseId = @"VLPPLQYpFIOJv4Z4";
        }
    } else {
        // trending
        if (preferences[@"TrendingBrowseId"]) {
            browseId = preferences[@"TrendingBrowseId"];
        } else {
            browseId = @"VLPLbgMm37FwiYk";
        }
    }
    
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"];
    NSURL *fullURL = [urlBuilder URL];
    
    return [self requestWithURL:fullURL 
                 authentication:nil 
                           body:[TRRequestBuilder browseBodyWithId:browseId 
                                                            params:nil 
                                                            client:[YoutubeClientType webMobileClient]]];
}

%end

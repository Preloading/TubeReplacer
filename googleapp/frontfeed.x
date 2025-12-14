#include <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

/// Logged out standard fields

// -[YTVideoParser parseElement:error:]

// TO LOOK AT
// -[YTVideoParser parseElement:error:]


// called at -[YTCategoryViewController_iPhone loadView]


%hook YTGDataService

// convert from GET to POST
-(void)makeVideosStandardFeedRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    //cache:[self valueForKey:@"videoPageCache_"] 
  [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

%hook YTGDataRequest

+(id)requestForVideosWithStandardFeed:(int)requestingForInt categoryTerm:(NSString*)category uploadDate:(int)uploadFilter safeSearch:(int)a6
{
    // We really can't differenciate between these, oh well.
//   NSString *requestingFor = nil;
//   switch ( requestingForInt )
//   {
//     case 0:
//       requestingFor = @"most_viewed";
//       break;
//     case 1:
//       requestingFor = @"top_rated";
//       break;
//     case 2:
//       requestingFor = @"most_discussed";
//       break;
//     case 3:
//       requestingFor = @"top_favorites";
//       break;
//     case 4:
//       requestingFor = @"most_responded";
//       break;
//     case 5:
//       requestingFor = @"most_popular";
//       break;
//     case 6:
//       requestingFor = @"recently_featured";
//       break;
//     default:
//       break;
//   }

//   NSString *userCountryCode = [[YTUtils userCountryCode] uppercaseString];
  NSString *baseUrl = @"https://www.youtube.com/youtubei/v1/browse";
//   if ( [YTGDataRequest regionHasLocalizedStandardFeeds:userCountryCode])
//   {
//     baseUrl = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"standardfeeds/%@/%@",userCountryCode,requestingFor];
//   }
//   else
//   {
//     baseUrl = (NSString *)objc_msgSend(
//                             CFSTR("https://gdata.youtube.com/feeds/api/"),
//                             "stringByAppendingFormat:",
//                             CFSTR("standardfeeds/%@"),
//                             requestingFor);
//   }
//   if ([category length])
//     baseUrl = -[baseUrl stringByAppendingFormat:@"_%@", category];
    // some older, less fancy 

    // browseId = @"UCEgdi0XIXXZ-qJOFPf4JSKw"; // sports 
    // params = @"EglzcG9ydHN0YWKSAQMIwwY%3D";
    // browseId = @"UCEgdi0XIXXZ-qJOFPf4JSKw"; // music
    // params = @"EglzcG9ydHN0YWKSAQMIwwY%3D";
    NSString *browseId = @"VLPL-p0-Yh03xpi2AsCiyuafMeQrMF6czMoL";
    NSString *params = nil;
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
    } else if ([category isEqualToString:@"Games"]) {
        browseId = @"VLPL-p0-Yh03xpi_x9L-Lqop_Kj6MTY38jqv";
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

  GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:baseUrl];
//   [self setQueryParametersToURLBuilder:urlBuilder withSafeSearch:a6];
//   [self setUploadDateFilter:uploadFilter toURLBuilder:urlBuilder];
  NSURL *fullURL = [urlBuilder URL];
  return [self requestWithURL:fullURL authentication:nil body:[YoutubeRequestClient browseBody:browseId params:params]];
}

%end


/// -[YTPageParser parseElement:error:]
/// 


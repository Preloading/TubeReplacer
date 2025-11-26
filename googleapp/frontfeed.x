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
    NSString *browseId = @"VLPL-wWBMXXWHNIbxAJtIj0YU4H2zQkk-RAi";
    NSString *params = nil;
    if ([category isEqualToString:@"Games"]) {
        browseId = @"UCOpNcN46UbXVtpKMrmU4Abg";
        params = @"Egh0cmVuZGluZw%3D%3D";
    } else if ([category isEqualToString:@"Sports"]) {
        browseId = @"UCEgdi0XIXXZ-qJOFPf4JSKw";
        params = @"EglzcG9ydHN0YWKSAQMIwwY%3D";
    } else if ([category isEqualToString:@"Music"]) {
        browseId = @"UCEgdi0XIXXZ-qJOFPf4JSKw";
        params = @"EglzcG9ydHN0YWKSAQMIwwY%3D";
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


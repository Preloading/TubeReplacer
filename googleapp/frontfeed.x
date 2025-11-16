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
    NSString *browseId = @"";
    NSString *params = nil;
    if ([category isEqualToString:@"Games"]) {
        browseId = @"UCOpNcN46UbXVtpKMrmU4Abg";
        params = @"Egh0cmVuZGluZw%3D%3D";
    } else if ([category isEqualToString:@"Sports"]) {
        browseId = @"UCEgdi0XIXXZ-qJOFPf4JSKw";
        params = @"EglzcG9ydHN0YWKSAQMIwwY%3D";
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

@interface YTPage : NSObject
{
    NSArray *entries_;
    int totalResults_;
    int entriesPerPage_;
    int startIndex_;
    NSURL *nextURL_;
    NSURL *previousURL_;
}

- (id)previousURL;
- (id)nextURL;
- (int)startIndex;
- (int)entriesPerPage;
- (int)totalResults;
- (id)entries;
// - (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithEntries:(id)fp8 totalResults:(int)fp12 entriesPerPage:(int)fp16 startIndex:(int)fp20 nextURL:(id)fp24 previousURL:(id)fp28;

@end


%hook YTPageParser

-(id)parseElement:(id)body error:(NSError *)onError {
    NSMutableArray *videos = [NSMutableArray array];
    if ([body isKindOfClass:[NSDictionary class]] ) {
        NSArray *unparsedVideos = body[@"contents"][@"twoColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"][0][@"shelfRenderer"][@"content"][@"gridRenderer"][@"items"];
        if (!unparsedVideos) {
            NSLog(@"aaaaaaaaaaaaaaaaaaaa");
            unparsedVideos = body[@"contents"][@"twoColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"richGridRenderer"][@"contents"];
        }
        if (unparsedVideos) {
            // NSLog(@"aaaaaaaaaaaaaaaaaaaa2");
            for (NSDictionary *unparsedVideoFull in unparsedVideos) {
                // NSLog(@"aaaaaaaaaaaaaaaaaaaa3");
                NSDictionary *unparsedVideo = unparsedVideoFull[@"gridVideoRenderer"];
                // NSLog(@"aaaaaaaaaaaaaaaaaaaa4");
                if (!unparsedVideo) {
                    // NSLog(@"aaaaaaaaaaaaaaaaaaaa5");
                    unparsedVideo = unparsedVideoFull[@"richItemRenderer"][@"content"][@"videoRenderer"];
                }

                // NSLog(@"%@", unparsedVideo[@"videoId"] );

                // thumbnails
                NSMutableDictionary *thumbnails = [NSMutableDictionary new];
                NSDictionary *unparsedThumbnails = unparsedVideo[@"thumbnail"][@"thumbnails"];
                for (NSDictionary *unparsedThumbnail in unparsedThumbnails) {
                    [thumbnails setObject:[NSURL URLWithString:unparsedThumbnail[@"url"]] forKey:[NSValue valueWithBytes:&(CGSize){[unparsedThumbnail[@"height"] intValue],[unparsedThumbnail[@"width"] intValue]} objCType:@encode(CGSize)]];
                }

                // video length
                NSString *videoLengthText = unparsedVideo[@"thumbnailOverlays"][0][@"thumbnailOverlayTimeStatusRenderer"][@"text"][@"simpleText"];
                NSArray *videoLengthTextComponents = [[[videoLengthText componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
                long videoLengthInSeconds = 0;
                if (videoLengthTextComponents.count >= 1) { // seconds
                    videoLengthInSeconds += [videoLengthTextComponents[0] intValue];
                }
                if (videoLengthTextComponents.count >= 2) { // minutes
                    videoLengthInSeconds += [videoLengthTextComponents[1] intValue] * 60;
                }
                if (videoLengthTextComponents.count >= 3) { // hours
                    videoLengthInSeconds += [videoLengthTextComponents[2] intValue] * 3600;
                }
                if (videoLengthTextComponents.count >= 4) { // days
                    videoLengthInSeconds += [videoLengthTextComponents[3] intValue] * 86400;
                }

                NSString *viewsString = [[unparsedVideo[@"viewCountText"][@"simpleText"] stringByReplacingOccurrencesOfString:@" views" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""];

                NSDate *uploadedDate = YTTimeAgoToDate(unparsedVideo[@"publishedTimeText"][@"simpleText"]);

                [videos addObject:[[%c(YTVideo) alloc] initWithID:unparsedVideo[@"videoId"] 
                    title:unparsedVideo[@"title"][@"runs"][0][@"text"]
                    description:@"bitch" 
                    uploaderDisplayName:unparsedVideo[@"shortBylineText"][@"runs"][0][@"text"]
                    uploaderChannelID:unparsedVideo[@"shortBylineText"][@"runs"][0][@"navigationEndpoint"][@"browseEndpoint"][@"browseId"]
                    uploadedDate:uploadedDate
                    publishedDate:uploadedDate
                    duration:videoLengthInSeconds 
                    viewCount:[viewsString intValue]
                    likesCount:0 
                    dislikesCount:0 
                    state:[[%c(YTVideoState) alloc] initWithCode:0 reason:@""] 
                    streams:@[[NSURL URLWithString:@"https://example.com"]] 
                    thumbnailURLs:thumbnails
                    subtitlesTracksURL:[NSURL URLWithString:@"https://example.com"]
                    commentsAllowed:YES 
                    commentsURL:[NSURL URLWithString:@"https://example.com"]
                    commentsCountHint:0
                    relatedURL:[NSURL URLWithString:@"https://example.com"]
                    claimed:NO
                    monetized:NO 
                    monetizedCountries:@[] 
                    allowedCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"] 
                    deniedCountries:@[] 
                    categoryLabel:@"Gaming" // who knows!
                    categoryTerm:@"Games"  // who knows!
                    tags:@[]
                    adultContent:NO 
                    videoPro:nil
                ]];
            }
        }
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }

    
    
    
    // [NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"]
    YTPage *page = [[%c(YTPage) alloc] initWithEntries:videos totalResults:[videos count] entriesPerPage:[videos count] startIndex:1 nextURL:nil previousURL:nil]; // todo: actually have this paginate
    //     ,
    //     entries,
    //     totalResults,
    //     itemsPerPage,
    //     startIndex,
    //     nextURL,YTPage
    //     previousURL);
      return [page autorelease];
    // %log;
    // return nil;
}

%end
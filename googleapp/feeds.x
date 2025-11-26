#include <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"


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

// this is a big boy
%hook YTPageParser

-(id)parseElement:(id)body error:(NSError *)onError {
    NSMutableArray *videos = [NSMutableArray array];
    if ([body isKindOfClass:[NSDictionary class]] ) {

        NSArray *unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"][0][@"shelfRenderer"][@"content"][@"horizontalListRenderer"][@"items"]; // mobile Gaming
        if (!unparsedVideos) {
            NSLog(@"aaaaaaaaaaaaaaaaaaaa");
            unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"][0][@"playlistVideoListRenderer"][@"contents"]; // mobile Playlist
        }
        if (!unparsedVideos) {
            NSLog(@"aaaaaaaaaaaaaaaaaaaa");
            unparsedVideos = body[@"contents"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"]; // mobile search
        }
        if (unparsedVideos) {
            for (NSDictionary *unparsedVideoFull in unparsedVideos) {
                NSDictionary *unparsedVideo = unparsedVideoFull[@"gridVideoRenderer"];
                NSString *dataType = @"videoRenderer";
                if (!unparsedVideo) {
                    unparsedVideo = unparsedVideoFull[@"richItemRenderer"][@"content"][@"videoRenderer"];
                    dataType = @"videoRenderer";
                }
                if (!unparsedVideo) {
                    unparsedVideo = unparsedVideoFull[@"playlistVideoRenderer"];
                    dataType = @"playlistVideoRenderer";
                }
                if (!unparsedVideo) {
                    unparsedVideo = unparsedVideoFull[@"videoWithContextRenderer"];
                    dataType = @"videoWithContextRenderer";
                }
                if (!unparsedVideo) {
                    continue;
                }

                // NSLog(@"%@", unparsedVideo[@"videoId"] );

                // thumbnails
                NSMutableDictionary *thumbnails = [NSMutableDictionary new];
                NSDictionary *unparsedThumbnails = unparsedVideo[@"thumbnail"][@"thumbnails"];
                for (NSDictionary *unparsedThumbnail in unparsedThumbnails) {
                    [thumbnails setObject:[NSURL URLWithString:unparsedThumbnail[@"url"]] forKey:[NSValue valueWithBytes:&(CGSize){[unparsedThumbnail[@"height"] intValue],[unparsedThumbnail[@"width"] intValue]} objCType:@encode(CGSize)]];
                }

                // video length
                NSString *videoLengthText = unparsedVideo[@"lengthText"][@"runs"][0][@"text"];
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

                long views = 0;
                if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                    views = YTTextToNumber(unparsedVideo[@"shortViewCountText"][@"runs"][0][@"text"]); // TODO: This can be more precise if we use the accessibilty data.
                } else if ([dataType isEqualToString:@"playlistVideoRenderer"])  {
                    views = YTTextToNumber(unparsedVideo[@"videoInfo"][@"runs"][0][@"text"]); // TODO: This can be more precise if we use the accessibilty data. 
                } else {
                    views = [[[unparsedVideo[@"viewCountText"][@"runs"][0][@"text"] stringByReplacingOccurrencesOfString:@" views" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
                }

                NSDate *uploadedDate = nil;
                if ([dataType isEqualToString:@"playlistVideoRenderer"])  {
                    uploadedDate = YTTimeAgoToDate(unparsedVideo[@"videoInfo"][@"runs"][2][@"text"]); // TODO: Some accessiblity data has more precise time, we should use that instead
                } else {
                    uploadedDate = YTTimeAgoToDate(unparsedVideo[@"publishedTimeText"][@"runs"][0][@"text"]); // TODO: Some accessiblity data has more precise time, we should use that instead
                }

                NSString *title = @"";
                if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                    title = unparsedVideo[@"headline"][@"runs"][0][@"text"];
                } else {
                    title = unparsedVideo[@"title"][@"runs"][0][@"text"];
                }
                

                [videos addObject:[[%c(YTVideo) alloc] initWithID:unparsedVideo[@"videoId"] 
                    title:title
                    description:@"" 
                    uploaderDisplayName:unparsedVideo[@"shortBylineText"][@"runs"][0][@"text"]
                    uploaderChannelID:unparsedVideo[@"shortBylineText"][@"runs"][0][@"navigationEndpoint"][@"browseEndpoint"][@"browseId"]
                    uploadedDate:uploadedDate
                    publishedDate:uploadedDate
                    duration:videoLengthInSeconds 
                    viewCount:views
                    likesCount:0 
                    dislikesCount:0 
                    state:[[%c(YTVideoState) alloc] initWithCode:0 reason:@""] 
                    streams:@[[NSURL URLWithString:@"https://example.com/badstream"]] 
                    thumbnailURLs:thumbnails
                    subtitlesTracksURL:[NSURL URLWithString:@"https://example.com/badsubtitles"]
                    commentsAllowed:YES 
                    commentsURL:[NSURL URLWithString:@"https://example.com/badcomments"]
                    commentsCountHint:0
                    relatedURL:[NSURL URLWithString:@"https://example.com/badrelatedurl"]
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
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
// handles parsing of alllll the feeds we can get.

@interface YTPageParser : NSObject
+(id)parseLockupViewModelVideo:(NSDictionary*)unparsedVideo;
@end

%hook YTPageParser


// old just in case i wanna use this again.
%new
+(id)parseLockupViewModelVideo:(NSDictionary*)unparsedVideo {
    return [[%c(YTVideo) alloc] initWithID:unparsedVideo[@"contentId"] 
                title:unparsedVideo[@"metadata"][@"lockupMetadataViewModel"][@"title"][@"content"]
                description:@"" 
                uploaderDisplayName:@"penis"
                uploaderChannelID:@"channelId"
                uploadedDate:[NSDate date]
                publishedDate:[NSDate date]
                duration:6969 
                viewCount:6969420
                likesCount:0 
                dislikesCount:0 
                state:[[%c(YTVideoState) alloc] initWithCode:0 reason:@""] 
                streams:@[[NSURL URLWithString:@"https://example.com/badstream"]] 
                thumbnailURLs:@[]
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
            ];
}

-(id)parseElement:(id)body error:(NSError **)error {
    NSMutableArray *output = [NSMutableArray array];
    if ([body isKindOfClass:[NSDictionary class]] ) {
        // proper page implementation, since i did this badly

        if (!([[self valueForKey:@"entryParser_"] isKindOfClass:[%c(YTVideoParser) class]] || [[self valueForKey:@"entryParser_"] isKindOfClass:[%c(YTChannelParser) class]])) { // this is here to avoid me having to rewrite a lot of code right now.
            NSArray *unparsedData = nil;
            NSDictionary *bodyDict = body;
            if ([[self valueForKey:@"entryParser_"] isKindOfClass:[%c(YTSubscriptionParser) class]]) {
                unparsedData = bodyDict[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"shelfRenderer"][@"content"][@"verticalListRenderer"][@"items"];
            }
            if ([[self valueForKey:@"entryParser_"] isKindOfClass:[%c(YTCommentParser) class]]) {
                unparsedData = bodyDict[@"onResponseReceivedEndpoints"][1][@"reloadContinuationItemsCommand"][@"continuationItems"];
            }
            NSLog(@"unparsed data count -> %lu",(unsigned long) [unparsedData count]);
            for (id i in unparsedData) {
                if (i[@"continuationItemRenderer"]) {
                    continue;
                }
                YTTBParser *parser = [self valueForKey:@"entryParser_"];
                NSError *parseError = nil;
                id entry = [parser parseElement:@{@"i":i,@"all":unparsedData} error:&parseError];
                if ( parseError ) {
                    NSLog(@"fuck");
                    break;
                    
                }
                    
                if ( entry )
                    [output addObject:entry];
            }
        } else {

            NSArray *unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"][0][@"shelfRenderer"][@"content"][@"horizontalListRenderer"][@"items"]; // mobile Gaming
            if (!unparsedVideos) { // history
                if ([body[@"responseContext"][@"serviceTrackingParams"][0][@"params"][0][@"value"] isEqualToString:@"FEhistory"]) {
                    // History is wierd, it's seperated by the date.
                    unparsedVideos = @[];
                    for (NSDictionary *section in body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"]) {
                        if (section[@"continuationItemRenderer"]) {
                            continue; // we don't wanna do this to the pagination data
                        }

                        unparsedVideos = [unparsedVideos arrayByAddingObjectsFromArray:section[@"itemSectionRenderer"][@"contents"]];
                    }
                }
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"][0][@"playlistVideoListRenderer"][@"contents"]; // mobile Playlist
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][0][@"tabRenderer"][@"content"][@"sectionListRenderer"][@"contents"];
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"singleColumnBrowseResultsRenderer"][@"tabs"][1][@"tabRenderer"][@"content"][@"richGridRenderer"][@"contents"]; // mobile channel videos
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"sectionListRenderer"][@"contents"][0][@"itemSectionRenderer"][@"contents"]; // mobile search
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"singleColumnWatchNextResults"][@"results"][@"results"][@"contents"][3][@"itemSectionRenderer"][@"contents"]; // mobile suggestions
            }
            if (!unparsedVideos) {
                unparsedVideos = body[@"contents"][@"twoColumnWatchNextResults"][@"secondaryResults"][@"secondaryResults"][@"results"][1][@"itemSectionRenderer"][@"contents"]; // desktop suggestions
            }
            NSLog(@"youtube parsdign  of videos@!!!!");
            if (unparsedVideos) {
                for (NSDictionary *unparsedVideoFull in unparsedVideos) {
                    // NSLog(@"unparsedVideo: %@", unparsedVideoFull);
                    NSDictionary *unparsedVideo = unparsedVideoFull[@"gridVideoRenderer"];
                    NSString *dataType = @"videoRenderer";
                    NSString *mediaType = @""; // VIDEO or CHANNEL
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"richItemRenderer"][@"content"][@"videoRenderer"];
                        dataType = @"videoRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"playlistVideoRenderer"];
                        dataType = @"playlistVideoRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"videoWithContextRenderer"];
                        dataType = @"videoWithContextRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"richItemRenderer"][@"content"][@"videoWithContextRenderer"];
                        dataType = @"videoWithContextRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"compactChannelRenderer"];
                        dataType = @"compactChannelRenderer";
                        mediaType = @"CHANNEL";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"itemSectionRenderer"][@"contents"][0][@"compactVideoRenderer"];
                        dataType = @"videoRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"lockupViewModel"];
                        dataType = @"lockupViewModel";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        unparsedVideo = unparsedVideoFull[@"compactVideoRenderer"];
                        dataType = @"videoRenderer";
                        mediaType = @"VIDEO";
                    }
                    if (!unparsedVideo) {
                        continue;
                    }

                    if ([dataType isEqualToString:@"lockupViewModel"]) {
                        [output addObject:[%c(YTPageParser) parseLockupViewModelVideo:unparsedVideo]];
                        continue;
                    }

                    NSLog(@"videocheck1");

                    // NSLog(@"%@", unparsedVideo[@"videoId"] );

                    if ([mediaType isEqualToString:@"VIDEO"]) {
                        NSLog(@"videocheck2");
                        // is the video even available?
                        if ([dataType isEqualToString:@"playlistVideoRenderer"])  {
                            if (!([unparsedVideo[@"videoInfo"][@"runs"] count] >= 2)) {
                                NSLog(@"bad video");
                                continue;
                            }
                        } //else if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                            // suggestions  
                        // } else {
                        //     if (!(unparsedVideo[@"publishedTimeText"][@"runs"][0])) {
                        //         NSLog(@"bad video (2)");
                        //         continue;
                        //     }
                        // }

                        // thumbnails
                        NSMutableDictionary *thumbnails = [NSMutableDictionary new];
                        NSDictionary *unparsedThumbnails = unparsedVideo[@"thumbnail"][@"thumbnails"];
                        for (NSDictionary *unparsedThumbnail in unparsedThumbnails) {
                            [thumbnails setObject:[NSURL URLWithString:unparsedThumbnail[@"url"]] forKey:[NSValue valueWithBytes:&(CGSize){[unparsedThumbnail[@"height"] intValue],[unparsedThumbnail[@"width"] intValue]} objCType:@encode(CGSize)]];
                        }
                        NSLog(@"videocheck3");

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
                        NSLog(@"videocheck4");

                        // for later me accessibility looks like
                        // Pasis - Tonton Malele by Tonton Malele 35,908 views 5 days ago 4 minutes, 20 seconds
                        // find a way to parse this!

                        NSString *title = @"";
                        if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                            title = unparsedVideo[@"headline"][@"runs"][0][@"text"];
                        } else {
                            title = unparsedVideo[@"title"][@"runs"][0][@"text"];
                        }

                        NSLog(@"videocheck5");

                        NSString *uploaderDisplayName = unparsedVideo[@"shortBylineText"][@"runs"][0][@"text"];
                        if (!uploaderDisplayName) {
                            uploaderDisplayName = body[@"header"][@"pageHeaderRenderer"][@"pageTitle"]; // channel videos
                        }

                        NSLog(@"videocheck6");

                        NSArray *accessibilityParts = nil; 
                        if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                            NSLog(@"accessiblity -> %@", unparsedVideo[@"headline"][@"accessibility"][@"accessibilityData"][@"label"]);
                            accessibilityParts = [unparsedVideo[@"headline"][@"accessibility"][@"accessibilityData"][@"label"] componentsSeparatedByString:@" "];
                            for (NSString *part in accessibilityParts) {
                                NSLog(@"accessibilityParts contains %@", part);
                            }
                        } else {
                            NSLog(@"accessiblity -> %@", unparsedVideo[@"title"][@"accessibility"][@"accessibilityData"][@"label"]);
                            accessibilityParts = [unparsedVideo[@"title"][@"accessibility"][@"accessibilityData"][@"label"] componentsSeparatedByString:@" "];
                        }
                        int removedParts = [[title componentsSeparatedByString:@" "] count] + 1 + [[uploaderDisplayName componentsSeparatedByString:@" "] count] -1; // This includes stuff like the title and diplay name which we already have, and since they can have spaces, we just filter them out here.
                        //                           title                                    by                 display name                                  index stuff
                        NSLog(@"videocheck7");

                        long views = 0;
                        if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
                            NSLog(@"views -> %@", [accessibilityParts[removedParts + 1] stringByReplacingOccurrencesOfString:@"," withString:@""]);
                            views = [[accessibilityParts[removedParts + 1] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
                            // views = YTTextToNumber(unparsedVideo[@"shortViewCountText"][@"runs"][0][@"text"]); 
                        } else if ([dataType isEqualToString:@"playlistVideoRenderer"])  {
                            // views = YTTextToNumber(unparsedVideo[@"videoInfo"][@"runs"][0][@"text"]); 
                            views = [[accessibilityParts[removedParts + 1] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
                        } else {
                            views = [[[unparsedVideo[@"viewCountText"][@"runs"][0][@"text"] stringByReplacingOccurrencesOfString:@" views" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue]; // precise
                        }

                        NSLog(@"videocheck8");

                        // this is *technically* wrong for suggestions, but it's not shown either way, so who cares!
                        NSDate *uploadedDate = nil;
                        NSString *uploadDateString = @"";
                        for (int i = 0; i < [accessibilityParts count] - (removedParts + 3); i++) {
                            uploadDateString = [NSString stringWithFormat:@"%@%@ ", uploadDateString, [accessibilityParts[removedParts + 3 + i] stringByReplacingOccurrencesOfString:@"," withString:@""]];
                        }


                        NSLog(@"maybe upload date = %@", uploadDateString);
                        uploadedDate = YTTimeAgoToDate(uploadDateString);
                        // if ([dataType isEqualToString:@"playlistVideoRenderer"])  {
                        //     // uploadedDate = YTTimeAgoToDate(unparsedVideo[@"videoInfo"][@"runs"][2][@"text"]);
                        // } else {
                        //     // uploadedDate = YTTimeAgoToDate(unparsedVideo[@"publishedTimeText"][@"runs"][0][@"text"]);
                        // }

                        NSLog(@"video");
                        

                        [output addObject:[[%c(YTVideo) alloc] initWithID:unparsedVideo[@"videoId"] 
                            title:title
                            description:@"" 
                            uploaderDisplayName:uploaderDisplayName
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
                            commentsURL:unparsedVideo[@"videoId"] 
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
                    } else if ([mediaType isEqualToString:@"CHANNEL"]) {
                        NSString *displayName = unparsedVideo[@"displayName"][@"runs"][0][@"text"];
                        
                        NSArray *accessibilityParts = [unparsedVideo[@"title"][@"accessibility"][@"accessibilityData"][@"label"] componentsSeparatedByString:@" "];
                        int removedParts = [[displayName componentsSeparatedByString:@" "] count] -1; // This includes stuff like the title and diplay name which we already have, and since they can have spaces, we just filter them out here.

                        [output addObject:[[[%c(YTChannel) alloc] initWithDisplayName:displayName
                            channelID:unparsedVideo[@"channelId"]
                            summary:@"summary"
                            updated:[NSDate date] // todo: we aren't provided this, but since this is way overkill, we can get the latest video as the date
                            videoCount:YTTextToNumber(accessibilityParts[removedParts + 1])
                            thumbnailURL:[NSURL URLWithString:[NSString stringWithFormat:@"https:%@", unparsedVideo[@"thumbnail"][@"thumbnails"][0][@"url"]]]
                            subscribersCount:YTTextToNumber(unparsedVideo[@"videoCountText"][@"runs"][0][@"text"])
                        ] autorelease]];
                    }
                }
            }
        }
    } else {
        NSLog(@"PANIK WE DIDNT GET JSON!|!!!!!");
        return nil;
    }

    
    
    
    // [NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"]
    YTPage *page = [[%c(YTPage) alloc] initWithEntries:output totalResults:[output count] entriesPerPage:[output count] startIndex:1 nextURL:nil previousURL:nil]; // todo: actually have this paginate
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
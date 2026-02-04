// TRVideoTranslator.m
// TubeReplacer
//
// Video translator implementation
// Handles both player responses and feed items

#import "TRVideoTranslator.h"
#import "TRJSONUtils.h"
#import <objc/runtime.h>
#import "../appheaders.h"

@implementation TRVideoTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeVideo;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    if ([json objectForKey:@"videoDetails"]) {
        return YES;
    }
    if (json[@"videoRenderer"] ||
        json[@"compactVideoRenderer"] ||
        json[@"gridVideoRenderer"] ||
        json[@"playlistVideoRenderer"] ||
        json[@"videoWithContextRenderer"] ||
        json[@"lockupViewModel"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoRenderer"] ||
        [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoWithContextRenderer"]) {
        return YES;
    }
    
    if ([TRJSONUtils dictFromJSON:json keyPath:@"itemSectionRenderer.contents[0].compactVideoRenderer"]) {
        return YES;
    }
    return NO;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRVideoTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    if (json[@"videoDetails"]) {
        return [self translatePlayerResponse:json error:error];
    }
    
    return [self translateFeedItem:json withContext:nil error:error];
}

#pragma mark - Player Response (Full Video Details)

- (id)translatePlayerResponse:(NSDictionary *)json error:(NSError **)error {
    NSString *videoId = [TRJSONUtils stringFromJSON:json keyPath:@"videoDetails.videoId"];
    
    if (!videoId) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRVideoTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing videoId"}];
        }
        return nil;
    }
    
    NSArray *thumbArray = [TRJSONUtils arrayFromJSON:json keyPath:@"videoDetails.thumbnail.thumbnails"];
    NSDictionary *thumbnails = [TRJSONUtils thumbnailsFromArray:thumbArray];
    
    NSMutableArray *ytStreams = [NSMutableArray array];
    NSArray *formats = [TRJSONUtils arrayFromJSON:json keyPath:@"streamingData.formats"];
    for (NSDictionary *format in formats) {
        NSString *urlString = format[@"url"];
        if (urlString) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                id stream = [NSClassFromString(@"YTStream") streamWithURL:url format:3 encrypted:NO];
                if (stream) {
                    [ytStreams addObject:stream];
                }
            }
        }
    }
    
    NSMutableArray *availableCountries = [NSMutableArray array];
    NSArray *countries = [TRJSONUtils arrayFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.availableCountries"];
    for (NSString *country in countries) {
        if ([country isKindOfClass:[NSString class]]) {
            [availableCountries addObject:[country lowercaseString]];
        }
    }
    
    NSString *uploadDateStr = [TRJSONUtils stringFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.uploadDate"];
    NSString *publishDateStr = [TRJSONUtils stringFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.publishDate"];
    NSDate *uploadDate = [TRJSONUtils dateFromRFC3339:uploadDateStr];
    NSDate *publishDate = [TRJSONUtils dateFromRFC3339:publishDateStr];
    
    uint64_t duration = [TRJSONUtils intFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.lengthSeconds"];
    uint64_t viewCount = [TRJSONUtils intFromJSON:json keyPath:@"videoDetails.viewCount"];
    uint64_t likesCount = [TRJSONUtils intFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.likeCount"];
    
    NSString *category = [TRJSONUtils stringFromJSON:json keyPath:@"microformat.playerMicroformatRenderer.category"];
    
    id videoState = [[NSClassFromString(@"YTVideoState") alloc] initWithCode:0 reason:@""];
    
    id video = [[NSClassFromString(@"YTVideo") alloc] 
        initWithID:videoId
        title:[TRJSONUtils stringFromJSON:json keyPath:@"videoDetails.title"]
        description:[TRJSONUtils stringFromJSON:json keyPath:@"videoDetails.shortDescription"]
        uploaderDisplayName:[TRJSONUtils stringFromJSON:json keyPath:@"videoDetails.author"]
        uploaderChannelID:[TRJSONUtils stringFromJSON:json keyPath:@"videoDetails.channelId"]
        uploadedDate:uploadDate
        publishedDate:publishDate
        duration:duration
        viewCount:viewCount
        likesCount:likesCount
        dislikesCount:0
        state:videoState
        streams:ytStreams
        thumbnailURLs:thumbnails
        subtitlesTracksURL:nil
        commentsAllowed:YES
        commentsURL:videoId
        commentsCountHint:0
        relatedURL:videoId
        claimed:NO
        monetized:NO
        monetizedCountries:@[]
        allowedCountries:availableCountries
        deniedCountries:@[]
        categoryLabel:@"Gaming"
        categoryTerm:category ?: @"Unknown"
        tags:@[]
        adultContent:NO
        videoPro:nil];
    
    [videoState release];
    
    return video;
}

#pragma mark - Feed Item (Minimal Video Details from Feed)

- (id)translateFeedItem:(NSDictionary *)json 
            withContext:(NSDictionary *)context 
                  error:(NSError **)error {
    
    // Unwrap the video data from various container formats
    NSDictionary *videoData = [self unwrapVideoData:json];
    NSString *dataType = [self detectDataType:json];
    
    if (!videoData) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRVideoTranslator" code:3 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Could not find video data"}];
        }
        return nil;
    }
    
    // Skip upcoming/scheduled videos
    if (videoData[@"upcomingEventData"]) {
        return nil;
    }
    
    NSString *videoId = videoData[@"videoId"];
    if (!videoId) {
        return nil;
    }
    
    // Title - different path for videoWithContextRenderer
    NSString *title = nil;
    if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
        title = [TRJSONUtils stringFromJSON:videoData keyPath:@"headline.runs[0].text"];
    } else {
        title = [TRJSONUtils stringFromJSON:videoData keyPath:@"title.runs[0].text"];
    }
    if (!title) title = @"";
    
    // Uploader display name
    NSString *uploaderName = [TRJSONUtils stringFromJSON:videoData keyPath:@"shortBylineText.runs[0].text"];
    if (!uploaderName && context) {
        // For channel videos, get from page header
        uploaderName = [TRJSONUtils stringFromJSON:context keyPath:@"header.pageHeaderRenderer.pageTitle"];
    }
    if (!uploaderName) uploaderName = @"";
    
    // Channel ID
    NSString *channelId = [TRJSONUtils stringFromJSON:videoData 
                                              keyPath:@"shortBylineText.runs[0].navigationEndpoint.browseEndpoint.browseId"];
    
    // Thumbnails 
    NSArray *thumbArray = [TRJSONUtils arrayFromJSON:videoData keyPath:@"thumbnail.thumbnails"];
    NSDictionary *thumbnails = [TRJSONUtils thumbnailsFromArray:thumbArray];
    
    // Duration from lengthText
    NSString *durationText = [TRJSONUtils stringFromJSON:videoData keyPath:@"lengthText.runs[0].text"];
    long duration = [TRJSONUtils secondsFromDurationText:durationText];
    
    // === CRITICAL: Views and Date from Accessibility Label ===
    // The accessibility label has format:
    // "Video Title by Channel Name 35,908 views 5 days ago 4 minutes, 20 seconds"
    
    uint64_t views = 0;
    NSDate *uploadDate = nil;
    
    // Get accessibility label based on renderer type
    NSString *accessibilityLabel = nil;
    if ([dataType isEqualToString:@"videoWithContextRenderer"]) {
        accessibilityLabel = [TRJSONUtils stringFromJSON:videoData 
                                                 keyPath:@"headline.accessibility.accessibilityData.label"];
    } else {
        accessibilityLabel = [TRJSONUtils stringFromJSON:videoData 
                                                 keyPath:@"title.accessibility.accessibilityData.label"];
    }

    NSLog(@"accessiblity label -> %@", accessibilityLabel);
    
    if (accessibilityLabel && [accessibilityLabel length] > 0) {
        // Parse accessibility label for views and date
        // Instead of calculating word positions, search for "views" keyword
        NSArray *accessibilityParts = [accessibilityLabel componentsSeparatedByString:@" "];
        
        // Find the index of "views" keyword
        NSInteger viewsIndex = NSNotFound;
        for (NSInteger i = 0; i < [accessibilityParts count]; i++) {
            if ([[accessibilityParts[i] lowercaseString] isEqualToString:@"views"]) {
                viewsIndex = i;
                break;
            }
        }
        
        if (viewsIndex != NSNotFound && viewsIndex > 0) {
            // The views count is the word before "views"
            NSString *viewsPart = accessibilityParts[viewsIndex - 1];
            viewsPart = [viewsPart stringByReplacingOccurrencesOfString:@"," withString:@""];
            views = [viewsPart longLongValue];
            
            // Extract upload date (remaining words after "views")
            // Format: "5 days ago" or "3 weeks ago" etc.
            if ([accessibilityParts count] > viewsIndex + 1) {
                NSMutableString *dateString = [NSMutableString string];
                for (NSInteger i = viewsIndex + 1; i < [accessibilityParts count]; i++) {
                    NSString *part = accessibilityParts[i];
                    // Stop if we hit the duration part (contains "minute" or "second")
                    if ([part rangeOfString:@"minute" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [part rangeOfString:@"second" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [part rangeOfString:@"hour" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        break;
                    }
                    part = [part stringByReplacingOccurrencesOfString:@"," withString:@""];
                    [dateString appendFormat:@"%@ ", part];
                }
                uploadDate = [TRJSONUtils dateFromTimeAgo:dateString];
            }
        }
    } else {
        // Fallback: try direct viewCountText path
        NSString *viewText = [TRJSONUtils stringFromJSON:videoData keyPath:@"viewCountText.runs[0].text"];
        if (!viewText) {
            viewText = [TRJSONUtils stringFromJSON:videoData keyPath:@"viewCountText.simpleText"];
        }
        if (viewText) {
            viewText = [viewText stringByReplacingOccurrencesOfString:@" views" withString:@""];
            viewText = [viewText stringByReplacingOccurrencesOfString:@"," withString:@""];
            views = [viewText intValue];
        }
        
        // Fallback: try publishedTimeText
        NSString *timeAgo = [TRJSONUtils stringFromJSON:videoData keyPath:@"publishedTimeText.runs[0].text"];
        if (!timeAgo) {
            timeAgo = [TRJSONUtils stringFromJSON:videoData keyPath:@"publishedTimeText.simpleText"];
        }
        if (timeAgo) {
            uploadDate = [TRJSONUtils dateFromTimeAgo:timeAgo];
        }
    }
    
    if (!uploadDate) {
        uploadDate = [NSDate date];
    }
    
    id videoState = [[NSClassFromString(@"YTVideoState") alloc] initWithCode:0 reason:@""];
    
    // Default allowed countries
    NSArray *defaultCountries = @[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", 
                                   @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", 
                                   @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", 
                                   @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", 
                                   @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", 
                                   @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", 
                                   @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"];
    NSLog(@"views -> %llu", views);
    id video = [[NSClassFromString(@"YTVideo") alloc] 
        initWithID:videoId
        title:title
        description:@""
        uploaderDisplayName:uploaderName
        uploaderChannelID:channelId ?: @""
        uploadedDate:uploadDate
        publishedDate:uploadDate
        duration:duration
        viewCount:views
        likesCount:0
        dislikesCount:0
        state:videoState
        streams:@[]
        thumbnailURLs:thumbnails
        subtitlesTracksURL:nil
        commentsAllowed:YES
        commentsURL:videoId
        commentsCountHint:0
        relatedURL:videoId
        claimed:NO
        monetized:NO
        monetizedCountries:@[]
        allowedCountries:defaultCountries
        deniedCountries:@[]
        categoryLabel:@"Gaming"
        categoryTerm:@"Unknown"
        tags:@[]
        adultContent:NO
        videoPro:nil];
    
    [videoState release];
    
    return video;
}

#pragma mark - Helpers

- (NSDictionary *)unwrapVideoData:(NSDictionary *)json {
    NSDictionary *result = [json objectForKey:@"videoRenderer"];
    if (result) return result;
    
    result = [json objectForKey:@"compactVideoRenderer"];
    if (result) return result;
    
    result = [json objectForKey:@"gridVideoRenderer"];
    if (result) return result;
    
    result = [json objectForKey:@"playlistVideoRenderer"];
    if (result) return result;
    
    result = [json objectForKey:@"videoWithContextRenderer"];
    if (result) return result;
    
    result = [json objectForKey:@"lockupViewModel"];
    if (result) return result;
    
    // Nested in richItemRenderer
    result = [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoRenderer"];
    if (result) return result;
    
    result = [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoWithContextRenderer"];
    if (result) return result;
    
    // Nested in itemSectionRenderer
    result = [TRJSONUtils dictFromJSON:json keyPath:@"itemSectionRenderer.contents[0].compactVideoRenderer"];
    if (result) return result;
    
    return nil;
}

- (NSString *)detectDataType:(NSDictionary *)json {
    if ([json objectForKey:@"videoRenderer"]) return @"videoRenderer";
    if ([json objectForKey:@"compactVideoRenderer"]) return @"videoRenderer";
    if ([json objectForKey:@"gridVideoRenderer"]) return @"gridVideoRenderer";
    if ([json objectForKey:@"playlistVideoRenderer"]) return @"playlistVideoRenderer";
    if ([json objectForKey:@"videoWithContextRenderer"]) return @"videoWithContextRenderer";
    if ([json objectForKey:@"lockupViewModel"]) return @"lockupViewModel";
    if ([TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoRenderer"]) return @"videoRenderer";
    if ([TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoWithContextRenderer"]) return @"videoWithContextRenderer";
    return @"unknown";
}

#pragma mark - Video Enhancement (/next response)

- (void)enhanceVideo:(id)video withNextResponse:(NSDictionary *)nextData {
    if (!video || !nextData || !nextData[@"next"]) return;
    
    @try {
        

        // Navigate to the like button data in /next response
        NSDictionary *resultContents = nextData[@"next"][@"contents"][@"singleColumnWatchNextResults"][@"results"][@"results"][@"contents"];
        

        BOOL hasLikeDataAlready = false;
        if (nextData[@"dislikes"]) {
            [video setValue:nextData[@"dislikes"][@"dislikes"] forKey:@"dislikesCount_"];
            [video setValue:nextData[@"dislikes"][@"likes"] forKey:@"likesCount_"];
            // NSLog(@"date -> %@", [TRJSONUtils dateFromISO8601:nextData[@"dislikes"][@"dateCreated"]]);
            // [video setValue:[TRJSONUtils dateFromISO8601:nextData[@"dislikes"][@"dateCreated"]] forKey:@"uploadedDate_"];
            // [video setValue:[TRJSONUtils dateFromISO8601:nextData[@"dislikes"][@"dateCreated"]] forKey:@"publishedDate_"];
            hasLikeDataAlready = true;
        }


        if (![resultContents isKindOfClass:[NSArray class]]) return;

        for (NSDictionary *item in resultContents) {
            NSDictionary *metaContents = item[@"slimVideoMetadataSectionRenderer"][@"contents"];    
            if (![metaContents isKindOfClass:[NSArray class]]) continue;
            for (NSDictionary *metaItem in metaContents) {
                NSDictionary *actionBar = metaItem[@"slimVideoActionBarRenderer"];
                if (!actionBar) continue;
                
                NSArray *buttons = actionBar[@"buttons"];
                if (![buttons isKindOfClass:[NSArray class]]) continue;
                
                for (NSDictionary *buttonItem in buttons) {
                    NSDictionary *smbr = [buttonItem objectForKey:@"slimMetadataButtonRenderer"];
                    if (!smbr) continue;
                    
                    NSDictionary *sldbvm = [[smbr objectForKey:@"button"] objectForKey:@"segmentedLikeDislikeButtonViewModel"];
                    if (!sldbvm) continue;
                    
                    // Extract like status
                    NSDictionary *likeButtonVM = [sldbvm objectForKey:@"likeButtonViewModel"];
                    NSString *status = likeButtonVM[@"likeStatusEntity"][@"likeStatus"];
                    
                    // todo dislikes
                    if (status) {
                        objc_setAssociatedObject(video, "TRLikeStatus", status, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    }

                    NSString *dateString = nextData[@"next"][@"engagementPanels"][2][@"engagementPanelSectionListRenderer"][@"content"][@"structuredDescriptionContentRenderer"][@"items"][0][@"videoDescriptionHeaderRenderer"][@"publishDate"][@"runs"][0][@"text"];
                    NSDate *date = [TRJSONUtils dateFromShortDate:dateString];
                    [video setValue:date forKey:@"uploadedDate_"];
                    [video setValue:date forKey:@"publishedDate_"];

                    if (!hasLikeDataAlready) {
                        // Extract like count
                        NSString *accessibilityText = likeButtonVM[@"likeButtonViewModel"][@"toggleButtonViewModel"][@"toggleButtonViewModel"][@"defaultButtonViewModel"][@"buttonViewModel"][@"accessibilityText"];

                        if (accessibilityText) { 
                            NSArray *accessibilityTextContent = [accessibilityText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            long likes = [TRJSONUtils numberFromText:accessibilityTextContent[5]];
                            if (likes > 0) {
                                [video setValue:[NSNumber numberWithLong:likes] forKey:@"likesCount_"];
                            }
                        }
                    }
                    return;
                }
            }
        }
        
        
    } @catch (NSException *e) {
        NSLog(@"TRVideoTranslator: Failed to enhance video: %@", e);
    }
}

@end

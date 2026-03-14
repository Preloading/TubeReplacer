// TRVideoTranslator.m
// TubeReplacer
//
// Video translator implementation
// Handles both player responses and feed items

#import "TRVideoTranslator.h"
#import "TRJSONUtils.h"
#import <objc/runtime.h>
#import "../appheaders.h"
#import "../../base64/NSString+Base64.h"
#import "../../base64/NSData+Base64.h"
#import "../general.h"

@implementation TRVideoTranslator

// this should really be in a seperate file but idc right now
+ (NSString *)uuid {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

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
        [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.videoWithContextRenderer"] ||
        [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.compactVideoRenderer"]) {
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
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if (!([preferences[@"StreamType"] isEqualToString:@"custom"] || [preferences[@"StreamType"] isEqualToString:@"tuberepair"]) ) {
        NSString *hlsStreamURL = [TRJSONUtils stringFromJSON:json keyPath:@"streamingData.hlsManifestUrl"];
        if (hlsStreamURL) {
            // this sux, it gives me fucking dubbed feeds, so i get to select the dubbed one out.
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:hlsStreamURL]];
            NSURLResponse *response = nil;
            NSError *error = nil;

            // This call blocks the thread
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response
                                                            error:&error];

            if (data != nil && error == nil) {
                // Handle success
                // data:application/vnd.apple.mpegurl;base64,
                NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                // Parse the M3U8 to remove bad audio :)
                NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
                NSArray *elements = [result componentsSeparatedByCharactersInSet:separator];
                NSMutableArray *newPlaylist = [NSMutableArray array];
                for (NSString *element in elements) {
                    if ([element hasPrefix:@"#EXT-X-MEDIA:"]) {
                        // NSMutableDictionary *components = [NSMutableDictionary dictionary];
                        // NSString *attributeList = [element substringFromIndex:13];
                        
                        // Parse attributes while respecting quoted values
                        // NSMutableString *currentKey = [NSMutableString string];
                        // NSMutableString *currentValue = [NSMutableString string];
                        // BOOL inQuotes = NO;
                        
                        // for (NSInteger i = 0; i < [attributeList length]; i++) {
                        //     unichar c = [attributeList characterAtIndex:i];
                            
                        //     if (c == '"') {
                        //         inQuotes = !inQuotes;
                        //         [currentValue appendFormat:@"%c", c];
                        //     } else if (c == '=' && !inQuotes) {
                        //         // Key-value separator
                        //         [currentKey appendFormat:@"%c", c];
                        //     } else if (c == ',' && !inQuotes) {
                        //         // Attribute separator - save current pair
                        //         if ([currentKey length] > 0) {
                        //             NSArray *keyValue = [currentKey componentsSeparatedByString:@"="];
                        //             if ([keyValue count] == 2) {
                        //                 NSString *key = [keyValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        //                 NSString *value = [currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        //                 components[key] = value;
                        //             }
                        //         }
                        //         [currentKey setString:@""];
                        //         [currentValue setString:@""];
                        //     } else {
                        //         if ([currentKey rangeOfString:@"="].location != NSNotFound) {
                        //             [currentValue appendFormat:@"%c", c];
                        //         } else {
                        //             [currentKey appendFormat:@"%c", c];
                        //         }
                        //     }
                        // }
                        
                        // Don't forget the last pair
                        // if ([currentKey length] > 0) {
                        //     NSArray *keyValue = [currentKey componentsSeparatedByString:@"="];
                        //     if ([keyValue count] == 2) {
                        //         NSString *key = [keyValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        //         NSString *value = [currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        //         components[key] = value;
                        //     }
                        // }
                        
                        // Now that it's parsed, lets check and see if we should include it
                        // if ([components[@"name"] hasSuffix:@" - dubbed-auto\""]) {
                        //     continue;
                        // }

                        if ([element rangeOfString:@" - dubbed-auto\""].location == NSNotFound) {
                            [newPlaylist addObject:element];
                        }
                        

                        // NSLog(@"components -> %@", components);
                    } else {
                        [newPlaylist addObject:element];
                    }
                }
                // NSLog(@"newPlaylist -> %@", newPlaylist);
                // store the M3U8 in a file

                NSString *mediaPath = [NSString stringWithFormat:@"%@%@.m3u8", NSTemporaryDirectory(), [TRVideoTranslator uuid]];
                NSLog(@"HLS Stream is at %@", mediaPath);

                [[[newPlaylist valueForKey:@"description"] componentsJoinedByString:@"\n"] writeToFile:mediaPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

                id stream = nil;
                if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
                    stream = [NSClassFromString(@"YTStream") streamWithURL:[NSURL fileURLWithPath:mediaPath] format:1 encrypted:NO];
                } else {
                    stream = [NSClassFromString(@"YTStream") streamWithURL:[NSURL fileURLWithPath:mediaPath] format:1 encrypted:NO precached:NO];
                }

                if (stream) {
                    [ytStreams addObject:stream];
                }
                // NSLog(@"stream -> %@", streamURL);
                // NSLog(@"%@", result); 
            } else {
                // Handle error
                NSLog(@"Error fetching HLS Playlist: %@", error.localizedDescription);
            }


            // id stream = [NSClassFromString(@"YTStream") streamWithURL:[NSURL URLWithString:hlsStreamURL] format:3 encrypted:NO];
            // if (stream) {
            //     [ytStreams addObject:stream];
            // }
        } else {
            NSArray *formats = [TRJSONUtils arrayFromJSON:json keyPath:@"streamingData.formats"];
            for (NSDictionary *format in formats) {
                NSString *urlString = format[@"url"];
                if (urlString) {
                    NSURL *url = [NSURL URLWithString:urlString];
                    if (url) {
                        id stream = nil;
                        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
                            stream = [NSClassFromString(@"YTStream") streamWithURL:url format:4 encrypted:NO];
                        } else {
                            stream = [NSClassFromString(@"YTStream") streamWithURL:url format:4 encrypted:NO precached:NO];
                        }
                        if (stream) {
                            [ytStreams addObject:stream];
                        }
                    }
                }
            }
        }
    } else {
        // they wanna use a custom url for playback.
        NSURL *url = nil;
        if ([preferences[@"StreamType"] isEqualToString:@"tuberepair"]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://tuberepair.uptimetrackers.com/getvideo/%@", videoId]];
        } else {
            url = [NSURL URLWithString:[preferences[@"CustomStreamURL"] stringByReplacingOccurrencesOfString:@"%v" withString:videoId]];
        }
        // we don't really have a way of knowing the video quality so
        id stream = nil;
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
            stream = [NSClassFromString(@"YTStream") streamWithURL:url format:4 encrypted:NO];
        } else {
            stream = [NSClassFromString(@"YTStream") streamWithURL:url format:4 encrypted:NO precached:NO];
        }
        if (stream) {
            [ytStreams addObject:stream];
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

    // subtitles
    NSMutableArray *subtitleTracks = [NSMutableArray array];
    NSArray *subtitleTracksUnparsed = [TRJSONUtils arrayFromJSON:json keyPath:@"captions.playerCaptionsTracklistRenderer.captionTracks"];
    if (subtitleTracksUnparsed) {
        for (NSDictionary *track in subtitleTracksUnparsed) {
            [subtitleTracks addObject:[[NSClassFromString(@"YTSubtitlesTrack") alloc] initWithLanguageCode:track[@"languageCode"] languageName:track[@"name"][@"runs"][0][@"text"] trackName:[NSURL URLWithString:track[@"baseUrl"]]]];
        }
    }
    
    id video = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            subtitlesTracksURL:subtitleTracks ? subtitleTracks : nil
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
    } else if ([version() isEqualToString:@"1.1.0"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
            state:videoState
            streams:ytStreams
            thumbnailURLs:thumbnails
            subtitlesTracksURL:subtitleTracks ? subtitleTracks : nil
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
            adultContent:NO
            editURL:nil
            videoPro:nil];
    } else if ([version() isEqualToString:@"1.2.1"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
            state:videoState
            streams:ytStreams
            thumbnailURLs:thumbnails
            subtitlesTracksURL:subtitleTracks ? subtitleTracks : nil
            commentsAllowed:YES
            commentsURL:videoId
            commentsCountHint:0
            relatedURL:videoId
            claimed:NO
            monetized:NO
            monetizedCountries:@[]
            categoryLabel:@"Gaming"
            categoryTerm:category ?: @"Unknown"
            adultContent:NO
            editURL:nil
            paidContent:NO
            videoPro:nil
            liveEventURL:nil
            currentViewers:0
        ];
    } else {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
            state:videoState
            streams:ytStreams
            thumbnailURLs:thumbnails
            subtitlesTracksURL:subtitleTracks ? subtitleTracks : nil
            commentsAllowed:YES
            commentsURL:videoId
            commentsCountHint:0
            relatedURL:videoId
            claimed:NO
            monetized:NO
            monetizedCountries:@[]
            listed:YES // todo: this should be easy enough to implement
            categoryLabel:@"Gaming"
            categoryTerm:category ?: @"Unknown"
            adultContent:NO
            editURL:nil
            paidContent:NO
            videoPro:nil
            liveEventURL:nil
            currentViewers:39
        ];
    }
        
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
        NSLog(@"Could not find video data!");
        return nil;
    }

    if ([dataType isEqualToString:@"playlistVideoRenderer"]) {
        if (![TRJSONUtils stringFromJSON:videoData keyPath:@"videoInfo.runs[1].text"]) {
            return nil;
        }
    }
    
    // Skip upcoming/scheduled videos
    if (videoData[@"upcomingEventData"]) {
        NSLog(@"skipping upcoming & scheduled video");
        return nil;
    }

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if (!preferences[@"ShowLiveContent"] && [[TRJSONUtils stringFromJSON:videoData keyPath:@"thumbnailOverlays[0].thumbnailOverlayTimeStatusRenderer.style"] isEqualToString:@"LIVE"]) {
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

    if ([title isEqualToString:@"[Deleted video]"]) return nil;
    
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

    // if ([channelId isEqualToString:@"UCStfhR2V58QkCCyq_8dlk6g"]) {
    //     NSLog(@"channel id is the bad one!!! title -> %@, channelName -> %@", title, uploaderName);
    // }
    
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
                    part = [part stringByReplacingOccurrencesOfString:@"," withString:@""];
                    [dateString appendFormat:@"%@ ", part];
                    
                    // Stop after we collect the time unit and "ago"
                    // Pattern: "41 minutes ago" 
                    if ([[part lowercaseString] isEqualToString:@"ago"]) {
                        break;
                    }
                }
                uploadDate = [TRJSONUtils dateFromTimeAgo:[dateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
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
    // NSLog(@"views -> %llu", views);

    id video = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
    } else if ([version() isEqualToString:@"1.1.0"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
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
            adultContent:NO
            editURL:nil
            videoPro:nil];
    } else if ([version() isEqualToString:@"1.2.1"]) {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
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
            categoryLabel:@"Gaming"
            categoryTerm:@"Unknown"
            adultContent:NO
            editURL:nil
            paidContent:NO
            videoPro:nil
            liveEventURL:nil
            currentViewers:0];
    } else {
        video = [[NSClassFromString(@"YTVideo") alloc] 
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
            ratingAllowed:YES
            state:videoState
            streams:@[[NSClassFromString(@"YTStream") streamWithURL:[NSURL fileURLWithPath:@"https://google.com"] format:1 encrypted:NO precached:NO]]
            thumbnailURLs:thumbnails
            subtitlesTracksURL:nil
            commentsAllowed:YES
            commentsURL:videoId
            commentsCountHint:0
            relatedURL:videoId
            claimed:NO
            monetized:NO
            monetizedCountries:@[]
            listed:YES // TODO: this should be easy enough to implement properly
            categoryLabel:@"Gaming"
            categoryTerm:@"Unknown"
            adultContent:NO
            editURL:nil
            paidContent:NO
            videoPro:nil
            liveEventURL:nil
            currentViewers:0];
    }
    
    return [video autorelease];
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

    result = [TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.compactVideoRenderer"];
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
    if ([TRJSONUtils dictFromJSON:json keyPath:@"richItemRenderer.content.compactVideoRenderer"]) return @"videoRenderer";
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
            [video setValue:nextData[@"dislikes"][@"dislikes"] forKey:l(@"dislikesCount")];
            [video setValue:nextData[@"dislikes"][@"likes"] forKey:l(@"likesCount")];
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

                    for (NSDictionary *engagementPanel in nextData[@"next"][@"engagementPanels"]) {
                        NSString *dateString = engagementPanel[@"engagementPanelSectionListRenderer"][@"content"][@"structuredDescriptionContentRenderer"][@"items"][0][@"videoDescriptionHeaderRenderer"][@"publishDate"][@"runs"][0][@"text"];
                        if (dateString != nil) {
                            if ([dateString hasSuffix:@" ago"]) {
                                NSDate *date = [TRJSONUtils dateFromTimeAgo:dateString];
                                [video setValue:date forKey:l(@"uploadedDate")];
                                [video setValue:date forKey:l(@"publishedDate")];
                            } else {
                                NSDate *date = [TRJSONUtils dateFromShortDate:dateString];
                                [video setValue:date forKey:l(@"uploadedDate")];
                                [video setValue:date forKey:l(@"publishedDate")];
                            }
                        }
                    }
                    
                    if (!hasLikeDataAlready) {
                        // Extract like count
                        NSString *accessibilityText = likeButtonVM[@"likeButtonViewModel"][@"toggleButtonViewModel"][@"toggleButtonViewModel"][@"defaultButtonViewModel"][@"buttonViewModel"][@"accessibilityText"];

                        if (accessibilityText) { 
                            NSArray *accessibilityTextContent = [accessibilityText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            long likes = [TRJSONUtils numberFromText:accessibilityTextContent[5]];
                            if (likes > 0) {
                                [video setValue:[NSNumber numberWithLong:likes] forKey:l(@"likesCount")];
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

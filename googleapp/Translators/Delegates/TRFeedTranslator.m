// TRFeedTranslator.m
// TubeReplacer
//
// Feed translator implementation

#import "TRFeedTranslator.h"
#import "TRVideoTranslator.h"
#import "TRChannelTranslator.h"
#import "TRJSONUtils.h"
#import "TRContinuation.h"
#import "../appheaders.h"

@implementation TRFeedTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeFeed;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    // Various feed response formats
    if ([TRJSONUtils dictFromJSON:json keyPath:@"contents.singleColumnBrowseResultsRenderer"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"contents.sectionListRenderer"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"contents.twoColumnWatchNextResults"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"contents.singleColumnWatchNextResults"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"onResponseReceivedActions[0].reloadContinuationItemsCommand.continuationItems"]) {
        return YES;
    }
    if ([TRJSONUtils dictFromJSON:json keyPath:@"onResponseReceivedEndpoints[0].appendContinuationItemsAction.continuationItems"]) {
        return YES;
    }
    return NO;
}

- (id)translateJSONAsEvent:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRFeedTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    

    NSArray *items = [self extractItemsFromFeed:json];
    NSMutableArray *entries = [NSMutableArray array];
    NSString *continuationToken = nil;
    
    // TODO: move this somewhat to it's own space like comments, how that app actually expects it
    TRVideoTranslator *videoTranslator = [[[TRVideoTranslator alloc] init] autorelease];
    
    continuationToken = [TRJSONUtils stringFromJSON:json keyPath:@"contents.sectionListRenderer.contents[1].continuationItemRenderer.continuationEndpoint.continuationCommand.token"];
    if (!continuationToken) continuationToken = [TRJSONUtils stringFromJSON:json keyPath:@"onResponseReceivedCommands[0].appendContinuationItemsAction.continuationItems[1].continuationItemRenderer.continuationEndpoint.continuationCommand.token"];

    for (NSDictionary *item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSLog(@"translateJSONAsEvent!");

        // Skip continuation items
        if ([item objectForKey:@"continuationItemRenderer"]) {
            continuationToken = item[@"continuationItemRenderer"][@"continuationEndpoint"][@"continuationCommand"][@"token"];
            continue;
        }
        
        NSError *itemError = nil;
        YTVideo *entry = [videoTranslator translateFeedItem:item withContext:json error:&itemError];

        NSLog(@"video -> %@", entry);
        
        // NSLog(@"actions -> %@", [self valueForKey:@"actionsLookup_"]);
        NSLog(@"uploader display name -> %@", [entry uploaderDisplayName]);
        if (entry) {
            [entries addObject:[[NSClassFromString(@"YTEvent") alloc] initWithAuthorDisplayName:[entry uploaderDisplayName]
                authorUserID:[entry uploaderChannelID]
                action:9 // 5 = uploaded 9 = recommended
                target:[entry uploaderChannelID]
                when:[entry uploadedDate]
                video:entry
                groupID:[entry title]
                feedURL:[NSURL URLWithString:@"https://google.com"]
            ]];
            // [entries addObject:entry];
        }
    }

    NSLog(@"continuation token -> %@", continuationToken);
    
    id contiunationData = nil;
    if (continuationToken) {
        contiunationData = [TRContinuation initWithToken:continuationToken];
    }

    // Create YTPage
    id page = [[[NSClassFromString(@"YTPage") alloc] 
        initWithEntries:entries 
        totalResults:100000 // todo: make better
        entriesPerPage:[entries count] 
        startIndex:1 
        nextURL:contiunationData //// right now continuation has some issues missing the channel information, and I don't wanna bother with it right now.
        previousURL:nil
    ] autorelease];
  
    return page;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRFeedTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    NSArray *items = [self extractItemsFromFeed:json];
    NSMutableArray *entries = [NSMutableArray array];
    NSString *continuationToken = nil;
    
    // TODO: move this somewhat to it's own space like comments, how that app actually expects it
    TRVideoTranslator *videoTranslator = [[[TRVideoTranslator alloc] init] autorelease];
    TRChannelTranslator *channelTranslator = [[[TRChannelTranslator alloc] init] autorelease];
    
    continuationToken = [TRJSONUtils stringFromJSON:json keyPath:@"contents.sectionListRenderer.contents[1].continuationItemRenderer.continuationEndpoint.continuationCommand.token"];
    if (!continuationToken) continuationToken = [TRJSONUtils stringFromJSON:json keyPath:@"onResponseReceivedCommands[0].appendContinuationItemsAction.continuationItems[1].continuationItemRenderer.continuationEndpoint.continuationCommand.token"];

    for (NSDictionary *item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        // Skip continuation items
        if ([item objectForKey:@"continuationItemRenderer"]) {
            continuationToken = item[@"continuationItemRenderer"][@"continuationEndpoint"][@"continuationCommand"][@"token"];
            continue;
        }
        
        NSError *itemError = nil;
        id entry = nil;
        
        // Try video first
        if ([videoTranslator canTranslateJSON:item]) {
            entry = [videoTranslator translateFeedItem:item withContext:json error:&itemError];
        }
        // Then try channel
        else if ([channelTranslator canTranslateJSON:item]) {
            entry = [channelTranslator translateJSON:item error:&itemError];
        }
        
        if (entry) {
            [entries addObject:entry];
        }
    }

    NSLog(@"continuation token -> %@", continuationToken);
    
    // Create YTPage
    id page = [[[NSClassFromString(@"YTPage") alloc] 
        initWithEntries:entries 
        totalResults:100000 // todo: make better
        entriesPerPage:[entries count] 
        startIndex:1 
        nextURL:continuationToken 
        previousURL:nil
    ] autorelease];
    
    return page;
}

#pragma mark - Item Extraction

- (NSArray *)extractItemsFromFeed:(NSDictionary *)json {
    NSArray *items = nil;
    
    // Try various known paths for feed items
    
    // Gaming home / shelf content
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents[0].itemSectionRenderer.contents[0].shelfRenderer.content.horizontalListRenderer.items"];
    if (items) return items;
    
    // History (special case - multiple sections by date)
    NSString *browseId = [TRJSONUtils stringFromJSON:json 
        keyPath:@"responseContext.serviceTrackingParams[0].params[0].value"];
    if ([browseId isEqualToString:@"FEhistory"]) {
        NSMutableArray *allItems = [NSMutableArray array];
        NSArray *sections = [TRJSONUtils arrayFromJSON:json 
            keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents"];
        for (NSDictionary *section in sections) {
            if (section[@"continuationItemRenderer"]) {
                [allItems addObject:section];
                continue;
            }
            NSArray *sectionItems = [TRJSONUtils arrayFromJSON:section keyPath:@"itemSectionRenderer.contents"];
            if (sectionItems) {
                [allItems addObjectsFromArray:sectionItems];
            }
        }
        if ([allItems count] > 0) return allItems;

        // Continuation
        sections = [TRJSONUtils arrayFromJSON:json 
            keyPath:@"onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems"];
        for (NSDictionary *section in sections) {
            if (section[@"continuationItemRenderer"]) { // seems to break for some reason that i can't figure out.
                NSLog(@"history contiunue!");
                [allItems addObject:section];
                continue;
            }
            NSArray *sectionItems = [TRJSONUtils arrayFromJSON:section keyPath:@"itemSectionRenderer.contents"];
            if (sectionItems) {
                [allItems addObjectsFromArray:sectionItems];
            }
        }
        if ([allItems count] > 0) return allItems;
    }
    
    // Playlist
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents[0].itemSectionRenderer.contents[0].playlistVideoListRenderer.contents"];
    if (items) return items;
    
    // Standard browse section list
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents"];
    if (items) return items;
    
    // Channel videos (tab index 1)
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[1].tabRenderer.content.richGridRenderer.contents"];
    if (items) return items;

    // Home Feed
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.richGridRenderer.contents"];
    if (items) return items;
    
    // Search results
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.sectionListRenderer.contents[0].itemSectionRenderer.contents"];
    if (items) return items;
    
    // Mobile suggestions
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.singleColumnWatchNextResults.results.results.contents[3].itemSectionRenderer.contents"];
    if (items) return items;
    
    // Desktop suggestions
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"contents.twoColumnWatchNextResults.secondaryResults.secondaryResults.results[1].itemSectionRenderer.contents"];
    if (items) return items;

    // Continuation
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems"];
    if (items) return items;

    // popular thingy
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"onResponseReceivedActions[0].reloadContinuationItemsCommand.continuationItems"];
    if (items) return items;

    // suggestions continue
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"onResponseReceivedEndpoints[0].appendContinuationItemsAction.continuationItems"];
    if (items) return items;

    // search continuation
    items = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"onResponseReceivedCommands[0].appendContinuationItemsAction.continuationItems[0].itemSectionRenderer.contents"];
    if (items) return items;
    
    NSLog(@"No array of content found!!!");
    return @[];
}

@end

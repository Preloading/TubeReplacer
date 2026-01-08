// TRFeedTranslator.m
// TubeReplacer
//
// Feed translator implementation

#import "TRFeedTranslator.h"
#import "TRVideoTranslator.h"
#import "TRChannelTranslator.h"
#import "TRJSONUtils.h"
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
    return NO;
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
    
    TRVideoTranslator *videoTranslator = [[[TRVideoTranslator alloc] init] autorelease];
    TRChannelTranslator *channelTranslator = [[[TRChannelTranslator alloc] init] autorelease];
    
    for (NSDictionary *item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        // Skip continuation items
        if ([item objectForKey:@"continuationItemRenderer"]) {
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
    
    // Create YTPage
    id page = [[[NSClassFromString(@"YTPage") alloc] 
        initWithEntries:entries 
        totalResults:[entries count] 
        entriesPerPage:[entries count] 
        startIndex:1 
        nextURL:nil 
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
            if ([section objectForKey:@"continuationItemRenderer"]) {
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
    
    return @[];
}

@end

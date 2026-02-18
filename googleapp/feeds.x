// feeds.x
// TubeReplacer
//
// Main page/feed parser - delegates to translators for parsing

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "Translators/TRContinuation.h"

@interface YTPageParser : NSObject
+(id)parseLockupViewModelVideo:(NSDictionary*)unparsedVideo;
-(id)parseSpecializedFeed:(NSDictionary *)bodyDict 
          withEntryParser:(id)entryParser 
                    error:(NSError **)error;
-(NSArray *)extractSpecializedItems:(NSDictionary *)bodyDict forParser:(id)parser;
@end

%hook YTPageParser

#pragma mark - Main Entry Point

-(id)parseElement:(id)body error:(NSError **)error {
    if (![body isKindOfClass:[NSDictionary class]]) {
        NSLog(@"YTPageParser: input is not NSDictionary");
        return nil;
    }
    
    NSDictionary *bodyDict = body;
    id entryParser = [self valueForKey:@"entryParser_"];
    
    NSLog(@"class -> %@", [entryParser class]);
    // Special handling for subscription, comment, and playlist parsers
    // These need individual item routing through their specific parsers
    if ([entryParser isKindOfClass:[%c(YTSubscriptionParser) class]] ||
        [entryParser isKindOfClass:[%c(YTCommentParser) class]] ||
        [entryParser isKindOfClass:[%c(YTPlaylistParser) class]]) {
        return [self parseSpecializedFeed:bodyDict withEntryParser:entryParser error:error];
    }


    // Use TRFeedTranslator for standard video/channel feeds
    TRFeedTranslator *translator = [[[TRFeedTranslator alloc] init] autorelease];
    if ([entryParser isKindOfClass:[%c(YTEventParser) class]]) {
        return [translator translateJSONAsEvent:bodyDict error:error];
    }
    return [translator translateJSON:bodyDict error:error];
}

#pragma mark - Specialized Feed Parsing (subscriptions, comments, playlists)

%new
-(id)parseSpecializedFeed:(NSDictionary *)bodyDict 
          withEntryParser:(id)entryParser 
                    error:(NSError **)error {
    
    NSArray *items = [self extractSpecializedItems:bodyDict forParser:entryParser];
    
    if (!items || [items count] == 0) {
        return [[%c(YTPage) alloc] initWithEntries:@[] 
                                      totalResults:0 
                                    entriesPerPage:0 
                                        startIndex:0 
                                           nextURL:nil 
                                       previousURL:nil];
    }
    
    NSMutableArray *output = [NSMutableArray array];
    TRContinuation *continuation = nil;
    
    for (id item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        if ([item objectForKey:@"continuationItemRenderer"]) {
            continuation = [TRContinuation initWithToken:item[@"continuationItemRenderer"][@"continuationEndpoint"][@"continuationCommand"][@"token"]];
            continue;
        }
        
        // Wrap item with context for the parser
        NSError *parseError = nil;
        id entry = [entryParser parseElement:@{@"i": item, @"all": bodyDict} error:&parseError];
        
        if (parseError) {
            NSLog(@"YTPageParser: entry parser error: %@", parseError);
            break;
        }
        
        if (entry) {
            [output addObject:entry];
        }
    }
    
    YTPage *page = [[%c(YTPage) alloc] initWithEntries:output 
                                          totalResults:[output count] 
                                        entriesPerPage:[output count] 
                                            startIndex:1 
                                               nextURL:continuation 
                                           previousURL:nil];

    return [page autorelease];
}

%new
-(NSArray *)extractSpecializedItems:(NSDictionary *)bodyDict forParser:(id)parser {
    // Subscription feed items
    if ([parser isKindOfClass:[%c(YTSubscriptionParser) class]]) {
        return [TRJSONUtils arrayFromJSON:bodyDict 
            keyPath:@"contents.twoColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents[0].itemSectionRenderer.contents[0].shelfRenderer.content.expandedShelfContentsRenderer.items"];
    }
    
    // Comment items
    if ([parser isKindOfClass:[%c(YTCommentParser) class]]) {
        id feed = [TRJSONUtils arrayFromJSON:bodyDict 
            keyPath:@"onResponseReceivedEndpoints[1].reloadContinuationItemsCommand.continuationItems"];
        if (feed) return feed;
        return [TRJSONUtils arrayFromJSON:bodyDict 
            keyPath:@"onResponseReceivedEndpoints[0].appendContinuationItemsAction.continuationItems"];
    }
    
    // Playlist items (find the "Playlists" tab)
    if ([parser isKindOfClass:[%c(YTPlaylistParser) class]]) {
        NSArray *items = [TRJSONUtils arrayFromJSON:bodyDict 
            keyPath:@"onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems"];
        if (items) return items;

        NSArray *tabs = [TRJSONUtils arrayFromJSON:bodyDict 
            keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs"];
        
        for (NSDictionary *tab in tabs) {
            NSString *tabTitle = [TRJSONUtils stringFromJSON:tab keyPath:@"tabRenderer.title"];
            if ([tabTitle isEqualToString:@"Playlists"]) {
                return [TRJSONUtils arrayFromJSON:tab 
                    keyPath:@"tabRenderer.content.sectionListRenderer.contents[0].itemSectionRenderer.contents"];
            }
        }
    }
    
    return nil;
}

#pragma mark - Legacy Helper for LockupViewModel

%new
+(id)parseLockupViewModelVideo:(NSDictionary*)unparsedVideo {
    // This is called for new lockupViewModel format
    // Delegate to translator
    TRVideoTranslator *translator = [[[TRVideoTranslator alloc] init] autorelease];
    NSError *error = nil;
    return [translator translateJSON:@{@"lockupViewModel": unparsedVideo} error:&error];
}

%end
// TRPlaylistTranslator.m
// TubeReplacer
//
// Playlist translator implementation

#import "TRPlaylistTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"
#import "../general.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation TRPlaylistTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypePlaylist;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    // Compact playlist from feed (wrapped in "i")
    if ([json objectForKey:@"i"]) {
        NSDictionary *inner = [json objectForKey:@"i"];
        if ([inner objectForKey:@"compactPlaylistRenderer"]) {
            return YES;
        }
    }
    return NO;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRPlaylistTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    NSDictionary *context = [json objectForKey:@"all"];
    return [self translateCompactPlaylist:json withContext:context error:error];
}

#pragma mark - Compact Playlist

- (id)translateCompactPlaylist:(NSDictionary *)json 
                   withContext:(NSDictionary *)context 
                         error:(NSError **)error {
    
    NSDictionary *data = [TRJSONUtils dictFromJSON:json keyPath:@"i.compactPlaylistRenderer"];
    
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRPlaylistTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing playlist data"}];
        }
        return nil;
    }

    NSString *title = [TRJSONUtils stringFromJSON:data keyPath:@"title.runs[0].text"];

    NSString *author = @"";
    if (context) {
        author = [TRJSONUtils stringFromJSON:context keyPath:@"header.pageHeaderRenderer.pageTitle"];
    }
    
    NSArray *thumbArray = [TRJSONUtils arrayFromJSON:data keyPath:@"thumbnail.thumbnails"];
    NSMutableDictionary *thumbnails = [NSMutableDictionary dictionary];
    for (NSDictionary *thumb in thumbArray) {
        if (![thumb isKindOfClass:[NSDictionary class]]) continue;
        
        NSString *urlString = [thumb objectForKey:@"url"];
        NSNumber *width = [thumb objectForKey:@"width"];
        NSNumber *height = [thumb objectForKey:@"height"];
        
        if (urlString) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url && width && height) {
                CGSize size = CGSizeMake([width floatValue], [height floatValue]);
                NSValue *sizeValue = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
                [thumbnails setObject:url forKey:sizeValue];
            }
        }
    }
    
    NSString *playlistId = [data objectForKey:@"playlistId"];
    
    NSString *countText = [TRJSONUtils stringFromJSON:data keyPath:@"videoCountShortText.runs[0].text"];
    int videoCount = countText ? [countText intValue] : 0;
    
    NSString *bylineText = [TRJSONUtils stringFromJSON:data keyPath:@"shortBylineText.runs[0].text"];
    BOOL isPrivate = [bylineText isEqualToString:@"Private"];
    
    id playlist = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
        playlist = [[[NSClassFromString(@"YTPlaylist") alloc] 
            initWithTitle:title ?: @""
            summary:@""
            authorDisplayName:author
            updated:[NSDate date]
            thumbnailURLs:thumbnails
            contentURL:playlistId
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            size:videoCount
            isPrivate:isPrivate
        ] autorelease];
    } else {
        playlist = [[[NSClassFromString(@"YTPlaylist") alloc] 
            initWithID:playlistId
            title:title ?: @""
            summary:@""
            authorDisplayName:author
            updated:[NSDate date]
            thumbnailURLs:thumbnails
            contentURL:playlistId
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            size:videoCount
            isPrivate:isPrivate
        ] autorelease];
    }
    
    return playlist;
}

@end

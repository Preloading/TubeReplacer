// TRPlaylistTranslator.m
// TubeReplacer
//
// Playlist translator implementation

#import "TRPlaylistTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"
#import <CoreGraphics/CoreGraphics.h>

// YTPlaylist is declared in appheaders.h

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
    
    // Get context if available
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
    
    // Title
    NSString *title = [TRJSONUtils stringFromJSON:data keyPath:@"title.runs[0].text"];
    
    // Author from context (channel page header)
    NSString *author = @"";
    if (context) {
        author = [TRJSONUtils stringFromJSON:context keyPath:@"header.pageHeaderRenderer.pageTitle"];
    }
    
    // Thumbnails
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
    
    // Playlist ID
    NSString *playlistId = [data objectForKey:@"playlistId"];
    
    // Video count
    NSString *countText = [TRJSONUtils stringFromJSON:data keyPath:@"videoCountShortText.runs[0].text"];
    int videoCount = countText ? [countText intValue] : 0;
    
    // Privacy check
    NSString *bylineText = [TRJSONUtils stringFromJSON:data keyPath:@"shortBylineText.runs[0].text"];
    BOOL isPrivate = [bylineText isEqualToString:@"Private"];
    
    id playlist = [[[NSClassFromString(@"YTPlaylist") alloc] 
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
    
    return playlist;
}

@end

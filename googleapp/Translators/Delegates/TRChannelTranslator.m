// TRChannelTranslator.m
// TubeReplacer
//
// Channel translator implementation

#import "TRChannelTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"
#import "../general.h"

@implementation TRChannelTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeChannel;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    if ([TRJSONUtils dictFromJSON:json keyPath:@"header.pageHeaderRenderer"]) {
        return YES;
    }
    if ([json objectForKey:@"compactChannelRenderer"]) {
        return YES;
    }
    if ([json objectForKey:@"channelRenderer"]) {
        return YES;
    }
    return NO;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRChannelTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    if ([TRJSONUtils dictFromJSON:json keyPath:@"header.pageHeaderRenderer"]) {
        return [self translateChannelPage:json error:error];
    }
    
    return [self translateCompactChannel:json error:error];
}

#pragma mark - Full Channel Page

- (id)translateChannelPage:(NSDictionary *)json error:(NSError **)error {
    NSString *channelId = [TRJSONUtils stringFromJSON:json keyPath:@"metadata.channelMetadataRenderer.externalId"];
    
    if (!channelId) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRChannelTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing channelId"}];
        }
        return nil;
    }
    
    NSString *title = [TRJSONUtils stringFromJSON:json keyPath:@"header.pageHeaderRenderer.pageTitle"];
    NSString *description = [TRJSONUtils stringFromJSON:json keyPath:@"metadata.channelMetadataRenderer.description"];
    
    long subs = -1;
    long videoCount = -1;
    
    NSArray *metadataRows = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.metadata.contentMetadataViewModel.metadataRows"];
    
    if ([metadataRows count] >= 2) {
        NSArray *metadataParts = [TRJSONUtils arrayFromJSON:json 
            keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.metadata.contentMetadataViewModel.metadataRows[1].metadataParts"];
        
        if ([metadataParts count] >= 2) {
            NSString *subsText = [TRJSONUtils stringFromJSON:json 
                keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.metadata.contentMetadataViewModel.metadataRows[1].metadataParts[0].text.content"];
            NSString *videosText = [TRJSONUtils stringFromJSON:json 
                keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.metadata.contentMetadataViewModel.metadataRows[1].metadataParts[1].text.content"];
            
            subs = [TRJSONUtils numberFromText:subsText];
            videoCount = [TRJSONUtils numberFromText:videosText];
        } else if ([metadataParts count] == 1) {
            NSString *subsText = [TRJSONUtils stringFromJSON:json 
                keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.metadata.contentMetadataViewModel.metadataRows[1].metadataParts[0].text.content"];
            subs = [TRJSONUtils numberFromText:subsText];
        }
    }
    
    NSString *thumbnailUrl = [TRJSONUtils stringFromJSON:json 
        keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.image.decoratedAvatarViewModel.avatar.avatarViewModel.image.sources[0].url"];
    NSURL *thumbnailURL = thumbnailUrl ? [NSURL URLWithString:thumbnailUrl] : nil;
    
    id channel = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
        channel = [[[NSClassFromString(@"YTChannel") alloc] 
            initWithDisplayName:title ?: @""
            channelID:channelId
            summary:description ?: @""
            updated:[NSDate date]
            videoCount:videoCount
            thumbnailURL:thumbnailURL
            subscribersCount:subs
        ] autorelease];
    } else {
        channel = [[[NSClassFromString(@"YTChannel") alloc] 
            initWithDisplayName:title ?: @""
            channelID:channelId
            summary:description ?: @""
            updated:[NSDate date]
            videoCount:videoCount
            thumbnailURL:thumbnailURL
            subscribersCount:subs
            paidContent:false
        ] autorelease];
    }
    
    return channel;
}

#pragma mark - Compact Channel (Search/Feed)

- (id)translateCompactChannel:(NSDictionary *)json error:(NSError **)error {
    NSDictionary *channelData = [json objectForKey:@"compactChannelRenderer"];
    if (!channelData) {
        channelData = [json objectForKey:@"channelRenderer"];
    }
    if (!channelData) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRChannelTranslator" code:3 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Could not find channel data"}];
        }
        return nil;
    }
    
    NSString *channelId = [channelData objectForKey:@"channelId"];
    if (!channelId) {
        return nil;
    }
    
    NSString *displayName = [TRJSONUtils stringFromJSON:channelData keyPath:@"displayName.runs[0].text"];
    if (!displayName) {
        displayName = [TRJSONUtils stringFromJSON:channelData keyPath:@"title.simpleText"];
    }
    
    NSString *thumbUrl = [TRJSONUtils stringFromJSON:channelData keyPath:@"thumbnail.thumbnails[0].url"];
    if (thumbUrl && ![thumbUrl hasPrefix:@"http"]) {
        thumbUrl = [@"https:" stringByAppendingString:thumbUrl];
    }
    NSURL *thumbnailURL = thumbUrl ? [NSURL URLWithString:thumbUrl] : nil;

    NSString *subsText = [TRJSONUtils stringFromJSON:channelData keyPath:@"videoCountText.runs[0].text"];
    long subs = [TRJSONUtils numberFromText:subsText];
    
    long videoCount = 0;
    NSString *accessibilityLabel = [TRJSONUtils stringFromJSON:channelData 
                                                       keyPath:@"title.accessibility.accessibilityData.label"];
    if (accessibilityLabel) {
        NSArray *parts = [accessibilityLabel componentsSeparatedByString:@" "];
        int nameWordCount = [[displayName componentsSeparatedByString:@" "] count];
        if ([parts count] > nameWordCount) {
            videoCount = [TRJSONUtils numberFromText:[parts objectAtIndex:nameWordCount]];
        }
    }
    
    id channel = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
        channel = [[[NSClassFromString(@"YTChannel") alloc] 
            initWithDisplayName:displayName ?: @""
            channelID:channelId
            summary:@""
            updated:[NSDate date]
            videoCount:videoCount
            thumbnailURL:thumbnailURL
            subscribersCount:subs
        ] autorelease];
    } else {
        channel = [[[NSClassFromString(@"YTChannel") alloc] 
            initWithDisplayName:displayName ?: @""
            channelID:channelId
            summary:@""
            updated:[NSDate date]
            videoCount:videoCount
            thumbnailURL:thumbnailURL
            subscribersCount:subs
            paidContent:false
        ] autorelease];
    }
    
    return channel;
}

@end

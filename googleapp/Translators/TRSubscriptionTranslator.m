// TRSubscriptionTranslator.m
// TubeReplacer
//
// Subscription translator implementation

#import "TRSubscriptionTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"

@implementation TRSubscriptionTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeSubscription;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    // List item format (from subscription page, wrapped in "i")
    if ([json objectForKey:@"i"]) {
        NSDictionary *inner = [json objectForKey:@"i"];
        if ([inner objectForKey:@"channelListItemRenderer"]) {
            return YES;
        }
    }
    // Channel header format (subscription check)
    if ([json objectForKey:@"header"] && [json objectForKey:@"frameworkUpdates"]) {
        return YES;
    }
    // Just-subscribed action response
    if ([TRJSONUtils dictFromJSON:json keyPath:@"actions[2].updateSubscribeButtonAction"]) {
        return YES;
    }
    return NO;
}

- (id)translateJSON:(NSDictionary *)json error:(NSError **)error {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRSubscriptionTranslator" code:1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
        }
        return nil;
    }
    
    // Detect format
    if ([json objectForKey:@"i"]) {
        return [self translateListItem:json error:error];
    }
    
    if ([json objectForKey:@"header"]) {
        return [self translateFromChannelHeader:json error:error];
    }
    
    return [self translateFromSubscribeAction:json error:error];
}

#pragma mark - List Item (Subscription Page)

- (id)translateListItem:(NSDictionary *)json error:(NSError **)error {
    NSDictionary *subscription = [TRJSONUtils dictFromJSON:json keyPath:@"i.channelListItemRenderer"];
    
    if (!subscription) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRSubscriptionTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing subscription data"}];
        }
        return nil;
    }
    
    NSString *channelID = [subscription objectForKey:@"channelId"];
    NSString *displayName = [TRJSONUtils stringFromJSON:subscription keyPath:@"title.runs[0].text"];
    
    // Thumbnail URL (needs https: prefix)
    NSString *thumbUrl = [TRJSONUtils stringFromJSON:subscription keyPath:@"thumbnail.thumbnails[0].url"];
    if (thumbUrl && ![thumbUrl hasPrefix:@"http"]) {
        thumbUrl = [@"https:" stringByAppendingString:thumbUrl];
    }
    NSURL *thumbnailURL = thumbUrl ? [NSURL URLWithString:thumbUrl] : nil;
    
    id sub = [[[NSClassFromString(@"YTSubscription") alloc] 
        initWithUsername:displayName
        displayName:displayName
        channelID:channelID
        type:1
        publishedDate:[NSDate date]
        updatedDate:[NSDate date]
        countHint:0
        editURL:[NSURL URLWithString:@"https://youtube.com"]
        thumbnailURL:thumbnailURL
    ] autorelease];
    
    return sub;
}

#pragma mark - Channel Header (Subscription Check)

- (id)translateFromChannelHeader:(NSDictionary *)json error:(NSError **)error {
    // Check if subscribed
    NSNumber *isSubscribed = [TRJSONUtils valueFromJSON:json 
        keyPathWithArrays:@"frameworkUpdates.entityBatchUpdate.mutations[0].payload.subscriptionStateEntity.subscribed"];
    
    if (![isSubscribed isEqual:@1]) {
        // Not subscribed, return nil (this is expected behavior)
        return nil;
    }
    
    // Extract subscription info from header
    NSString *displayName = [TRJSONUtils stringFromJSON:json keyPath:@"header.pageHeaderRenderer.pageTitle"];
    NSString *channelID = [TRJSONUtils stringFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.browseEndpoint.browseId"];
    
    NSString *thumbUrl = [TRJSONUtils stringFromJSON:json 
        keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.image.decoratedAvatarViewModel.avatar.avatarViewModel.image.sources[0].url"];
    NSURL *thumbnailURL = thumbUrl ? [NSURL URLWithString:thumbUrl] : nil;
    
    id sub = [[[NSClassFromString(@"YTSubscription") alloc] 
        initWithUsername:displayName
        displayName:displayName
        channelID:channelID
        type:1
        publishedDate:[NSDate date]
        updatedDate:[NSDate date]
        countHint:0
        editURL:[NSURL URLWithString:@"https://youtube.com"]
        thumbnailURL:thumbnailURL
    ] autorelease];
    
    return sub;
}

#pragma mark - Subscribe Action Response

- (id)translateFromSubscribeAction:(NSDictionary *)json error:(NSError **)error {
    NSString *channelID = [TRJSONUtils stringFromJSON:json 
        keyPath:@"actions[2].updateSubscribeButtonAction.channelId"];
    
    if (!channelID) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRSubscriptionTranslator" code:3 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing channelId in action"}];
        }
        return nil;
    }
    
    id sub = [[[NSClassFromString(@"YTSubscription") alloc] 
        initWithUsername:nil
        displayName:@""
        channelID:channelID
        type:1
        publishedDate:[NSDate date]
        updatedDate:[NSDate date]
        countHint:0
        editURL:[NSURL URLWithString:@"https://youtube.com"]
        thumbnailURL:nil
    ] autorelease];
    
    return sub;
}

@end

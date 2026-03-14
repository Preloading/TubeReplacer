// TRSubscriptionTranslator.m
// TubeReplacer
//
// Subscription translator implementation

#import "TRSubscriptionTranslator.h"
#import "TRChannelTranslator.h"
#import "TRJSONUtils.h"
#import "../appheaders.h"
#import "../general.h"

@implementation TRSubscriptionTranslator

#pragma mark - TRJSONTranslatorProtocol

+ (TREndpointType)supportedEndpoint {
    return TREndpointTypeSubscription;
}

- (BOOL)canTranslateJSON:(NSDictionary *)json {
    if ([json objectForKey:@"i"]) {
        NSDictionary *inner = [json objectForKey:@"i"];
        if ([inner objectForKey:@"channelListItemRenderer"]) {
            return YES;
        }
    }
    if ([json objectForKey:@"header"] && [json objectForKey:@"frameworkUpdates"]) {
        return YES;
    }
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
    NSLog(@"we are actually parsing a subscription");
    NSDictionary *subscription = [TRJSONUtils dictFromJSON:json keyPath:@"i"];
    
    if (!subscription) {
        if (error) {
            *error = [NSError errorWithDomain:@"TRSubscriptionTranslator" code:2 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing subscription data"}];
        }
        return nil;
    }
    
    YTChannel *channel = [[TRChannelTranslator alloc] translateCompactChannel:subscription error:error];
    // todo check for error

    id sub = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
            initWithUsername:[channel channelID] // i could fix this but im lazy
            displayName:[channel displayName]
            channelID:[channel channelID]
            type:1
            publishedDate:[NSDate date]
            updatedDate:[channel updated]
            countHint:0
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            thumbnailURL:[channel thumbnailURL]
        ] autorelease];
    } else {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
            initWithDisplayName:[channel displayName]
            channelID:[channel channelID]
            type:1
            publishedDate:[NSDate date]
            updatedDate:[channel updated]
            countHint:0
            unreadCount:0 // todo: see if i can actually make this correct
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            thumbnailURL:[channel thumbnailURL]
        ] autorelease];
    }
    
    return sub;
}

#pragma mark - Channel Header (Subscription Check)

- (id)translateFromChannelHeader:(NSDictionary *)json error:(NSError **)error {
    // PAIN
    NSString *mutationKey = [TRJSONUtils stringFromJSON:json 
        keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.actions.flexibleActionsViewModel.actionsRows[0].subscribeButtonViewModel.stateEntityStoreKey"];

    if (!mutationKey) {
        return nil; // we can't tell if we don't have this key.
    }
    
    NSArray *mutations = [TRJSONUtils arrayFromJSON:json 
        keyPath:@"frameworkUpdates.entityBatchUpdate.mutations"];


    //.payload.subscriptionStateEntity.subscribed
    BOOL isSubscribed = false;
    for (NSDictionary *mutation in mutations) {
        if ([mutation[@"entityKey"] isEqualToString:mutationKey]) {
            if ([TRJSONUtils boolFromJSON:mutation keyPath:@"payload.subscriptionStateEntity.subscribed"]) {
                isSubscribed = true;
            }
            break;
        }
    }

    
    if (!isSubscribed) {
        return nil;
    }
    
    NSString *displayName = [TRJSONUtils stringFromJSON:json keyPath:@"header.pageHeaderRenderer.pageTitle"];
    NSString *channelID = [TRJSONUtils stringFromJSON:json 
        keyPath:@"contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.browseEndpoint.browseId"];
    
    NSString *thumbUrl = [TRJSONUtils stringFromJSON:json 
        keyPath:@"header.pageHeaderRenderer.content.pageHeaderViewModel.image.decoratedAvatarViewModel.avatar.avatarViewModel.image.sources[0].url"];
    NSURL *thumbnailURL = thumbUrl ? [NSURL URLWithString:thumbUrl] : nil;
    
    id sub = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
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
    } else {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
            initWithDisplayName:displayName
            channelID:channelID
            type:1
            publishedDate:[NSDate date]
            updatedDate:[NSDate date]
            countHint:0
            unreadCount:0 // todo: see if i can actually make this correct
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            thumbnailURL:thumbnailURL
        ] autorelease];
    }

    
    
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
    
    id sub = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
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
    } else {
        sub = [[[NSClassFromString(@"YTSubscription") alloc] 
            initWithDisplayName:@""
            channelID:channelID
            type:1
            publishedDate:[NSDate date]
            updatedDate:[NSDate date]
            countHint:0
            unreadCount:0 // todo: see if i can actually make this correct
            editURL:[NSURL URLWithString:@"https://youtube.com"]
            thumbnailURL:nil
        ] autorelease];
    }
    
    return sub;
}

@end
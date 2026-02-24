// myprofile.x
// TubeReplacer
//
// User profile request and parsing hooks

#include <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMyUserProfileWithAuth:(id)authentication {
    // Uses a special endpoint that returns account switcher data
    return [self requestWithURLString:@"https://m.youtube.com/getAccountSwitcherEndpoint" 
                       authentication:authentication];
}

%end

%hook YTGDataRequestFactory

-(id)requestForMyUserProfileWithAuth:(id)authentication {
    // Uses a special endpoint that returns account switcher data
    return [self requestWithURLString:@"https://m.youtube.com/getAccountSwitcherEndpoint" 
                       authentication:authentication];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService 

-(void)makeMyUserProfileRequestWithAuth:(id)auth responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id request;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"])  {
        request = [%c(YTGDataRequest) requestForMyUserProfileWithAuth:auth];
    } else {
        request = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestForMyUserProfileWithAuth:auth];

    }
    [self makeGETRequest:request 
              withParser:[self valueForKey:l(@"userProfileParser")] 
           responseBlock:responseBlock 
              errorBlock:errorBlock];
}

%end

#pragma mark - Profile Parsing

%hook YTUserProfileParser
    
-(id)parseElement:(id)body error:(NSError *)error {
    if (![body isKindOfClass:[NSDictionary class]]) {
        NSLog(@"YTUserProfileParser: input is not NSDictionary");
        return nil;
    }
    
    NSDictionary *data = body;
    
    // Extract account info from the multi-page menu structure
    NSDictionary *accountInfo = [TRJSONUtils dictFromJSON:data 
        keyPath:@"data.actions[0].getMultiPageMenuAction.menu.multiPageMenuRenderer.sections[0].accountSectionListRenderer.contents[0].accountItemSectionRenderer.contents[0].accountItem"];
    
    if (!accountInfo) {
        NSLog(@"YTUserProfileParser: Could not find account info");
        return nil;
    }
    
    NSString *displayName = [TRJSONUtils stringFromJSON:accountInfo keyPath:@"accountName.simpleText"];
    
    NSString *channelHandle = [TRJSONUtils stringFromJSON:accountInfo keyPath:@"channelHandle.simpleText"];
    if ([channelHandle hasPrefix:@"@"]) {
        channelHandle = [channelHandle substringFromIndex:1];
    }
    
    NSString *bylineText = [TRJSONUtils stringFromJSON:accountInfo keyPath:@"accountByline.simpleText"];
    int subscribersCount = (int)[TRJSONUtils numberFromText:bylineText];
    
    NSString *thumbUrl = [TRJSONUtils stringFromJSON:accountInfo keyPath:@"accountPhoto.thumbnails[0].url"];
    NSURL *thumbnail = thumbUrl ? [NSURL URLWithString:thumbUrl] : nil;
    
    YTUserProfile *profile = nil;
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        profile = [[[%c(YTUserProfile) alloc] 
            initWithUsername:channelHandle
            displayName:displayName
            age:0
            thumbnailURL:thumbnail
            uploadsURL:[NSURL URLWithString:@"https://youtube.com"]
            playlistsURL:[NSURL URLWithString:@"https://youtube.com"]
            uploadedCount:0
            favoritesCount:0
            subscriptionsCount:0
            uploadViewsCount:0
            channelViewsCount:0
            subscribersCount:subscribersCount
        ] autorelease];
    } else if ([version() isEqualToString:@"1.1.0"])  {
        profile = [[[%c(YTUserProfile) alloc] 
            initWithDisplayName:displayName
            channelID:channelHandle
            age:0
            thumbnailURL:thumbnail
            uploadsURL:[NSURL URLWithString:@"https://youtube.com"]
            playlistsURL:[NSURL URLWithString:@"https://youtube.com"]
            uploadedCount:0
            favoritesCount:0
            subscriptionsCount:0
            uploadViewsCount:0
            channelViewsCount:0
            subscribersCount:subscribersCount
        ] autorelease];
    } else {
        profile = [[[%c(YTUserProfile) alloc] 
            initWithDisplayName:displayName
            hasChannel:true // i mean probably lmao
            channelID:channelHandle
            eligibleForChannel:true // i mean i guess??????
            googlePlusUserID:nil // google plus is colon three
            age:0
            thumbnailURL:thumbnail
            uploadsURL:[NSURL URLWithString:@"https://youtube.com"]
            playlistsURL:[NSURL URLWithString:@"https://youtube.com"]
            uploadedCount:0
            favoritesCount:0
            subscriptionsCount:0
            uploadViewsCount:0
            channelViewsCount:0
            subscribersCount:subscribersCount
        ] autorelease];
    }
    
    return profile;
}

%end
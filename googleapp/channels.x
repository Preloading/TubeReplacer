// channels.x
// TubeReplacer
//
// Channel page request and parsing hooks

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"
// #import <execinfo.h>
// #import <mach-o/dyld.h>

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForChannelWithID:(NSString*)channelId {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" 
                       authentication:nil 
                                 body:[TRRequestBuilder browseBodyWithId:channelId 
                                                                  params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataRequestFactory

-(id)requestForChannelWithID:(NSString*)channelId {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" 
                       authentication:nil 
                                 body:[TRRequestBuilder browseBodyWithId:channelId 
                                                                  params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeChannelRequestWithID:(NSString*)channelId responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    // intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    // NSLog(@"ASLR Slide Offset: 0x%lx\n", (unsigned long)slide);
    // void *callstack[128];
    // int frames = backtrace(callstack, 128);
    // char **symbols = backtrace_symbols(callstack, frames);
    // NSMutableString *callstackString = [NSMutableString stringWithFormat:@"uwu >_<"];
    // for (int i = 0; i < frames; i++) {
    // [callstackString appendFormat:@"%s\n", symbols[i]];
    // }
    // NSLog(@"%@", callstackString);


    id cache = [[self channelCache] objectForKey:channelId];
    if (cache) {
        if (cache == [NSNull null]) {
            cache = nil;
        }
        [self performResponseBlock:responseBlock response:cache];
    } else {
        NSLog(@"Channel cache miss!");
        id url = nil;
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            url = [%c(YTGDataRequest) requestForChannelWithID:channelId];
            
        } else {
            url = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestForChannelWithID:channelId];
        }
        [self makePOSTRequest:url 
                    withParser:[self valueForKey:l(@"channelParser")] 
                    responseBlock:responseBlock 
                    errorBlock:errorBlock];
    }
}

%end

#pragma mark - Channel Parsing

%hook YTChannelParser

-(id)parseElement:(id)body error:(NSError*)error {
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRChannelTranslator *translator = [[[TRChannelTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id channel = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRChannelTranslator error: %@", translatorError);
            error = translatorError;
        }
        
        return channel;
    } else {
        NSLog(@"YTChannelParser: input is not NSDictionary");
        return nil;
    }
}

%end

%hook YTEventsFeedController 

// optimization: instead of doing the channel request 20 thousand times, we sneak the channel's icon inside the request and use that instead.
-(void)loadAvatarForEvent:(YTEvent*)entry {
    if ([entry action] != 9) {
        NSURL *profilePicture = nil;
        if ([[[entry video] uploaderChannelID] isEqualToString:[entry authorUserID]]) {
            profilePicture = objc_getAssociatedObject([entry video], "uploaderChannelProfilePicture");
        }

        if (profilePicture) {
            YTImageService *imageService = [(YTServices*)[self valueForKey:l(@"services")] imageService];
            [imageService makeImageRequestWithURL:profilePicture responseBlock:^(id image, BOOL unk2) {
                [self setAvatar:image forEntry:entry];
                [self updateCellForEntry:entry animated:YES];
            } errorBlock:^(NSError *error){
                
            }];
        } else {
            return %orig;
        }
    }
}

-(void)loadChannelThumbnailForEvent:(YTEvent*)entry {
    if (![entry isYouTubeAuthored]) {
        NSURL *profilePicture = nil;
        if ([[[entry video] uploaderChannelID] isEqualToString:[entry authorUserID]]) {
            profilePicture = objc_getAssociatedObject([entry video], "uploaderChannelProfilePicture");
        }

        if (profilePicture) {
            YTImageService *imageService = [self valueForKey:l(@"imageService")];
            [imageService makeImageRequestWithURL:profilePicture responseBlock:^(id image, BOOL unk2) {
                [self setChannelThumbnail:image forEntry:entry];
                [self updateCellForEntry:entry animated:YES];
            } errorBlock:^(NSError *error){
                
            }];
        } else {
            return %orig;
        }
    }
}

-(void)loadUploaderThumbnailWithID:(NSString*)channelId forEntry:(YTEvent*)entry {
    // NSLog(@"entry class type -> %@", NSStringFromClass([entry class]));
    NSURL *profilePicture = nil;
    if ([[[entry video] uploaderChannelID] isEqualToString:[entry authorUserID]]) {
        profilePicture = objc_getAssociatedObject([entry video], "uploaderChannelProfilePicture");
    }

    BOOL hasSel = NO;
    if ([version() isEqualToString:@"1.2.1"]) {
        hasSel = [(id<YTFeedViewProtocol>)[self valueForKey:l(@"feedView")] cellsRespondToSelector:@selector(setUploaderThumbnail:animated:)];
    } else {
        hasSel = [(id<YTFeedViewProtocol>)[self valueForKey:l(@"feedView")] cellsRespondToSelector:@selector(setUploaderThumbnail:animated:) forEntry:entry];
    }

    if (profilePicture) {
        if (channelId != nil
            && hasSel != NO) {

                YTImageService *imageService = [self valueForKey:l(@"imageService")];
                [imageService makeImageRequestWithURL:profilePicture responseBlock:^(id image, BOOL unk2) {
                    [self setUploaderThumbnail:image forEntry:entry];
                    [self updateCellForEntry:entry animated:YES];
                } errorBlock:^(NSError *error){
                    
                }];
        }
        
    } else {
        return %orig;
    }
}

// 2.0.0
-(void)loadChannelThumbnailForEvent:(YTEvent*)entry inCell:(YTEventCell_iPhone*)inCell { // YTEventCell_iPhone *should be* compatible with the ipad version
    if ([entry isYouTubeAuthored]) {
        [inCell setChannelThumbnail:[self valueForKey:l(@"YouTubeSystemChannelImage")] animated:0];
    } else {
        NSURL *profilePicture = nil;
        if ([[[entry video] uploaderChannelID] isEqualToString:[entry authorUserID]]) {
            profilePicture = objc_getAssociatedObject([entry video], "uploaderChannelProfilePicture");
        }

        if (profilePicture) {
            YTImageService *imageService = [self valueForKey:l(@"imageService")];
            [imageService makeImageRequestWithURL:profilePicture responseBlock:^(id image, BOOL unk2) {
                [inCell setChannelThumbnail:image animated:0];
            } errorBlock:^(NSError *error){
                
            }];
        } else {
            return %orig;
        }
    }
}



%end

%hook YTVideosFeedController
    
-(void)loadChannelThumbnailForVideo:(YTVideo*)entry inCell:(YTEventCell_iPhone*)inCell { // YTEventCell_iPhone *should be* compatible with the ipad version
    NSURL *profilePicture = objc_getAssociatedObject(entry, "uploaderChannelProfilePicture");

    if (profilePicture && [inCell respondsToSelector:@selector(setChannelThumbnail:animated:)]) {
        YTImageService *imageService = [self valueForKey:l(@"imageService")];
        [imageService makeImageRequestWithURL:profilePicture responseBlock:^(id image, BOOL unk2) {
            [inCell setChannelThumbnail:image animated:0];
        } errorBlock:^(NSError *error){
            
        }];
    } else {
        return %orig;
    }
}

%end
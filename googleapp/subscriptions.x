// subscriptions.x
// TubeReplacer
//
// Subscription-related hooks for viewing and managing subscriptions

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMySubscriptionsWithAuth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder browseBodyWithId:@"FEchannels" 
                                                                  params:nil 
                                                                  client:[YoutubeClientType webClient]]];
}

+(id)requestForMySubscriptionWithChannelID:(NSString*)channelId auth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false&subscription=true" 
                       authentication:authentication 
                                 body:[TRRequestBuilder browseBodyWithId:channelId 
                                                                  params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

+(id)requestToSubscribeWithChannelID:(NSString*)channelId authentication:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/subscription/subscribe?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder subscribeBodyWithChannelId:channelId 
                                                                            client:[YoutubeClientType webMobileClient]]];
}

+(id)requestToUnsubscribeWithSubscription:(YTSubscription*)subscription authentication:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/subscription/unsubscribe?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder subscribeBodyWithChannelId:[subscription channelID] 
                                                                            client:[YoutubeClientType webMobileClient]]];
}
%end

%hook YTGDataRequestFactory

-(id)requestForMySubscriptionsWithAuth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder browseBodyWithId:@"FEchannels" 
                                                                  params:nil 
                                                                  client:[YoutubeClientType webClient]]];
}

-(id)requestForMySubscriptionWithChannelID:(NSString*)channelId auth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder browseBodyWithId:channelId 
                                                                  params:@"EgZzaG9ydHPyBgUKA5oBAA%3D%3D" 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

-(id)requestToSubscribeWithChannelID:(NSString*)channelId authentication:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/subscription/subscribe?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder subscribeBodyWithChannelId:channelId 
                                                                            client:[YoutubeClientType webMobileClient]]];
}

-(id)requestToUnsubscribeWithSubscription:(YTSubscription*)subscription authentication:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/subscription/unsubscribe?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder subscribeBodyWithChannelId:[subscription channelID] 
                                                                            client:[YoutubeClientType webMobileClient]]];
}
%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeMySubscriptionRequestWithChannelID:(NSString*)channelId authentication:(id)authentication responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    // todo: uncomment this out, since this is only blanked for testing
    id cache = [[self valueForKey:l(@"subscriptionCache")] objectForKey:channelId];
    
    if (cache) {
        if (cache == [NSNull null]) {
            cache = nil;
        }
        [self performResponseBlock:responseBlock response:cache];
    } else {
        id request = nil;
        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            request = [%c(YTGDataRequest) requestForMySubscriptionWithChannelID:channelId auth:authentication];
        } else {
            request = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestForMySubscriptionWithChannelID:channelId auth:authentication];
        }
        [self makePOSTRequest:request 
                   withParser:[self valueForKey:l(@"subscriptionParser")] 
                responseBlock:responseBlock 
                   errorBlock:errorBlock];
    }
}

-(void)makeMySubscriptionsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:l(@"subscriptionPageParser")] 
            responseBlock:responseBlock
               errorBlock:errorBlock];               
}

-(void)makeSubscribeRequestWithChannelID:(id)request authentication:(id)authentication responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
    NSLog(@"makeSubscribeRequestWithChannelID:request -> %@", request);
    void (^originalResponseBlock)(id) = [responseBlock copy];
    void (^newResponseBlock)(id) = ^(id response) {
        YTChannel *channel = [[self channelCache] objectForKey:request];

        [response setValue:[channel displayName] forKey:l(@"displayName")];
        [response setValue:[channel thumbnailURL] forKey:l(@"thumbnailURL")];


        // for (YTEvent *event in [response entries]) {
        //     [event setValue:@5 forKey:@"action_"];
        //     [event setValue:[request URL] forKey:@"authorUserID_"];
        //     [event setValue:[[[self channelCache] objectForKey:[request URL]] displayName] forKey:@"authorDisplayName_"];
        //     [[event video] setValue:[request URL] forKey:@"uploaderChannelID_"];
        //     [[event video] setValue:[ displayName] forKey:@"uploaderDisplayName_"];
        // }

        if (originalResponseBlock) {
            originalResponseBlock(response);
        }
    };
    %orig(request, authentication, newResponseBlock, errorBlock);
}

-(void)makeUnsubscribeRequestWithSubscription:(YTSubscription*)subscription authentication:(id)authentication responseBlock:(void (^)(void))responseBlock errorBlock:(void (^)(NSError *error))errorBlock
{
  id request = nil;
  
  if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
    request = [%c(YTGDataRequest) requestToUnsubscribeWithSubscription:subscription authentication:authentication];
  } else {
    request = [(YTGDataRequestFactory*)[self valueForKey:l(@"GDataRequestFactory")] requestToUnsubscribeWithSubscription:subscription authentication:authentication];
  }

    void (^successBlock)(id) = ^(id response) {
        [self clearSubscriptionDependentCaches];

        id channelID = [subscription channelID];
        [[self valueForKey:l(@"subscriptionCache")] setObject:[NSNull null] forKey:channelID];

        // Notify the app that subscription changed (now unsubscribed)

        if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
            [%c(YTNotificationCenter) notifySubscriptionChange:subscription
                                             subscribed:NO];
        } else {
            [self notifySubscriptionDidChange:subscription
                                             subscribed:NO];
        }
        

        if (responseBlock) {
            responseBlock();
        }
    };

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        if ([error code] == 404) {
            if (responseBlock) {
                responseBlock();
            }
        } else {
            if (errorBlock) {
                errorBlock(error);
            }
        }
    };
  [self makePOSTRequest:request withParser:nil responseBlock:successBlock errorBlock:failureBlock];
//   ^(id response) {
//     [self clearSubscriptionDependentCaches];
//     // v3 = *(void **)(block->superSelf + 28);
//     [[self valueForKey:l(@"subscriptionPageCache")] setObject:[NSNull null] forKey:channelId];
//     // [%c(YTNotificationCenter) notifySubscriptionChange: subscribed:0];
//     // (*(void (**)(void))(block->responseBlock + 12))();
//   } 
}

%end

#pragma mark - Subscription Parsing

%hook YTSubscriptionParser
    
-(id)parseElement:(id)body error:(NSError *)error {
    // Use unified translator for subscription parsing
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRSubscriptionTranslator *translator = [[[TRSubscriptionTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id subscription = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRSubscriptionTranslator error: %@", translatorError);
        }
        
        return subscription;
    }
    
    NSLog(@"YTSubscriptionParser: input is not NSDictionary");
    return nil;
}

%end
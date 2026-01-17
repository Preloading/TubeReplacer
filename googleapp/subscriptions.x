// subscriptions.x
// TubeReplacer
//
// Subscription-related hooks for viewing and managing subscriptions

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestForMySubscriptionsWithAuth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" 
                       authentication:authentication 
                                 body:[TRRequestBuilder browseBodyWithId:@"FEsubscriptions" 
                                                                  params:nil 
                                                                  client:[YoutubeClientType webMobileClient]]];
}

+(id)requestForMySubscriptionWithChannelID:(NSString*)channelId auth:(id)authentication {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse?prettyprint=false" 
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

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeMySubscriptionRequestWithChannelID:(NSString*)channelId authentication:(id)authentication responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id cache = [[self valueForKey:@"subscriptionCache_"] objectForKey:channelId];
    
    if (cache) {
        if (cache == [NSNull null]) {
            cache = nil;
        }
        [self performResponseBlock:responseBlock response:cache];
    } else {
        id request = [%c(YTGDataRequest) requestForMySubscriptionWithChannelID:channelId auth:authentication];
        [self makePOSTRequest:request 
                   withParser:[self valueForKey:@"subscriptionParser_"] 
                responseBlock:responseBlock 
                   errorBlock:errorBlock];
    }
}

-(void)makeMySubscriptionsRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"subscriptionPageParser_"] 
            responseBlock:responseBlock
               errorBlock:errorBlock];               
}

-(void)makeUnsubscribeRequestWithSubscription:(NSString*)channelId authentication:(id)authentication responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  id request; // r0

  request = [%c(YTGDataRequest) requestToUnsubscribeWithSubscription:channelId authentication:authentication];
  [self makePOSTRequest:request withParser:nil responseBlock:^(id response) {
    [self clearSubscriptionDependentCaches];
    // v3 = *(void **)(block->superSelf + 28);
    [[self valueForKey:@"subscriptionPageCache_"] setObject:[NSNull null] forKey:channelId];
    // [%c(YTNotificationCenter) notifySubscriptionChange: subscribed:0];
    // (*(void (**)(void))(block->responseBlock + 12))();
  } errorBlock:errorBlock];
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
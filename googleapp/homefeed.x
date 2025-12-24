// FEsubscriptions

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

/// Logged out standard fields

// -[YTVideoParser parseElement:error:]

// TO LOOK AT
// -[YTVideoParser parseElement:error:]


// called at -[YTCategoryViewController_iPhone loadView]


%hook YTGDataService

// uploads only
-(void)makeMySubscriptionUploadsRequest:(YTGDataRequest*)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
  %log;
  [self makePOSTRequest:request withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end

%hook YTGDataRequest

// uploads only
+(id)requestForMySubscriptionUploadsWithAuth:(id)authentication safeSearch:(BOOL)isSafeSearch
{
  return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"FEsubscriptions" params:nil]];
}

// highlights
+(id)requestForMySubscriptionUpdatesWithAuth:(id)authentication
{
  return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/browse"] authentication:authentication body:[YoutubeRequestClient browseBody:@"FEwhat_to_watch" params:nil]];
}

%end


/// -[YTPageParser parseElement:error:]
/// 


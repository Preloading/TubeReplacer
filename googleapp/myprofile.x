#include <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

%hook YTGDataRequest

+(id)requestForMyUserProfileWithAuth:(id)authentication
{
    // return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/browse" authentication:authentication body:[YoutubeRequestClient browseBody:@"FElibrary" params:nil]];
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/account/account_menu?prettyPrint=false" authentication:authentication body:[YoutubeRequestClient clientOnlyWithClient:[YoutubeClientType webClient]]];
}
// FElibrary
%end

%hook YTGDataService 

-(void)makeMyUserProfileRequestWithAuth:(id)auth responseBlock:(id)responseBlock errorBlock:(id)errorBlock
{
  id request = [%c(YTGDataRequest) requestForMyUserProfileWithAuth:auth];
  [self makePOSTRequest:request withParser:[self valueForKey:@"userProfileParser_"] responseBlock:responseBlock errorBlock:errorBlock];
}

%end
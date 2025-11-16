#import <Foundation/Foundation.h>

// i accidently mixed this up, so that's here for now.

// %hook YTGDataService

// //change from a GET to a POST, since youtubei browse only accepts POST
// -(void)makeVideosStandardFeedRequest:(id)request responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
//   [self makePOSTRequest:request withParser:self->videoPageParser_ cache:self->videoPageCache_ responseBlock:responseBlock errorBlock:errorBlock];
// }


// + (id)requestForChannelsWithStandardFeed:(int)requestingType;
// {
//   NSString *forData = nil;
//   NSString *v5; // r0
//   NSString *userCountryCode; // r6
//   GTMURLBuilder *v7; // r0
//   GTMURLBuilder *v8; // r0
//   NSURL *v9; // r0

//   if ( requestingType == 1 )
//   {
//     forData = @"most_subscribed";
//   }
//   else
//   {
//       forData = @"most_viewed";
//   }
//   userCountryCode = [[%c(YTUtils) userCountryCode] uppercaseString];
//   if ([%c(YTGDataRequest) regionHasLocalizedStandardFeeds:userCountryCode])
//   {
//     v7 = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"standardfeeds/%@/%@",userCountryCode,forData];
//   }
//   else
//   {
//     v7 = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"standardfeeds/%@",forData];
//   }
//   v8 = +[GTMURLBuilder builderWithString:v7];
//   v9 = -[v8 URL];
//   return [self requestWithURL:v9];
// }

// %end


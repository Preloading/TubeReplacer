// parsing.x
// TubeReplacer
//
// Data format detection and routing (XML vs JSON)
// Also handles subscription caching for POST requests

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "general.h"

#pragma mark - Format Detection & Parsing

%hook YTTBParser

-(id)parse:(NSData*)rawData error:(NSError **)error {
    if (!rawData || [rawData length] == 0) {
        NSLog(@"TubeReplacer: Empty data received");
        return nil;
    }

    // NSLog(@"rawData -> %@", rawData);
    
    const unsigned char* bytes = [rawData bytes];
    NSUInteger length = [rawData length];
    NSData *cleanData = rawData;

    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if (preferences[@"DebugNetworkRequests"]) {
        NSString *path = @"/var/mobile/Library/Preferences/tubereplacer_network_log.txt";
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        }
        NSMutableData *dataToWrite = [NSMutableData data];
        [dataToWrite appendData:[@"========Tub3R3p1@c3r_Un1qu3-S3p3r@t0r_!&479(21!#9hfa@a1===============" dataUsingEncoding:NSUTF8StringEncoding]];
        [dataToWrite appendData:rawData];

        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:dataToWrite];
        [fileHandle closeFile];
    }
    
    // Strip Google's anti-XSS prefix: )]}'\\n
    // This is prepended to JSON responses to prevent JSONP hijacking
    if (length >= 5 && 
        bytes[0] == ')' && 
        bytes[1] == ']' && 
        bytes[2] == '}' && 
        bytes[3] == '\'' && 
        bytes[4] == '\n') {
        bytes += 5;
        length -= 5;
        cleanData = [NSData dataWithBytes:bytes length:length];
    }
    
    // Detect format by first character
    if (length > 0 && bytes[0] == '<') {
        // XML format - use legacy TBXML parser
        NSLog(@"TubeReplacer: XML detected, using TBXML");
        TBXML *xml = [%c(TBXML) tbxmlWithXMLData:cleanData error:error];
        if ([xml rootXMLElement]) {
            YTTBXMLElement *rootElement = [[[%c(YTTBXMLElement) alloc] 
                initWithElement:[xml rootXMLElement]] autorelease];
            return [self parseElement:rootElement error:error];
        }
        return nil;
    } 
    else if (length > 0 && bytes[0] == '{') {
        // JSON format - parse and route to translators
        NSLog(@"TubeReplacer: JSON detected");
        id json = [NSJSONSerialization 
            JSONObjectWithData:cleanData 
            options:NSJSONReadingMutableContainers 
            error:error];
        
        if (!json) {
            NSLog(@"TubeReplacer: JSON parsing failed");
            return nil;
        }
        
        // Route to parseElement which will use the appropriate translator
        return [self parseElement:json error:error];
    } 
    else {
        NSLog(@"TubeReplacer: Unknown format, first byte: 0x%02X", bytes[0]);
        return nil;
    }
}

%end

#pragma mark - POST Request Caching

%hook YTGDataService

- (void)makePOSTRequest:(YTGDataRequest *)request
             withParser:(id)parser
          responseBlock:(id)responseBlock
             errorBlock:(id)errorBlock {
    
    // Wrap the response block to intercept certain responses for caching
    void (^originalResponseBlock)(id) = [responseBlock copy];

    void (^wrappedResponseBlock)(id) = ^(id response) {
        // Cache subscriptions when fetching subscription page
        NSLog(@"parser -> %@", parser);
        if (parser == [self valueForKey:l(@"subscriptionPageParser")]) {
            id cache = [self valueForKey:l(@"subscriptionCache")];
            [cache setValue:@100000 forKey:l(@"countLimit")];
            [self cacheSubscriptionsFromSubscriptionPage:response];
        }

        if (parser == [self valueForKey:l(@"channelParser")]) {
            id cache = [self channelCache];
            [cache setValue:@100000 forKey:l(@"countLimit")];
            [self cacheChannel:response];
        }

        

        if (parser == [self valueForKey:l(@"channelPageParser")]) {
            id cache = [self channelCache];
            for (id channel in [response entries]) {
                [cache setValue:@100000 forKey:l(@"countLimit")];
                [self cacheChannel:channel];
            }
            
        }

        if (originalResponseBlock) {
            originalResponseBlock(response);
        }
    };

    %orig(request, parser, wrappedResponseBlock, errorBlock);
    
    [originalResponseBlock release];
}

%end

// fixes views & other values being capped at 32bit unsigned int limit
%hook YTUtils
+(id)localizedCount:(uint64_t)number
{
  return [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithLongLong:number] numberStyle:1];
}
%end

%hook YTUIUtils
+(id)localizedCount:(uint64_t)number
{
    // NSLog(@"number => %lld", number);
  return [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithLongLong:number] numberStyle:1];
}
%end

@interface YTLikesDislikesView : NSObject
- (void)setVideo:(id)video userLike:(BOOL)userLike userDislike:(BOOL)userDislike;
@end

// yeah fun :D
%hook YTVideoInfoCell_iPhone
-(void)setVideo:(YTVideo*)video userLike:(BOOL)userLike userDislike:(BOOL)userDislike
{
    if ([version() isEqualToString:@"1.1.0"] || [version() isEqualToString:@"1.2.1"]) {
        return %orig;
    }
  // title
  [(UILabel*)[self valueForKey:l(@"titleLabel")] setText:[video title]];

  // upload date
  NSDate *uploadedDate = nil;
  if ([video publishedDate])
    uploadedDate = [video publishedDate];
  else
    uploadedDate = [video uploadedDate];

  NSString *formattedUploadDate = [NSDateFormatter localizedStringFromDate:uploadedDate dateStyle:2 timeStyle:0];

  [(UILabel*)[self valueForKey:l(@"dateLabel")] setText:[NSString stringWithFormat:localizedStringForKey(@"video_info.published_date"), formattedUploadDate]];

  [(YTLikesDislikesView*)[self valueForKey:l(@"likesDislikesView")] setVideo:video userLike:userLike userDislike:userDislike];
  if ([video videoDescription])
  {
    [(UILabel*)[self valueForKey:l(@"descriptionLabel")] setText:[video videoDescription]];
  }

  if ( ![video isLive] )
  {
    // viewCount = [video viewCount];
    // -[YTVideoInfoCell_iPhone updateViewCountLabelWithViewCount:isLive:](
    //   self,
    //   viewCount,
    //   0);

      // reimplementation of -[YTVideoInfoCell_iPhone updateViewCountLabelWithViewCount:isLive:], since it gets passed in an int, not an int64, meaning we lose precision and it becomes negative

        [(YTAttributedTextLabel*)[self valueForKey:l(@"viewCountLabel")] clearText];
        if ( ![video isLive] || [video viewCount] )
        {
            NSString *formattedCount = [%c(YTUIUtils) localizedCount:[video viewCount]];
            NSString *localizationKey;
            if ( [video isLive] )
                localizationKey = @"video_info.live_viewers";
            else
                localizationKey = @"video_info.views";
            NSString *viewCountText = localizedStringForKey2(localizationKey, [video viewCount]);

            [(YTAttributedTextLabel*)[self valueForKey:l(@"viewCountLabel")] appendText:[formattedCount stringByAppendingString:@"\n"]
                                   withAttributes:[%c(YTAttributedTextLabel) attributesWithFont:[UIFont mediumLightFont] color:[%c(YTColor) XDarkTextColor] paragraphSpacingBefore:0 textAlignment:1]
                                ];

            [(YTAttributedTextLabel*)[self valueForKey:l(@"viewCountLabel")] appendText:viewCountText 
                                                           withAttributes:[%c(YTAttributedTextLabel) attributesWithFont:[UIFont XSmallLightFont] color:[%c(YTColor) mediumTextColor] paragraphSpacingBefore:0 textAlignment:1]
                                                    ];
        }
  }
  [self setValue:@1 forKey:l(@"layoutChanged")];
  [self setNeedsLayout];
}


-(void)updateViewCountLabelWithViewCount:(int)viewCount isLive:(BOOL)isLive {
    NSLog(@"updateViewCountLabelWithViewCount was called! This function should hopefully no longer be called, as it has a 32bit limit.");
    return %orig;
}
%end

@interface PendingRequestKey

-(id)keyWithRequest:(id)a3 authorizer:(id)a4;

@end

// i hate you youtube for not writing this correctly!!!!
%hook YTBaseService

-(void)performHTTPRequest:(id)request withAuthorizer:(id)withAuthorizer completionBlock:(id)completionBlock
{
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        return %orig;
    } else {
        id copiedCompletionBlock = [completionBlock copy];

        NSBlockOperation *operation =
        [NSBlockOperation blockOperationWithBlock:^{

            id requestKey =
            [%c(PendingRequestKey) keyWithRequest:request authorizer:withAuthorizer];

            id completionBlock2 = [copiedCompletionBlock autorelease];

            NSMutableArray *v6 =
            [NSMutableArray arrayWithObject:completionBlock2];

            [[self valueForKey:l(@"pendingRequests")]
                setObject:v6 forKey:requestKey];

            GTMHTTPFetcher *fetcher =
            [[self valueForKey:l(@"httpFetcherService")]
                fetcherWithRequest:request];

            [fetcher setAuthorizer:withAuthorizer];

            [fetcher beginFetchWithCompletionHandler:
            ^(NSData *data, NSError *error) {

                for (void (^block)(NSData *, NSError *) in v6) {
                    block(data, error);
                }

                [(NSMutableDictionary*)
                [self valueForKey:l(@"pendingRequests")]
                removeObjectForKey:requestKey];
            }];
        }];

        [[NSOperationQueue mainQueue] addOperation:operation];
    }
}
%end
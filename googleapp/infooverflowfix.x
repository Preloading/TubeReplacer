#import <Foundation/Foundation.h>
#import "appheaders.h"
#import "general.h"

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
-(void)sizeToFit;
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

%hook YTVideoInfoLeftView_iPad
-(void)setVideo:(YTVideo*)video {
    if ([version() isEqualToString:@"1.1.0"] || [version() isEqualToString:@"1.2.1"]) {
        return %orig;
    }

    [[self valueForKey:l(@"video")] autorelease];
    [self setValue:[video retain] forKey:l(@"video")];
    [(UILabel*)[self valueForKey:l(@"titleLabel")] setText:[video title]];

    NSDate *uploadedDate;
    if ([video publishedDate])
        uploadedDate = [video publishedDate];
    else
        uploadedDate = [video uploadedDate];
    
    [(UILabel*)[self valueForKey:l(@"dateLabel")] setText:[NSString stringWithFormat:localizedStringForKey(@"video_info.published_date"),
                        [NSDateFormatter localizedStringFromDate:uploadedDate dateStyle:2 timeStyle:0]
                    ]];
    [(UILabel*)[self valueForKey:l(@"dateLabel")] sizeToFit];
    [(UILabel*)[self valueForKey:l(@"viewsLabel")] setText:@""];
    if (![video isLive])
    {
        NSString *localizationKey = nil;
        if ( ![video isLive] )
            localizationKey = @"video_info.num_views";
        // else if ( [video viewCount] )
        else
            localizationKey = @"video_info.live_viewers";
    
        [(UILabel*)[self valueForKey:l(@"viewsLabel")] setText:[NSString stringWithFormat:localizedStringForKey2UILib(localizationKey, [video viewCount]), [%c(YTUIUtils) localizedCount:[video viewCount]]]];
        [(UILabel*)[self valueForKey:l(@"viewsLabel")] sizeToFit];
        // v12 = ;
        // -[self updateViewCountLabelWithViewCount:[video viewCount] isLive:0](
        // self,
        // v12,
        // 0);
    }
    [(YTLikesDislikesView*)[self valueForKey:l(@"likesDislikesView")] setVideo:video userLike:0 userDislike:0];
    [(YTLikesDislikesView*)[self valueForKey:l(@"likesDislikesView")] sizeToFit];
    if ([video videoDescription]) {
        [(NIAttributedLabel*)[self valueForKey:@"descriptionLabel"] setText:[video videoDescription]];
    }
}

%end

// 2.0.0+
%hook YTVideoInfoCell

-(void)setVideo:(YTVideo*)video userLike:(BOOL)userLike userDislike:(BOOL)userDislike
{
    [(UILabel*)[self valueForKey:l(@"titleLabel")] setText:[video title]];

    NSDate *publishedDate;
    if ([video publishedDate])
        publishedDate = [video publishedDate];
    else
        publishedDate = [video uploadedDate];

    NSString *formattedDate = [NSDateFormatter localizedStringFromDate:publishedDate dateStyle:2 timeStyle:0];

    // v30 = ;
    [(YTLikesDislikesView*)[self valueForKey:l(@"likesDislikesView")] setVideo:video userLike:userLike userDislike:userDislike];

    int datePostedLength = [formattedDate length];
    if ( [[video videoDescription] length] )
    {
        [(NIAttributedLabel*)[self valueForKey:l(@"descriptionLabel")] setText:[NSString stringWithFormat:@"%@  ·  %@", formattedDate, [video videoDescription]]];
        datePostedLength += 3;
    }
    else
    {
        [(NIAttributedLabel*)[self valueForKey:l(@"descriptionLabel")] setText:formattedDate];
    }
    [(NIAttributedLabel*)[self valueForKey:l(@"descriptionLabel")] setTextColor:[%c(YTColor) XDarkTextColor] range:NSMakeRange(0, datePostedLength)];
    if (![video isLive])
    {
        [(UILabel*)[self valueForKey:l(@"viewCountLabel")] setText:nil];
        if ( ![video isLive] || [video viewCount] )
        {
            NSString *formattedCount = [%c(YTUIUtils) localizedCount:[video viewCount]];
            NSString *viewCountText;
            if ( [video isLive] )
                viewCountText = localizedStringForKey2(@"video_info.live_viewers", [video viewCount]);
            else
                viewCountText = localizedStringForKey2(@"video_info.views", [video viewCount]);

            [(UILabel*)[self valueForKey:l(@"viewCountLabel")] setText:[NSString stringWithFormat:@"%@ %@", formattedCount, viewCountText]];
            
        }
    }
    [self setNeedsLayout];
}

%end
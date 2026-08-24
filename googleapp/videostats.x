#import "appheaders.h"
#import "general.h"

%hook YTVideoStatsService
-(void)setCommonVSSParametersToBuilder:(GTMURLBuilder*)builder {
    %orig;
    NSDictionary *videoStatsInfo = objc_getAssociatedObject([self valueForKey:l(@"video")], "videoStatsInfo");
    for (NSString *queryKey in [videoStatsInfo allKeys]) {
        [builder setValue:videoStatsInfo[queryKey] forParameter:queryKey];
    }
}

%end
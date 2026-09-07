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

-(void)performSignedHTTPRequestWithBuilder:(id)builder {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
    if ([preferences[@"EnableVideoStats"] isEqual:@(YES)] || preferences[@"EnableVideoStats"] == nil) {
        return %orig;
    }
}

%end
#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "../YoutubeRequestClient.h"

@interface YTSearchFilters : NSObject {
    int sortBy_;
    int uploadDate_;
    int duration_;
    BOOL CC_;
}

- (void)setCC:(BOOL)fp8;
- (BOOL)hasCC;
- (void)setDuration:(int)fp8;
- (id)duration;
- (void)setUploadDate:(int)fp8;
- (id)uploadDate;
- (void)setSortBy:(int)fp8;
- (id)sortBy;
- (id)copyWithZone:(struct _NSZone *)fp8;

@end


%hook YTGDataRequest
+(id)requestForVideosWithSearchQuery:(NSString*) query languageCode:(NSString*)language filters:(YTSearchFilters*)filters safeSearch:(NSString*)safeSearchLevel
{
  // NSString *baseUrl; // r0
  // GTMURLBuilder *urlBuilder; // r5
  // id sortFilter; // r0
  // NSString *uploadDateFilter; // r0
  // NSString duration; // r0
  // id hasCC; // r0
  // NSURL *fullURL; // r0

  // baseUrl = [@"https://gdata.youtube.com/feeds/api/" stringByAppendingFormat:@"videos"];
  // urlBuilder = +[GTMURLBuilder builderWithString:](baseUrl);
  // -[GTMURLBuilder setValue:forParameter:](urlBuilder, query, CFSTR("q"));
  // -[GTMURLBuilder setValue:forParameter:](urlBuilder, language, CFSTR("hl"));
  // if ( filters )
  // {
  //   sortFilter = -[YTSearchFilters sortBy](filters);
  //   -[YTGDataRequest setSortByFilter:toURLBuilder:](self, sortFilter, urlBuilder);
  //   uploadDateFilter = -[YTSearchFilters uploadDate](filters);
  //   -[YTGDataRequest setUploadDateFilter:toURLBuilder:](
  //     self,
  //     uploadDateFilter,
  //     urlBuilder);
  //   duration = -[YTSearchFilters duration](filters);
  //   -[YTGDataRequest setDurationFilter:toURLBuilder:](self, duration, urlBuilder);
  //   hasCC = (id)-[YTSearchFilters hasCC](filters);
  //   -[YTGDataRequest setCCFilter:toURLBuilder:](self, hasCC, urlBuilder);
  // }
  // -[YTGDataRequest setQueryParametersToURLBuilder:withSafeSearch:](
  //   self,
  //   urlBuilder,
  //   safeSearchLevel);.
  if (filters) {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] authentication:nil body:[YoutubeRequestClient searchBody:query 
      sortBy:[filters sortBy] uploadDateFilter:nil duration:[filters duration] hasCC:[filters hasCC] withClient:[YoutubeClientType webMobileClient]]];
  } else {
    return [self requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/search?prettyprint=false"] authentication:nil body:[YoutubeRequestClient searchBody:query 
      sortBy:nil uploadDateFilter:nil duration:nil hasCC:false withClient:[YoutubeClientType webMobileClient]]];
  }
  

}
%end

%hook YTGDataService
-(void)makeSearchVideosRequest:(id)url responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
  [self makePOSTRequest:url withParser:[self valueForKey:@"videoPageParser_"] responseBlock:responseBlock errorBlock:errorBlock];
  // cache:[self valueForKey:@"videoPageCache_"] 
}
%end


// getvideo.x
// TubeReplacer
//
// Video detail request and parsing hooks
// Makes both /player (for streams) and /next (for likes) requests

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "appheaders.h"
#include "general.h"
#include "Translators/TRTranslators.h"

// Forward declare new methods for YTVideoParser
@interface YTVideoParser : NSObject
-(id)parseElement:(id)fp8 error:(id *)fp12;
// New methods
-(NSDictionary *)fetchNextDataForVideoId:(NSString *)videoId;
-(void)enhanceVideo:(id)video withNextData:(NSDictionary *)nextData;
@end

#pragma mark - Request Building

%hook YTGDataRequest

+(YTGDataRequest*)requestForVideoWithVideoID:(NSString*)videoId {
    // /player endpoint for video streams and basic info
    GTMURLBuilder *urlBuilder = [%c(GTMURLBuilder) builderWithString:@"https://www.youtube.com/youtubei/v1/player?noauth=1"];
    NSURL *fullURL = [urlBuilder URL];
    return [self requestWithURL:fullURL 
                 authentication:nil 
                           body:[TRRequestBuilder playerBodyWithVideoId:videoId 
                                                                 client:[YoutubeClientType androidClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeVideoRequestWithVideoID:(NSString*)videoId responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    id videoCache = [self valueForKey:@"videoCache_"];
    id cachedVideo = [videoCache objectForKey:videoId];
    
    if (cachedVideo) {
        [self performResponseBlock:responseBlock response:cachedVideo];
    } else {
        YTGDataRequest *request = [%c(YTGDataRequest) requestForVideoWithVideoID:videoId];
        [self makePOSTRequest:request 
                   withParser:[self valueForKey:@"videoParser_"] 
                responseBlock:responseBlock 
                   errorBlock:errorBlock];
    }
}

%end

#pragma mark - Video Parsing

%hook YTVideoParser

-(YTVideo*)parseElement:(id)body error:(NSError*)error {
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRVideoTranslator *translator = [[[TRVideoTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id video = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRVideoTranslator error: %@", translatorError);
        }
        
        // Try to get like counts from /next endpoint synchronously
        NSString *videoId = [TRJSONUtils stringFromJSON:body keyPath:@"videoDetails.videoId"];
        
        if (videoId && video) {
            @try {
                NSDictionary *nextData = [self fetchNextDataForVideoId:videoId];
                if (nextData) {
                    [self enhanceVideo:video withNextData:nextData];
                }
            } @catch (NSException *e) {
                NSLog(@"Failed to fetch /next data: %@", e);
            }
        }
        
        return video;
    } else {
        NSLog(@"YTVideoParser: input is not NSDictionary");
        return nil;
    }
}

%new
-(NSDictionary *)fetchNextDataForVideoId:(NSString *)videoId {
    // Synchronous request to /next endpoint
    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[TRRequestBuilder nextBodyWithVideoId:videoId 
                                                        client:[YoutubeClientType webMobileClient]]];
    
    NSURLResponse *response = nil;
    NSError *reqError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&reqError];
    
    if (reqError || !data) {
        NSLog(@"fetchNextDataForVideoId error: %@", reqError);
        return nil;
    }
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    return json;
}

%new
-(void)enhanceVideo:(id)video withNextData:(NSDictionary *)nextData {
    @try {
        // Navigate deep into the JSON structure manually to handle arrays properly
        NSDictionary *contents = [nextData objectForKey:@"contents"];
        NSDictionary *scwnr = [[contents objectForKey:@"singleColumnWatchNextResults"] objectForKey:@"results"];
        NSDictionary *results = [scwnr objectForKey:@"results"];
        NSArray *resultContents = [results objectForKey:@"contents"];
        
        if (![resultContents isKindOfClass:[NSArray class]]) return;

        for (NSDictionary *item in resultContents) {
            // Looking for slimVideoMetadataSectionRenderer
            NSDictionary *metadataSection = [item objectForKey:@"slimVideoMetadataSectionRenderer"];
            if (metadataSection) {
                NSArray *metaContents = [metadataSection objectForKey:@"contents"];
                if (![metaContents isKindOfClass:[NSArray class]]) continue;
                
                for (NSDictionary *metaItem in metaContents) {
                    // Looking for slimVideoActionBarRenderer
                    NSDictionary *actionBar = [metaItem objectForKey:@"slimVideoActionBarRenderer"];
                    if (actionBar) {
                        NSArray *buttons = [actionBar objectForKey:@"buttons"];
                        if (![buttons isKindOfClass:[NSArray class]]) continue;
                        
                        for (NSDictionary *buttonItem in buttons) {
                            // Looking for slimMetadataButtonRenderer
                            NSDictionary *smbr = [buttonItem objectForKey:@"slimMetadataButtonRenderer"];
                            if (smbr) {
                                // Looking for segmentedLikeDislikeButtonViewModel
                                NSDictionary *sldbvm = [[smbr objectForKey:@"button"] objectForKey:@"segmentedLikeDislikeButtonViewModel"];
                                if (sldbvm) {
                                    // Found the like/dislike button model!
                                    // 1. Get Like Status (for button highlighting)
                                    NSDictionary *likeButtonVM = [sldbvm objectForKey:@"likeButtonViewModel"];
                                    NSDictionary *likeStatusEntity = [likeButtonVM objectForKey:@"likeStatusEntity"];
                                    NSString *status = [likeStatusEntity objectForKey:@"likeStatus"]; // LIKE, DISLIKE, INDIFFERENT
                                    
                                    if (status) {
                                        // Store status as associated object since YTVideo has no property for it
                                        objc_setAssociatedObject(video, "TRLikeStatus", status, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                                        NSLog(@"Enhanced video with like status: %@", status);
                                    }

                                    // 2. Get Like Count
                                    NSDictionary *toggleButtonVM = [[[likeButtonVM objectForKey:@"likeButtonViewModel"]
                                                                    objectForKey:@"toggleButtonViewModel"]
                                                                    objectForKey:@"toggleButtonViewModel"];
                                                                    
                                    NSDictionary *defaultButton = [[toggleButtonVM objectForKey:@"defaultButtonViewModel"] objectForKey:@"buttonViewModel"];
                                    
                                    NSString *title = [defaultButton objectForKey:@"title"];
                                    if (title) {
                                        long likes = [TRJSONUtils numberFromText:title];
                                        if (likes > 0) {
                                            [video setValue:[NSNumber numberWithLong:likes] forKey:@"likesCount_"];
                                            NSLog(@"Enhanced video with %ld likes", likes);
                                        }
                                    }
                                    
                                    return; // Found it, done.
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: Check for other paths if the above specific one failed (e.g. different layout)
        // (Keep the previous logic or simplified version as backup if needed, but for now specific path is best)
        
    } @catch (NSException *e) {
        NSLog(@"Failed to parse /next data for likes: %@", e);
    }
}

%end

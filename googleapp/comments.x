// comments.x
// TubeReplacer
//
// Comment-related hooks for viewing and adding comments

#import <Foundation/Foundation.h>
#include "appheaders.h"
#include "Translators/TRTranslators.h"
#include "Translators/TRContinuation.h"
#include "general.h"

#pragma mark - Request Building

%hook YTGDataRequest

+(id)requestToAddCommentWithVideoID:(NSString*)videoId authentication:(id)authentication content:(NSString*)content {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/comment/create_comment?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder addCommentBodyWithVideoId:videoId 
                                                                      commentText:content 
                                                                           client:[YoutubeClientType webMobileClient]]];
}

%end

%hook YTGDataRequestFactory

-(id)requestToAddCommentWithVideoID:(NSString*)videoId authentication:(id)authentication content:(NSString*)content {
    return [self requestWithURLString:@"https://www.youtube.com/youtubei/v1/comment/create_comment?prettyPrint=false" 
                       authentication:authentication 
                                 body:[TRRequestBuilder addCommentBodyWithVideoId:videoId 
                                                                      commentText:content 
                                                                           client:[YoutubeClientType webMobileClient]]];
}

%end

#pragma mark - Request Dispatch

%hook YTGDataService

-(void)makeCommentsRequest:(id)originalRequest responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    YTGDataRequest *request = nil;
    
    if ([[originalRequest valueForKey:@"URL_"] isKindOfClass:[TRContinuation class]]) {
        TRContinuation *continuation = [originalRequest valueForKey:@"URL_"];
        if ([version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.0.1"]) {
            request = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
                authentication:nil // i hope this wont cause issues... 
                body:[TRRequestBuilder continueWithContext:[continuation token]
                        client:[YoutubeClientType webMobileClient]]];
        } else {
            request = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
                authentication:nil // i hope this wont cause issues... 
                body:[TRRequestBuilder continueWithContext:[continuation token]
                        client:[YoutubeClientType webMobileClient]]];
        }
        
    } else {
        NSString* videoId = [originalRequest valueForKey:@"URL_"];
        if ([version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.0.1"]) {
            request = [%c(YTGDataRequest) requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
                authentication:nil 
                body:[TRRequestBuilder commentsBodyWithVideoId:videoId 
                                                        sortBy:@"top" 
                                                        client:[YoutubeClientType webMobileClient]]];
        } else {
            request = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestWithURL:[NSURL URLWithString:@"https://www.youtube.com/youtubei/v1/next"] 
                authentication:nil 
                body:[TRRequestBuilder commentsBodyWithVideoId:videoId 
                                                        sortBy:@"top" 
                                                        client:[YoutubeClientType webMobileClient]]];
        }
    }    
    
    [self makePOSTRequest:request 
               withParser:[self valueForKey:@"commentPageParser_"] 
            responseBlock:responseBlock 
               errorBlock:errorBlock];
}

%end

#pragma mark - Comment Parsing

%hook YTCommentParser

-(id)parseElement:(NSDictionary*)body error:(NSError *)error {
    // Use unified translator for comment parsing
    if ([body isKindOfClass:[NSDictionary class]]) {
        TRCommentTranslator *translator = [[[TRCommentTranslator alloc] init] autorelease];
        NSError *translatorError = nil;
        id comment = [translator translateJSON:body error:&translatorError];
        
        if (translatorError) {
            NSLog(@"TRCommentTranslator error: %@", translatorError);
        }
        
        return comment;
    }
    
    NSLog(@"YTCommentParser: input is not NSDictionary");
    return nil;
}

%end
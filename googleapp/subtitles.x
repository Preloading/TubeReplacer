#import <Foundation/Foundation.h>
#import "appheaders.h"
#include "general.h"

%hook YTSubtitlesController

-(void)loadSubtitlesTracksWithBlock:(void (^)(id))responseBlock
{
    YTSubtitlesService *service = nil; 
    
    if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
        service = [(YTServices*)[self valueForKey:@"services_"] subtitlesService];
    } else {
        service = [self valueForKey:l(@"subtitlesService")];
    }
    
    NSArray *trackURLs = [(YTVideo*)[self valueForKey:l(@"video")] subtitlesTracksURL];

    [service performResponseBlock:^(id response)
    {
        if ([response count])
        {
            [self setSubtitlesTracks:response];
            responseBlock(response);
        }
    } response:trackURLs];
}

%end

%hook YTSubtitlesService

-(void)makeSubtitlesRequestWithVideoID:(NSString*)videoId track:(YTSubtitlesTrack*)track responseBlock:(id)responseBlock errorBlock:(id)errorBlock 
{
//   GTMURLBuilder *urlBuilder; // r5
//   NSString *languageCode; // r0
//   NSString *v11; // r0
//   NSString *v12; // r0
//   id v13; // r0
//   id v14; // r2

//   [self cacheKeyForVideoID:videoId track:track];
//   if ( -[NSCache objectForKey:](self->subtitlesCache_) )
//   {
//     -[YTBaseService performResponseBlock:response:](self, a5);
//   }
    NSURLRequest *request = [NSURLRequest requestWithURL:[track trackName]];
    [self performHTTPRequest:request parser:[self valueForKey:l(@"subtitlesParser")] responseBlock:responseBlock errorBlock:errorBlock];
  
}

%end

@interface YTSubtitles : NSObject
{
    NSMutableArray *lines_;
}

- (id)textAtTime:(unsigned int)fp8;
- (void)appendLine:(id)fp8 startTime:(unsigned int)fp12 endTime:(unsigned int)fp16;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)init;

@end


%hook YTSubtitlesParser

-(id)parse:(NSData*)data error:(NSError**)error {
    TBXML *xml = [%c(TBXML) tbxmlWithXMLData:data error:error];
    if ([xml rootXMLElement]) {        
        YTTBXMLElement *root = [[[%c(YTTBXMLElement) alloc] 
                        initWithElement:[xml rootXMLElement]] autorelease];
        // NSError **error1 = nil;
        // [%c(TBXML) childElementNamed:@"transcript" parentElement:[root valueForKey:@"element_"] error:error1];
        // NSLog(@"error1 -> %@", *error1);
        YTSubtitles *subtitles = [[[%c(YTSubtitles) alloc] init] autorelease];
        if (root) {            
            // Iterate through all <text> elements
            YTTBXMLElement *bodyElement = [root childElementNamed:@"body"];
            
            if (bodyElement) {
                // 360p (android)
                YTTBXMLElement *textBlock = [bodyElement childElementNamed:@"p"];
                
                double previousEnd = 0;
                double previousStart = 0;
                NSString *previousText = nil;

                while (textBlock != nil) {
                    // Extract attributes
                    double start = [[textBlock valueOfAttributeNamed:@"t"] doubleValue];
                    double dur = [[textBlock valueOfAttributeNamed:@"d"] doubleValue];
                    double endDuration = start + dur;

                    NSString *textContent = nil;

                    YTTBXMLElement *textElement = [textBlock childElementNamed:@"s"];

                    while (textElement != nil) { 
                        if (textContent) {
                            textContent = [NSString stringWithFormat:@"%@ %@",textContent, [textElement text]];
                        } else {
                            textContent = [textElement text];
                        }
                        textElement = [textElement nextSiblingNamed:@"s"];
                    }
                    
                    NSError *error = nil;
                    
                    if (textContent) {
                        // you may say "this is bad you shouldn't use regex to filter out HTML!!!!", however, this isnt actually being rendered, it's just to remove style tags we can't render
                        NSRegularExpression *regex = [NSRegularExpression 
                            regularExpressionWithPattern:@"<[^>]+>"
                            options:NSRegularExpressionCaseInsensitive 
                            error:&error];
                        textContent = [regex stringByReplacingMatchesInString:textContent
                            options:0
                            range:NSMakeRange(0, [textContent length])
                            withTemplate:@""];
                            
                        // Decode common HTML entities
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
                        textContent = [textContent stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
                    }
                    

                    if (previousText) {
                        if (previousEnd >= start) {
                            previousEnd = start-0.001;
                        }
                        [subtitles appendLine:previousText startTime:previousStart endTime:previousEnd];
                    }
                    
                    previousStart = start;
                    previousEnd = endDuration;
                    previousText = textContent;                
                    
                    // NSLog(@"Start: %f, Duration: %f, Text: %@", start, dur, textContent);
                    
                    // Move to next <text> element
                    textBlock = [textBlock nextSiblingNamed:@"p"];
                }
                if (previousText)
                    [subtitles appendLine:previousText startTime:previousStart endTime:previousEnd];

            } else {
                // HLS (iOS)
                YTTBXMLElement *textElement = [root childElementNamed:@"text"];
                
                double previousEnd = 0;
                double previousStart = 0;
                NSString *previousText = nil;

                while (textElement != nil) {
                    // Extract attributes
                    double start = [[textElement valueOfAttributeNamed:@"start"] doubleValue]*1000;
                    double dur = [[textElement valueOfAttributeNamed:@"dur"] doubleValue]*1000;
                    double endDuration = start + dur;
                    NSString *textContent = [textElement text];
                    NSError *error = nil;

                    // you may say "this is bad you shouldn't use regex to filter out HTML!!!!", however, this isnt actually being rendered, it's just to remove style tags we can't render
                    NSRegularExpression *regex = [NSRegularExpression 
                        regularExpressionWithPattern:@"<[^>]+>"
                        options:NSRegularExpressionCaseInsensitive 
                        error:&error];
                    textContent = [regex stringByReplacingMatchesInString:textContent
                        options:0
                        range:NSMakeRange(0, [textContent length])
                        withTemplate:@""];

                    // Decode common HTML entities
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
                    textContent = [textContent stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];

                    if (previousText) {
                        if (previousEnd >= start) {
                            previousEnd = start-0.001;
                        }
                        [subtitles appendLine:previousText startTime:previousStart endTime:previousEnd];
                    }
                    
                    previousStart = start;
                    previousEnd = endDuration;
                    previousText = textContent;                
                    
                    // NSLog(@"Start: %f, Duration: %f, Text: %@", start, dur, textContent);
                    
                    // Move to next <text> element
                    textElement = [textElement nextSiblingNamed:@"text"];
                }
                if (previousText)
                    [subtitles appendLine:previousText startTime:previousStart endTime:previousEnd];
            }

        }
        return subtitles;
    } else {
        NSLog(@"Failed to decode XML subtitles!!!!");
        return nil;
    }
}

%end
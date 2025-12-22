#include <Foundation/Foundation.h>
#include "appheaders.h"

@interface TBXML : NSObject
// {
//     struct _TBXMLElement *rootXMLElement;
//     struct _TBXMLElementBuffer *currentElementBuffer;
//     struct _TBXMLAttributeBuffer *currentAttributeBuffer;
//     long currentElement;
//     long currentAttribute;
//     char *bytes;
//     long bytesLength;
// }

+ (id)tbxmlWithXMLFile:(id)fp8 fileExtension:(id)fp12 error:(id *)fp16;
+ (id)tbxmlWithXMLFile:(id)fp8 fileExtension:(id)fp12;
+ (id)tbxmlWithXMLFile:(id)fp8 error:(id *)fp12;
+ (id)tbxmlWithXMLFile:(id)fp8;
+ (id)tbxmlWithXMLData:(id)fp8 error:(id *)fp12;
+ (id)tbxmlWithXMLData:(id)fp8;
+ (id)tbxmlWithXMLString:(id)fp8 error:(id *)fp12;
+ (id)tbxmlWithXMLString:(id)fp8;
- (struct _TBXMLElement *)rootXMLElement;
- (void)decodeData:(id)fp8 withError:(id *)fp12;
- (void)decodeData:(id)fp8;
- (id)initWithXMLFile:(id)fp8 fileExtension:(id)fp12 error:(id *)fp16;
- (id)initWithXMLFile:(id)fp8 fileExtension:(id)fp12;
- (id)initWithXMLFile:(id)fp8 error:(id *)fp12;
- (id)initWithXMLFile:(id)fp8;
- (id)initWithXMLData:(id)fp8 error:(id *)fp12;
- (id)initWithXMLData:(id)fp8;
- (id)initWithXMLString:(id)fp8 error:(id *)fp12;
- (id)initWithXMLString:(id)fp8;
- (id)init;

@end



%hook YTTBParser

// i apologize for the cursed shit in this function. There is 100% a better way to do this, but uhhh i can't find where the parser is set, so here we are, in hell
-(id)parse:(NSData*)xmlData error:(NSError **)error
{
    const unsigned char* bytes = [xmlData bytes];
    NSUInteger length = [xmlData length];
    
    // Check for and skip )]}'\n prefix (5 bytes)
    if (length >= 5 && 
        bytes[0] == ')' && 
        bytes[1] == ']' && 
        bytes[2] == '}' && 
        bytes[3] == '\'' && 
        bytes[4] == '\n') {
        bytes += 5;
        length -= 5;
        xmlData = [NSData dataWithBytes:bytes length:length];
    }

    if (bytes[0] == '<') {
        NSLog(@"XML Detected!");
        TBXML *xml = [%c(TBXML) tbxmlWithXMLData:xmlData error:error];
        if ([xml rootXMLElement])
        {
            YTTBXMLElement *ytRootElement = [[[%c(YTTBXMLElement) alloc] initWithElement:[xml rootXMLElement]] autorelease];
            return [self parseElement:ytRootElement error:error];
        }
        else
        {
            // too hard innit?
            // if ( error )
            // {
            //     *error = [NSError errorWithCode:1 cause:*error];
            // }
            return nil;
        }
    } else if (bytes[0] == '{') {
        NSLog(@"JSON Detected!");
        id json = [NSJSONSerialization 
            JSONObjectWithData: xmlData 
            options: NSJSONReadingMutableContainers 
            error: error];
        
        return [self parseElement:json error:error]; // if we haven't touched this function, we are **VERY** likely to crash
    } else {
        NSLog(@"Not a valid file format! %c", bytes[0]);
        return nil;
    }
}
%end
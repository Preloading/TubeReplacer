#import "potoken.h"
#import "../base64/NSData+Base64.h"

@interface GTMHTTPFetcher : NSObject
+ (id)fetcherWithRequest:(id)fp8;
- (void)waitForCompletionWithTimeout:(double)fp8;
- (void)setAuthorizer:(id)fp8;
- (BOOL)beginFetchWithCompletionHandler:(id)fp;

@end

#import <Foundation/Foundation.h>

@interface TRURLProtocol : NSURLProtocol
@end

@implementation TRURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *path = request.URL.path;

    if ([path isEqualToString:@"/ytscframe"]) {
        return YES;
    }

    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSString *path = @"/Library/Application Support/TubeReplacer/ytscframe.html";

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];

    if (!data || error) {
        NSLog(@"[TRURLProtocol] Failed to load file: %@", error);
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    NSURLResponse *response =
        [[NSURLResponse alloc] initWithURL:self.request.URL
                                   MIMEType:@"text/html"
                      expectedContentLength:data.length
                           textEncodingName:@"utf-8"];

    [self.client URLProtocol:self didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}

@end

@implementation TRPOTokenSolver

-(NSDictionary*)fetchPOJNNChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body {
    // https://www.youtube.com/api/jnn/v1/Create

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/api/jnn/v1/%@?noauth=1", method]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]]; // does requestKey ever change?
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"AIzaSyDyT5W0Jh49F30Pqqtyfdf7pDLFKLJoAnw" forHTTPHeaderField:@"x-goog-api-key"];
    [request setValue:@"grpc-web-javascript/0.1" forHTTPHeaderField:@"x-user-agent"];

    NSError *error = nil;
    NSURLResponse *requestResponse = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&error];
    if (error) {
        NSLog(@"[TubeReplacer] POToken challenge request failed!");
        return nil;
    }

    NSDictionary *json = [NSJSONSerialization
                            JSONObjectWithData:result
                            options:0
                            error:&error];
    if (error) {
        NSLog(@"[TubeReplacer] POToken challenge json decode failed!");
        return nil;
    }

    if (![json isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[TubeReplacer] POToken challenge json not a dictionary");
        return nil;
    }

    return json;
}

-(void)descrambleChallenge:(NSString*)scrambledChallenge {
    NSData *rawChallenge = [NSData dataWithBase64EncodedString:scrambledChallenge];
    NSMutableData *decipheredChallenge = [[NSMutableData alloc] init];
    const char *rawChallengeBytes = [rawChallenge bytes];

    for (int i = 0; i < rawChallenge.length; i++) {
        const char newByte = rawChallengeBytes[i]+97;
        [decipheredChallenge appendBytes:&newByte length:1];
    }
    NSError *error = nil;
    NSArray *json = [NSJSONSerialization
                            JSONObjectWithData:decipheredChallenge
                            options:0
                            error:&error];

    if (error) {
        NSLog(@"[TubeReplacer] POToken descrambled challenge json decode failed!");
        return;
    }

    if (![json isKindOfClass:[NSArray class]]) {
        NSLog(@"[TubeReplacer] POToken descrambled challenge json not an array");
        return;
    }

    self->_messageId = json[0];
    if ([json[1] isKindOfClass:[NSArray class]]) {
        for (NSString* safeScript in json[1]) {
            if ([safeScript isKindOfClass:[NSString class]]) {
                self->_safeScript = safeScript;
                break;
            }
        }
    }
    if ([json[2] isKindOfClass:[NSArray class]]) {
        for (NSString* resourceUrl in json[2]) {
            if ([resourceUrl isKindOfClass:[NSString class]]) {
                self->_resourceURL = resourceUrl;
                break;
            }
        }
    }
    self->_interpreterHash = json[3];
    self->_program = json[4];
    self->_globalName = json[5];
    self->_clientExperimentsStateBlob = json[7];

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"web error: %@", error);
}


-(void)initEngine {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSURLProtocol registerClass:[TRURLProtocol class]];

        if (self.webView) return;

        UIWindow *window = [UIApplication sharedApplication].keyWindow;

        // self.webView = [[UIWebView alloc] initWithFrame:window.bounds]; // visible
        self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(-500, -500, 100, 100)]; // invisible
        self.webView.hidden = NO;
        self.webView.alpha = 1.0;
        self.webView.delegate = self;

        NSString *path = @"/Library/Application Support/TubeReplacer/challenge_solver.html";
        NSError *error = nil;

        NSString *html = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];

        NSLog(@"html -> %@", html);

        if (!html || error) {
            NSLog(@"failed to load html: %@", error);
            return;
        }

        [window addSubview:self.webView];

        [self.webView loadHTMLString:html
                             baseURL:[NSURL URLWithString:@"https://www.youtube.com"]];

        NSLog(@"done!");
    });
}

-(void)webViewScriptsLoaded:(UIWebView*)webView {
    self.isWebViewInitialized = true;

    // NSString *wrapped = [NSString stringWithFormat:
    //     @"try { %@ } catch(e) { console.log('script error: ' + e); }",
        
    // ];

    [webView stringByEvaluatingJavaScriptFromString:self.safeScript];
    NSLog(@"safeScript executed");
    NSString *runVM = [NSString stringWithFormat:@"runBotguardChallenge(\"%@\", \"%@\", \"%@\")", self.program, self.globalName, self.botguardChallenge];
    [webView stringByEvaluatingJavaScriptFromString:runVM];
}

-(void)recievedBotguardResponse:(NSString*)result webView:(UIWebView*)webView {
    NSString *botguardResponse = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"botguard response -> %@", botguardResponse);
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    NSString *url = request.URL.absoluteString;

    if ([url hasPrefix:@"jslog://"]) {
        NSLog(@"[JS] %@", [url substringFromIndex:8]);
        return NO;
    }

    if ([url hasPrefix:@"status://"]) {
        if ([url isEqualToString:@"status://scriptsLoaded"])
            [self webViewScriptsLoaded:webView];
        return NO;
    }

    if ([url hasPrefix:@"botguard-response://"]) {
        [self recievedBotguardResponse:[url substringFromIndex:20] webView:webView];
        return NO;
    }

    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView*)webView {
    NSLog(@"loaded successfully");
}

// https://www.youtube.com/watch?v=4JkIs37a2JE
-(void)solveIntegrityToken {
    [self initEngine];
}


-(void)createPOTokenMinter {
    return;
}

-(NSString*)mintPOToken:(NSString*)identifier {
    return @"";
}

-(void)obtainPOToken {
    // NSDate *start = [NSDate date];
    NSDictionary *rawChallenge = [self fetchPOJNNChallengeWithMethod:@"Create" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo"}];
    // NSLog(@"got challenge at %f", [start timeIntervalSinceNow]);
    [self descrambleChallenge:rawChallenge[@"scrambledChallenge"]];



    // NSLog(@"descrambled at %f", [start timeIntervalSinceNow]);
    // [self solveIntegrityToken];
    // NSLog(@"solved integrity at %f", [start timeIntervalSinceNow])();
    // [self mintPOToken:@"101414430328181110843"];
    
    // [self mintPOToken:@"TiXIIwNua9E"];
    // NSLog(@"minted token at %f", [start timeIntervalSinceNow]);
    // NSLog(@"integrity token -> %@", self->_integrityToken);
    // NSLog(@"botguard response -> %@", self->_botguardResponse);

    // NSLog(@"message ID -> %@", self->_messageId);
    // NSLog(@"safe script -> %@", self->_safeScript);
    // NSLog(@"resource url -> %@", self->_resourceURL);
    // NSLog(@"program -> %@", self->_program);
    
    // NSLog(@"interpreter hash -> %@", self->_interpreterHash);
    // NSLog(@"global name -> %@", self->_globalName);
    // NSLog(@"client experiments state blob -> %@", self->_clientExperimentsStateBlob);
}

-(void)dealloc {
    [super dealloc];
}

@end
#import "potoken.h"
#import "../base64/NSData+Base64.h"
#import "../base64/NSString+Base64.h"
#import <Foundation/Foundation.h>

@interface GTMHTTPFetcher : NSObject
+ (id)fetcherWithRequest:(id)fp8;
- (void)waitForCompletionWithTimeout:(double)fp8;
- (void)setAuthorizer:(id)fp8;
- (BOOL)beginFetchWithCompletionHandler:(id)fp;

@end


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
    [response release];

    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}

@end

@implementation TRPOTokenOutput

-(instancetype)initWithPoToken:(NSString*)poToken coldStartToken:(NSString*)coldStart {
    self = [super init];
    if (self) {
        self.poToken = poToken;
        self.coldstartToken = coldStart;
    }
    return self;
}

-(void)dealloc {
    [_poToken release];
    [_coldstartToken release];
    [super dealloc];
}
@end


@implementation TRPOTokenSolver

static TRPOTokenSolver *_sharedInstance = nil;

+(TRPOTokenSolver *)sharedInstance {
    @synchronized([TRPOTokenSolver class]) {
        if (!_sharedInstance)
          _sharedInstance = [[self alloc] init];
        return _sharedInstance;
    }
    return nil;
}

-(instancetype)init {
    [super init];
    self.poTokenCallbacks = [[[NSMutableDictionary alloc] init] autorelease];
    return self;
}

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
    [request release];
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
    [decipheredChallenge release];

    if (error) {
        NSLog(@"[TubeReplacer] POToken descrambled challenge json decode failed!");
        return;
    }

    if (![json isKindOfClass:[NSArray class]]) {
        NSLog(@"[TubeReplacer] POToken descrambled challenge json not an array");
        return;
    }

    self.messageId = json[0];
    if ([json[1] isKindOfClass:[NSArray class]]) {
        for (NSString* safeScript in json[1]) {
            if ([safeScript isKindOfClass:[NSString class]]) {
                self.safeScript = safeScript;
                break;
            }
        }
    }
    if ([json[2] isKindOfClass:[NSArray class]]) {
        for (NSString* resourceUrl in json[2]) {
            if ([resourceUrl isKindOfClass:[NSString class]]) {
                self.resourceURL = resourceUrl;
                break;
            }
        }
    }
    self.interpreterHash = json[3];
    self.program = json[4];
    self.globalName = json[5];
    self.clientExperimentsStateBlob = json[7];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"web error: %@", error);
}


-(void)initEngineWithCallback:(void(^)())callback {
    self.vmReadyCallback = callback;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = @"/Library/Application Support/TubeReplacer/challenge_solver.html";
        NSError *error = nil;

        NSString *html = [NSString stringWithContentsOfFile:path
                                                    encoding:NSUTF8StringEncoding
                                                        error:&error];

        [NSURLProtocol registerClass:[TRURLProtocol class]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.webView) return;

            UIWindow *window = [UIApplication sharedApplication].keyWindow;

            // self.webView = [[UIWebView alloc] initWithFrame:window.bounds]; // visible
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(-500, -500, 100, 100)]; // invisible
            self.webView.hidden = NO;
            self.webView.alpha = 1.0;
            self.webView.delegate = self;


            if (!html || error) {
                NSLog(@"failed to load html: %@", error);
                return;
            }

            [window addSubview:self.webView];

            [self.webView loadHTMLString:html
                                baseURL:[NSURL URLWithString:@"https://www.youtube.com"]];

            NSLog(@"done!");
        });
    });
}

-(void)startFetchingChallengeResponseWithCallback:(void (^)(NSString *))callback {
    self.botguardResponseCallback = callback;
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"createAttChallengeResponse(\"%@\")", self.botguardChallenge]];
}

-(void)startFetchingIntegrityTokenForPOTokenWithCallback:(void (^)(NSString *))callback {
    self.botguardResponseCallback = callback; // ehhhh maaybe should be different? on the other hand, requesting both botguard & this is ehhhh
    [self.webView stringByEvaluatingJavaScriptFromString:@"createPOSignalOutput();"];
}

-(void)startPOTokenMinterWithIntegrityToken:(NSString*)integrityToken callback:(void (^)())callback {
    self.poGenReady = callback; 
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"processIntegrityToken(\"%@\");", integrityToken]];
}

-(void)webViewScriptsLoaded:(UIWebView*)webView {
    self.isWebViewReady = true;

    // NSString *wrapped = [NSString stringWithFormat:
    //     @"try { %@ } catch(e) { console.log('script error: ' + e); }",
        
    // ];

    CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
    [webView stringByEvaluatingJavaScriptFromString:self.safeScript];
    self.safeScript = nil;
    NSLog(@"safeScript: %.1f ms", (CFAbsoluteTimeGetCurrent()-t)*1000);
    // NSLog(@"safeScript executed");
    t = CFAbsoluteTimeGetCurrent();
    NSString *runVM = [NSString stringWithFormat:@"runBotguardChallenge(\"%@\", \"%@\", \"%@\")", self.program, self.globalName, self.botguardChallenge];
    self.program = nil;

    [webView stringByEvaluatingJavaScriptFromString:runVM];
    NSLog(@"runVM: %.1f ms", (CFAbsoluteTimeGetCurrent()-t)*1000);
}

-(void)recievedBotguardResponse:(NSString*)result webView:(UIWebView*)webView {
    NSString *botguardResponse = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.botguardResponse = botguardResponse;
    self.botguardResponseCallback(botguardResponse);
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
        if ([url isEqualToString:@"status://vmReady"])
            self.vmReadyCallback();
        if ([url isEqualToString:@"status://poReady"])
            self.poGenReady();
        return NO;
    }

    if ([url hasPrefix:@"botguard-response://"]) {
        [self recievedBotguardResponse:[url substringFromIndex:20] webView:webView];
        return NO;
    }

    if ([url hasPrefix:@"potoken-response://"]) {
        NSString *retrievedData = [url substringFromIndex:19];
        NSArray *components = [retrievedData componentsSeparatedByString:@";"];
        void (^callback)(NSString *) = [[self.poTokenCallbacks objectForKey:components[0]] retain];
        [self.poTokenCallbacks removeObjectForKey:components[0]];
        if (callback)
            callback([components[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
        else
            NSLog(@"something went critically wrong! no callback was found");
        [callback release];
        return NO;
    }

    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView*)webView {
    NSLog(@"loaded successfully");
}

-(void)mintPOTokenWithData:(NSString*)data withCallback:(void (^)(NSString *))callback {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *randomIdentifier = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    
    [self.poTokenCallbacks setObject:[callback copy] forKey:randomIdentifier];

    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"mintPOToken(\"%@\", \"%@\");", randomIdentifier, data]];
    [randomIdentifier release];
}

// direct port of https://github.com/LuanRT/BgUtils/blob/5c1c05e75c8c56b897191a8a799d94ee84b9df1c/src/core/WebPoMinter.ts#L69
// client state defualts to 1
+(NSString*)generateColdStartTokenWithContent:(NSString*)contentBinding clientState:(int)clientState {
    NSData *contentBindingBytes = [contentBinding dataUsingEncoding:NSUTF8StringEncoding];
    uint64_t timestamp = [[NSDate date] timeIntervalSince1970];
    uint8_t randomKeys[2] = {(uint8_t)arc4random_uniform(256), (uint8_t)arc4random_uniform(256)};

    uint8_t header[8] = {randomKeys[0], randomKeys[1], 0, (uint8_t)clientState, (uint8_t)((timestamp >> 24) & 0xFF), (uint8_t)((timestamp >> 16) & 0xFF), (uint8_t)((timestamp >> 8) & 0xFF), (uint8_t)(timestamp & 0xFF) };

    int packetLength = 2 + sizeof(header) + [contentBindingBytes length];
    uint8_t packet[packetLength];
    memset(packet, 0, packetLength*sizeof(uint8_t) );

    packet[0] = 34;
    packet[1] = sizeof(header) + [contentBindingBytes length];
    memcpy(packet + 2, header, sizeof(header));
    memcpy(packet + 2 + sizeof(header), [contentBindingBytes bytes], [contentBindingBytes length]);

    int keyLength = 2;
    for (int i = keyLength+2; i < packetLength; i++) {
        packet[i] ^= packet[2 + (i % keyLength)];
    }

    NSData *coldStartTokenData = [NSData dataWithBytes:(const void *)packet length:packetLength];
    NSLog(@"coldstart -> %@", [coldStartTokenData base64EncodedString]);
    return [coldStartTokenData base64EncodedString];
}

// -(void)mintPOTokenOrColdStart

// n/sig deciphering

// -(void)getPlayerJSWithCallback:(void(^)())callback {
//     NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.youtube.com/iframe_api"]];

//     [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
//         NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//         NSString *playerId = nil;
//         NSRange startRange = [responseString rangeOfString:@"player\\/"];
//         if (startRange.location != NSNotFound) {
//             NSRange targetRange;
//             targetRange.location = startRange.location + startRange.length;
//             targetRange.length = [responseString length] - targetRange.location;   
//             NSRange endRange = [responseString rangeOfString:@"\\/" options:0 range:targetRange];
//             if (endRange.location != NSNotFound) {
//                 targetRange.length = endRange.location - targetRange.location;
//                 playerId = [responseString substringWithRange:targetRange];
//             }
//         }

//         if (playerId) {
//             NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/s/player/%@/player_es6.vflset/en_US/base.js", playerId]]];

//             [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
//                 // NSString *playerJS = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//                 self.playerJS = response;
//                 callback();
//             }];
//         } else {
//             NSLog(@"playerId was not found!");
//             return;
//         }

//     }];
// }

-(void)fetchNSigFromServerWithCallback:(void(^)())callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://preloading.dev/tweaks/tubereplacer/nsig_function.php"]];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *response, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        if ([responseString hasPrefix:@"// tubereplacer n/sig"]) { 
            // it's valid! yay!

            // there is 110% better way to do this, but ehhhh
            int signatureTimestamp = 0;
            NSRange startRange = [responseString rangeOfString:@"\"signatureTimestampVar\": \""];
            if (startRange.location != NSNotFound) {
                NSRange targetRange;
                targetRange.location = startRange.location + startRange.length;
                targetRange.length = [responseString length] - targetRange.location;   
                NSRange endRange = [responseString rangeOfString:@"\"" options:0 range:targetRange];
                if (endRange.location != NSNotFound) {
                    targetRange.length = endRange.location - targetRange.location;
                    signatureTimestamp = [[responseString substringWithRange:targetRange] intValue];
                }
            }

            self.nsigSignatureTimestamp = signatureTimestamp;
            self.nsigJS = responseString;

            // cache to disk
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                     NSUserDomainMask,
                                                     YES);
            NSString *cacheFile = [[paths firstObject] stringByAppendingPathComponent:@"nsig_js.plist"];
            NSLog(@"cache file -> %@", cacheFile);
            NSDictionary *nsigCacheData = @{
                @"js":responseString,
                @"timestampSignature":@(signatureTimestamp),
                @"date":[NSDate date],
            };
            [nsigCacheData writeToFile:cacheFile atomically:TRUE];
            callback();

        }
        [responseString release];
    }];
    [request release];
}

-(void)setupNSig {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                NSUserDomainMask,
                                                YES);
    NSString *cacheFile = [[paths firstObject] stringByAppendingPathComponent:@"nsig_js.plist"];

    NSDictionary *nsigCacheData = [NSDictionary dictionaryWithContentsOfFile:cacheFile];

    if (nsigCacheData) {
        self.nsigJS = nsigCacheData[@"js"];
        self.nsigSignatureTimestamp = [nsigCacheData[@"timestampSignature"] intValue];


        if ([[NSDate date] compare:[nsigCacheData[@"date"] dateByAddingTimeInterval:604800]] == NSOrderedDescending) { // one week
            // cache has expired
            NSLog(@"[N/Sig] renewal called");
            [self fetchNSigFromServerWithCallback:^{}];
        }
    } else {
        NSLog(@"[N/Sig] cache not found, regenerating...");

        [self fetchNSigFromServerWithCallback:^{}];
    }
}

// Deciphers a URL using youtube's N/Sig systems.
// You only need either URL or signature cipher, as youtube provides the URL in several ways.
// Declare the one you are not using as nil
-(NSString*)decipherUrl:(NSString*)url signatureCipher:(NSString*)signatureCipher {
    // check if we actually can solve n/sig
    if (!self.isWebViewReady) {
        NSLog(@"[N/Sig] webview is not ready!");
        return @"";
    }



    if (!self.nsigJS) {
        NSLog(@"[N/Sig] JS code is not available!");
        return @"";
    }
    
    NSString *n = nil;
    NSString *s = nil;
    NSString *sp = nil;

    // deal with signatureCipher
    if (signatureCipher) {
        NSArray *allSigQueriesCombined = [signatureCipher componentsSeparatedByString:@"&"];
        NSMutableDictionary *signatureQueries =  [[NSMutableDictionary alloc] init];

        for (NSString *query in allSigQueriesCombined) {
            NSArray *seperatedQuery = [query componentsSeparatedByString:@"="];
            [signatureQueries setObject:[seperatedQuery[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:seperatedQuery[0]];
        }

        url = signatureQueries[@"url"];
        s = signatureQueries[@"s"];
        sp = signatureQueries[@"sp"];
    }
    

    // split URL up by query parameters
    NSArray *splitURL = [url componentsSeparatedByString:@"?"];
    NSString *querySection = splitURL[1];
    
    NSArray *allQueriesCombined = [querySection componentsSeparatedByString:@"&"];
    NSMutableDictionary *urlQueries =  [[NSMutableDictionary alloc] init];

    for (NSString *query in allQueriesCombined) {
        NSArray *seperatedQuery = [query componentsSeparatedByString:@"="];
        [urlQueries setObject:[seperatedQuery[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:seperatedQuery[0]];
    }

    n = urlQueries[@"n"];


    __block NSString *solvedNSigJSON = nil;

    if ([NSThread isMainThread])
    {
        solvedNSigJSON = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@\nprocess(\"%@\",\"\",\"\")", self.nsigJS, n]];
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            solvedNSigJSON = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@\nprocess(\"%@\",\"%@\",\"%@\")", self.nsigJS, (n ? n : @""), (sp ? sp : @""), (s ? s : @"")]];
        });
    }


    NSError *error = nil;
    NSDictionary *solvedNSig = [NSJSONSerialization JSONObjectWithData:[solvedNSigJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0
                                                    error:&error];
    if (error) {
        NSLog(@"[N/Sig] solution did not succeed!");
        return nil;
    }

    NSLog(@"solvedNsig -> %@", solvedNSig);

    if (solvedNSig[@"n"]) {
        [urlQueries setObject:solvedNSig[@"n"] forKey:@"n"];
    }

    if (solvedNSig[@"sig"]) {
        if (sp) {
            [urlQueries setObject:solvedNSig[@"sig"] forKey:sp];
        } else {
            [urlQueries setObject:solvedNSig[@"sig"] forKey:@"signature"];
        }
    }

    // rebuild the query

    NSMutableString *newURL = [[[NSMutableString alloc] init] autorelease];
    [newURL appendString:splitURL[0]];
    [newURL appendString:@"?"];
    BOOL start = YES;
    
    for (NSString *queryKey in urlQueries) {
        if (start) {
            start = NO;
        } else {
            [newURL appendString:@"&"];
        }

        NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(
            NULL,
        (CFStringRef)[urlQueries objectForKey:queryKey],
            NULL,
            CFSTR("!*'();:@&=+$,/?%#[]\" "),
            kCFStringEncodingUTF8);

        [newURL appendString:[NSString stringWithFormat:@"%@=%@", queryKey, escapedString]];
        [escapedString release];
    }

    [urlQueries release];

    // NSLog(@"good url -> %@", newURL);
    return newURL;
}

-(void)dealloc {
    if (_webView) [_webView release];

    if (_messageId) [_messageId release];
    if (_safeScript) [_safeScript release];
    if (_resourceURL) [_resourceURL release];
    if (_interpreterHash) [_interpreterHash release];
    if (_program) [_program release];
    if (_globalName) [_globalName release];
    if (_clientExperimentsStateBlob) [_clientExperimentsStateBlob release];

    if (_botguardChallenge) [_botguardChallenge release];
    if (_botguardResponse) [_botguardResponse release];

    if (_vmReadyCallback) [_vmReadyCallback release];
    if (_poGenReady) [_poGenReady release];    
    if (_botguardResponseCallback) [_botguardResponseCallback release];
    if (_poTokenCallbacks) [_poTokenCallbacks release];

    if (_nsigJS) [_nsigJS release];

    [super dealloc];
}

@end
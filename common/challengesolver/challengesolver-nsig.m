#import "challengesolver-nsig.h"

@implementation TRPOTokenSolver (NSig)

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
        self.errorAlert(@"n/sig failed to start correctly! playback may not work.");
        return nil;
    }



    if (!self.nsigJS) {
        NSLog(@"[N/Sig] JS code is not available!");
        self.errorAlert(@"n/sig failed to fetch in time. playback may not work.");
        return nil;
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
        [signatureQueries release];
    }
    
    BOOL isHLS = NO;

    // split URL up by query parameters
    NSArray *splitURL = [url componentsSeparatedByString:@"?"];
    NSMutableDictionary *urlQueries =  [[NSMutableDictionary alloc] init];

    if (splitURL.count >= 2) {
        NSString *querySection = splitURL[1];
        
        NSArray *allQueriesCombined = [querySection componentsSeparatedByString:@"&"];

        for (NSString *query in allQueriesCombined) {
            NSArray *seperatedQuery = [query componentsSeparatedByString:@"="];
            [urlQueries setObject:[seperatedQuery[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:seperatedQuery[0]];
        }

        n = urlQueries[@"n"];
    } else {
        // hls
        isHLS = YES;

        splitURL = [url componentsSeparatedByString:@"/"];

        for (int i = 0; i < splitURL.count; i++) {
            if ([splitURL[i] isEqualToString:@"n"]) {
                n = splitURL[i+1];
                i++;
            }
            if ([splitURL[i] isEqualToString:@"s"]) {
                s = splitURL[i+1];
                i++;
            }
            if ([splitURL[i] isEqualToString:@"sp"]) {
                sp = splitURL[i+1];
                i++;
            }
            if ([splitURL[i] isEqualToString:@"sig"]) {
                urlQueries[@"sig"] = splitURL[i+1];
                i++;
            }
        }
    }


    __block NSString *solvedNSigJSON = nil;

    if ([NSThread isMainThread])
    {
        solvedNSigJSON = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@\nprocess(\"%@\",\"%@\",\"%@\")", self.nsigJS, (n ? n : @""), (sp ? sp : @""), (s ? s : @"")]];
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            solvedNSigJSON = [[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@\nprocess(\"%@\",\"%@\",\"%@\")", self.nsigJS, (n ? n : @""), (sp ? sp : @""), (s ? s : @"")]] copy];
        });
    }


    NSError *error = nil;
    NSDictionary *solvedNSig = [NSJSONSerialization JSONObjectWithData:[solvedNSigJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0
                                                    error:&error];
    if (error) {
        NSLog(@"[N/Sig] solution did not succeed!");
        [urlQueries release];
        return nil;
    }

    if (!solvedNSig[@"n"] && !solvedNSig[@"sig"]) {
        NSLog(@"n/sig failed to decipher!");
        [urlQueries release];
        return nil;
    }

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
    if (isHLS) {
        NSLog(@"rebuild -> %@", splitURL);
        for (int i = 0; i < splitURL.count; i++) {
            if ([splitURL[i] isEqualToString:@"n"]) {
                [newURL appendString:@"n/"];
                if (solvedNSig[@"n"]) {
                    [newURL appendString:solvedNSig[@"n"]];
                } else {
                    [newURL appendString:splitURL[i+1]];
                }

                [newURL appendString:@"/"];

                if (solvedNSig[@"sig"]) {
                    if (sp) {
                        [newURL appendString:[NSString stringWithFormat:@"%@/%@/", sp, solvedNSig[@"sig"]]];
                    } else {
                        [newURL appendString:[NSString stringWithFormat:@"signature/%@/", solvedNSig[@"sig"]]];
                    }
                } else if (urlQueries[@"sig"]) {
                    [newURL appendString:[NSString stringWithFormat:@"sig/%@/", urlQueries[@"sig"]]];
                }
                i++;
            } else if ([splitURL[i] isEqualToString:@"sig"]) {
                i++;
            } else {
                [newURL appendString:splitURL[i]];
                [newURL appendString:@"/"];
            }
        }
    } else {
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
    }

    [urlQueries release];

    return newURL;
}

@end
#include "challengesolver-potokens.h"
#import "base64/NSData+Base64.h"

@implementation TRPOTokenSolver (POTokens) 

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
    self.isPOTokenEngineStarting = NO;
}


-(void)startBotguardVM:(void(^)())callback {
    self.vmReadyCallback = callback;
    if ([NSThread isMainThread])
    {
        if (self.ytCfg) {
            [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.yt = { config_: %@ };", self.ytCfg]];
        }
        [self.webView stringByEvaluatingJavaScriptFromString:self.safeScript];
        self.safeScript = nil;
        NSString *runVM = [NSString stringWithFormat:@"runBotguardChallenge(\"%@\", \"%@\", \"%@\")", self.program, self.globalName, self.botguardChallenge];
        self.program = nil;
        [self.webView stringByEvaluatingJavaScriptFromString:runVM];
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.ytCfg) {
                [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.yt = { config_: %@ };", self.ytCfg]];
            }
            [self.webView stringByEvaluatingJavaScriptFromString:self.safeScript];
            self.safeScript = nil;
            NSString *runVM = [NSString stringWithFormat:@"runBotguardChallenge(\"%@\", \"%@\", \"%@\")", self.program, self.globalName, self.botguardChallenge];
            self.program = nil;
            [self.webView stringByEvaluatingJavaScriptFromString:runVM];
        });
    }
    
}

-(void)recievedBotguardResponse:(NSString*)result webView:(UIWebView*)webView {
    NSString *botguardResponse = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.botguardResponse = botguardResponse;
    self.botguardResponseCallback(botguardResponse);
}



-(NSString*)mintPOTokenWithData:(NSString*)data {
    if (!self.isReadyToMintTokens)  {
        return nil;
    }

    __block NSString *poToken = nil;

    if ([NSThread isMainThread])
    {
        poToken = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"mintPOToken(\"%@\");", data]]; // takes ~20ms
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"mintPOToken(\"%@\");", data]];
            poToken = [result copy];        
        });
    }


    return poToken;
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

-(NSString*)mintPOTokenOrColdStart:(NSString*)contentBinding {
    NSString *token = nil;
    if (self.isReadyToMintTokens) {
        // mint a POToken
        token = [self mintPOTokenWithData:contentBinding];
    } else {
        // mint a coldstart
        token = [TRPOTokenSolver generateColdStartTokenWithContent:contentBinding clientState:1];
    }

    return token;
}

@end
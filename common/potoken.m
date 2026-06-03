#import "potoken.h"
#import "../base64/NSData+Base64.h"
#import "botguard_js.h"
#import "../lib/quickjs.h"
#import "../lib/quickjs-libc.h"


@interface GTMHTTPFetcher : NSObject
+ (id)fetcherWithRequest:(id)fp8;
- (void)waitForCompletionWithTimeout:(double)fp8;
- (void)setAuthorizer:(id)fp8;
- (BOOL)beginFetchWithCompletionHandler:(id)fp;

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

void print_memory_stats(JSRuntime *rt) {
    JSMemoryUsage stats;
    
    // 1. Populate the stats struct
    JS_ComputeMemoryUsage(rt, &stats);
    
    // 2. Read specific fields manually
    NSLog(@"Total Allocated Memory: %lld bytes\n", stats.malloc_size);
    NSLog(@"Number of JS Objects:   %lld\n", stats.obj_count);
    NSLog(@"Memory used by Objects: %lld bytes\n", stats.obj_size);
    NSLog(@"Memory used by Strings: %lld bytes\n", stats.str_size);
    
    NSLog(@"\n--- Detailed QuickJS Dump ---\n");
    // 3. Alternatively, use the built-in formatter to print everything to stdout
    // JS_DumpMemoryUsage(stdout, &stats, rt);
}

static JSValue native_nslog(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc > 0) {
        const char *str = JS_ToCString(ctx, argv[0]);
        if (str) {
            NSLog(@"%s", str);
            JS_FreeCString(ctx, str);
        }
    }
    return JS_UNDEFINED;
}

-(BOOL)initJSEngine {
    // cleanup prev. session
    if (self->_jsCtx) {
        JS_FreeContext(self->_jsCtx);
        self->_jsCtx = nil;
    }
    if (self->_jsRuntime) {
        JS_FreeRuntime(self->_jsRuntime);
        self->_jsRuntime = nil;
    }

    JSRuntime *rt = JS_NewRuntime();
    if (!rt) return NO;
    JSContext *ctx = JS_NewContext(rt);
    if (!ctx) {
        JS_FreeRuntime(rt);
        return NO;
    }


    // i need console.log, its getting really annoying w/o
    JSValue globalObj = JS_GetGlobalObject(ctx);
    JSValue logFunc = JS_NewCFunction(ctx, native_nslog, "__nativeNSLog", 1);
    JS_SetPropertyStr(ctx, globalObj, "__nativeNSLog", logFunc);
    JS_FreeValue(ctx, globalObj);
    js_std_eval_binary(ctx, qjsc_botguard_js, qjsc_botguard_js_size, JS_EVAL_TYPE_GLOBAL);
    self->_jsCtx = ctx;
    self->_jsRuntime = rt;
    return YES;
}

// https://www.youtube.com/watch?v=4JkIs37a2JE
-(void)solveIntegrityToken {
    NSDate *start = [NSDate date];
    if (!self->_jsRuntime || !self->_jsCtx) {
        BOOL didInitVM = [self initJSEngine];
        if (!didInitVM) {
            return;
        }
    }
    JSContext *ctx = self->_jsCtx;
    
    const char *challengeCode = [self->_safeScript UTF8String];
    size_t challengeCodeLen = strlen(challengeCode);
    JSValue challengeCodeResult = JS_Eval(ctx, challengeCode, challengeCodeLen, "<input>", JS_EVAL_TYPE_GLOBAL);
    JS_FreeValue(ctx, challengeCodeResult);
    NSLog(@"challenge vm addded at %f", [start timeIntervalSinceNow]);


    NSString *checkForToken = [NSString stringWithFormat:
        @"globalThis.fetchIntegretyChallengeResp2('%@','%@');", self->_globalName, self->_program]; 

    const char *checkForTokenStr = [checkForToken UTF8String];
    size_t checkForTokenStrLen = strlen(checkForTokenStr);
    JSValue tokenPromise = JS_Eval(ctx, checkForTokenStr, checkForTokenStrLen, "<input>", JS_EVAL_TYPE_GLOBAL);

    // async BS
    JSContext *ctx1;
    int err;
    while ((err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx1)) > 0) {
        // wheeeee!
    }

    JSValue globalObj = JS_GetGlobalObject(ctx);

    JSValue tokenVal = JS_GetPropertyStr(ctx, globalObj, "finalTokenOutput");

    NSString *botguard_challenge_resp = nil;
    if (!JS_IsUndefined(tokenVal) && !JS_IsNull(tokenVal)) {

        const char *tokenCStr = JS_ToCString(ctx, tokenVal);
        botguard_challenge_resp = [[NSString stringWithFormat:@"%s", tokenCStr] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
        JS_FreeCString(ctx, tokenCStr);
    } else {
        NSLog(@"Error: nothing was returned!!!");
        JS_FreeValue(ctx, tokenVal);
        JS_FreeValue(ctx, globalObj);
        JS_FreeValue(ctx, tokenPromise);
        return;
    }

    JS_FreeValue(ctx, tokenVal);
    JS_FreeValue(ctx, globalObj);
    JS_FreeValue(ctx, tokenPromise);

    if ([botguard_challenge_resp hasPrefix:@"error"]) {
        NSLog(@"An error occured with solving BotGuard! %@", botguard_challenge_resp);
    }
    NSLog(@"base integrity solved at %f", [start timeIntervalSinceNow]);
    self->_botguardResponse = botguard_challenge_resp;

    // get the integrity token
    NSDictionary *solvedIntegrety = [self fetchPOJNNChallengeWithMethod:@"GenerateIT" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo", @"botguard_response":botguard_challenge_resp}];
    NSLog(@"solved integrity -> %@", solvedIntegrety);
    NSLog(@"integrity token 1 -> %@", self->_integrityToken);
    self->_integrityToken = solvedIntegrety[@"integrityToken"];
    if (!self->_integrityToken) {
        return;
    }
    self->_integrityTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:[solvedIntegrety[@"estimatedTtlSecs"] intValue]];
    self->_integrityTokenShouldProbablyRenew = [NSDate dateWithTimeIntervalSinceNow:[solvedIntegrety[@"estimatedTtlSecs"] intValue]/12]; // in my test, it lasts 12h, means at 1h we renew;
    NSLog(@"integrity token 2 -> %@", self->_integrityToken);
    
    NSString *createMinter = [NSString stringWithFormat:
        @"globalThis.createMinter('%@');", self->_integrityToken]; 

    const char *createMinterStr = [createMinter UTF8String];
    size_t createMinterStrLen = strlen(createMinterStr);
    JSValue createMinterPromise = JS_Eval(ctx, createMinterStr, createMinterStrLen, "<input>", JS_EVAL_TYPE_GLOBAL);
    NSLog(@"actual integrity obtained at %f", [start timeIntervalSinceNow]);

    // async BS x2
    JSContext *ctx2;
    while ((err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx2)) > 0) {
        // wheeeee! :3
    }
    JS_FreeValue(ctx, createMinterPromise);
    NSLog(@"minter created at %f", [start timeIntervalSinceNow]);

    // NSString *objcResult = nil;
    // if (JS_IsException(result)) {
    //     JSValue exception = JS_GetException(ctx);
    //     const char *excStr = JS_ToCString(ctx, exception);
        
    //     objcResult = [NSString stringWithFormat:@"Error: %s", excStr];
        
    //     JS_FreeCString(ctx, excStr);
    //     JS_FreeValue(ctx, exception);
    // } else {
    //     const char *resStr = JS_ToCString(ctx, result);
    //     if (resStr) {
    //         objcResult = [NSString stringWithUTF8String:resStr];
    //         JS_FreeCString(ctx, resStr);
    //     }
    // }

    // JS_FreeValue(ctx, result);
    return;

    // NSLog(@"result -> %@", objcResult);
}

-(NSString*)mintPOToken:(NSString*)identifier {
    if (!self->_jsCtx || !self->_jsRuntime) {
        NSLog(@"JS engine is not running! Cannot mint a POToken!");
    }

    JSValue globalObj = JS_GetGlobalObject(self->_jsCtx);
    JS_SetPropertyStr(self->_jsCtx, globalObj, "poTokenJobDone", JS_NewBool(self->_jsCtx, NO));

    NSString *mintToken = [NSString stringWithFormat:
        @"globalThis.mintPOToken('%@');", identifier]; 

    const char *mintTokenStr = [mintToken UTF8String];
    size_t mintTokenStrLen = strlen(mintTokenStr);
    JSValue mintTokenPromise = JS_Eval(self->_jsCtx, mintTokenStr, mintTokenStrLen, "<input>", JS_EVAL_TYPE_GLOBAL);

    JSContext *ctx2;
    BOOL isDone = NO;
    
    while (!isDone) {
        while (JS_ExecutePendingJob(JS_GetRuntime(self->_jsCtx), &ctx2) > 0) {
            // meow mrrp mewo
        }
        
        JSValue doneVal = JS_GetPropertyStr(self->_jsCtx, globalObj, "poTokenJobDone");
        isDone = JS_ToBool(self->_jsCtx, doneVal);
        JS_FreeValue(self->_jsCtx, doneVal);
        
        if (!isDone) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
    

    JSValue tokenVal = JS_GetPropertyStr(self->_jsCtx, globalObj, "poToken");

    NSString *poToken = nil;
    if (!JS_IsUndefined(tokenVal) && !JS_IsNull(tokenVal)) {
        const char *tokenCStr = JS_ToCString(self->_jsCtx, tokenVal);
        poToken = [[NSString stringWithFormat:@"%s", tokenCStr] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
        JS_FreeCString(self->_jsCtx, tokenCStr);
    } else {
        NSLog(@"Error: nothing was returned!!!");
        JS_FreeValue(self->_jsCtx, tokenVal);
        JS_FreeValue(self->_jsCtx, globalObj);
        JS_FreeValue(self->_jsCtx, mintTokenPromise);
        return nil;
    }

    JS_FreeValue(self->_jsCtx, tokenVal);
    JS_FreeValue(self->_jsCtx, globalObj);
    JS_FreeValue(self->_jsCtx, mintTokenPromise);
    
    NSLog(@"Achievement get! POToken: %@", poToken);
    return poToken;
}

-(void)obtainPOToken {
    // NSDate *start = [NSDate date];
    NSDictionary *rawChallenge = [self fetchPOJNNChallengeWithMethod:@"Create" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo"}];
    // NSLog(@"got challenge at %f", [start timeIntervalSinceNow]);
    [self descrambleChallenge:rawChallenge[@"scrambledChallenge"]];
    // NSLog(@"descrambled at %f", [start timeIntervalSinceNow]);
    [self solveIntegrityToken];
    // NSLog(@"solved integrity at %f", [start timeIntervalSinceNow])();
    // [self mintPOToken:@"101414430328181110843"];
    
    // [self mintPOToken:@"TiXIIwNua9E"];
    // NSLog(@"minted token at %f", [start timeIntervalSinceNow]);
    NSLog(@"integrity token -> %@", self->_integrityToken);
    NSLog(@"botguard response -> %@", self->_botguardResponse);

    // NSLog(@"message ID -> %@", self->_messageId);
    // NSLog(@"safe script -> %@", self->_safeScript);
    // NSLog(@"resource url -> %@", self->_resourceURL);
    // NSLog(@"program -> %@", self->_program);
    
    // NSLog(@"interpreter hash -> %@", self->_interpreterHash);
    // NSLog(@"global name -> %@", self->_globalName);
    // NSLog(@"client experiments state blob -> %@", self->_clientExperimentsStateBlob);
}

-(void)dealloc {
    if (self->_jsCtx)
        JS_FreeContext(self->_jsCtx);
    if (self->_jsRuntime)
        JS_FreeRuntime(self->_jsRuntime);
    [super dealloc];
}

@end
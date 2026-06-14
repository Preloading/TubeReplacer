// im really sorry to say, but a decent chunk of this is AI. I spent weeks just trying to get the PO stuff to work fully, and at some point I just gave up and used AI.

#import "potoken.h"
#import "../base64/NSData+Base64.h"
#import "botguard_js.h"
#import "../lib/quickjs.h"
#import "../lib/quickjs-libc.h"


// timers
@interface QJSTimerTarget : NSObject
@property (nonatomic, assign) JSContext *ctx;
@property (nonatomic, assign) JSValue callback;
@property (nonatomic, assign) BOOL isRepeating;
@property (nonatomic, assign) int intervalId;
@end

@implementation QJSTimerTarget
- (void)timerFired:(NSTimer *)timer {
    // Safely execute the callback on the active thread pumping the RunLoop
    JSValue res = JS_Call(self.ctx, self.callback, JS_UNDEFINED, 0, NULL);
    JS_FreeValue(self.ctx, res);
    NSLog(@"fire away!");
    // If it's a timeout (not repeating), clean up the JSValue reference now
    if (!self.isRepeating) {
        JS_FreeValue(self.ctx, self.callback);
        [timer invalidate];
    }
}
@end
static NSMutableDictionary<NSNumber *, NSTimer *> *activeIntervals = nil;
static NSMutableDictionary<NSNumber *, QJSTimerTarget *> *activeTargets = nil; // Add this
static int nextIntervalId = 3;

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
// --- Helper C Functions for QuickJS to Call ---

static JSValue native_setTimeout(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    if (argc < 1) return JS_UNDEFINED;
    
    double delayMs = 0;
    if (argc > 1) {
        JS_ToFloat64(ctx, &delayMs, argv[1]);
    }
    
    JSValue callback = JS_DupValue(ctx, argv[0]);
    
    QJSTimerTarget *target = [[QJSTimerTarget alloc] init];
    target.ctx = ctx;
    target.callback = callback;
    target.isRepeating = NO;

    // Schedule directly on the CURRENT thread's runloop, removing dispatch_async
    [NSTimer scheduledTimerWithTimeInterval:(delayMs / 1000.0)
                                     target:target
                                   selector:@selector(timerFired:)
                                   userInfo:nil
                                    repeats:NO];
    
    return JS_NewInt32(ctx, 1); 
}

static JSValue native_setInterval(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    if (argc < 1) return JS_UNDEFINED;
    
    if (!activeIntervals) {
        activeIntervals = [[NSMutableDictionary alloc] init];
        activeTargets = [[NSMutableDictionary alloc] init]; // Initialize here
    }
    
    double delayMs = 0;
    if (argc > 1) {
        JS_ToFloat64(ctx, &delayMs, argv[1]);
    }
    
    JSValue callback = JS_DupValue(ctx, argv[0]);
    int intervalId = nextIntervalId++;
    
    QJSTimerTarget *target = [[QJSTimerTarget alloc] init];
    target.ctx = ctx;
    target.callback = callback;
    target.isRepeating = YES;
    target.intervalId = intervalId;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(delayMs / 1000.0)
                                                      target:target
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
    
    activeIntervals[@(intervalId)] = timer;
    activeTargets[@(intervalId)] = target; // Track the target explicitly
    
    return JS_NewInt32(ctx, intervalId);
}

static JSValue native_clearInterval(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    if (argc < 1 || !activeIntervals) return JS_UNDEFINED;
    
    int32_t intervalId;
    if (JS_ToInt32(ctx, &intervalId, argv[0]) < 0) return JS_UNDEFINED;
    
    NSNumber *key = @(intervalId);
    NSTimer *timer = activeIntervals[key];
    QJSTimerTarget *target = activeTargets[key];
    
    if (target) {
        // Safely free the JS callback reference
        JS_FreeValue(ctx, target.callback);
        [activeTargets removeObjectForKey:key];
    }
    
    if (timer) {
        [timer invalidate];
        [activeIntervals removeObjectForKey:key];
    }
    
    return JS_UNDEFINED;
}
static JSValue native_fetch(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    NSLog(@"fetch :D");
    if (argc < 1) return JS_UNDEFINED;

    // 1. Parse the URL
    const char *urlCStr = JS_ToCString(ctx, argv[0]);
    if (!urlCStr) return JS_UNDEFINED;
    NSString *urlString = [NSString stringWithUTF8String:urlCStr];
    JS_FreeCString(ctx, urlCStr);

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"]; // Default fallback

    // 2. Parse Options Object (Method, Headers, Body) if provided
    if (argc > 1 && JS_IsObject(argv[1])) {
        JSValue options = argv[1];

        // Parse HTTP Method
        JSValue methodVal = JS_GetPropertyStr(ctx, options, "method");
        if (!JS_IsUndefined(methodVal) && !JS_IsNull(methodVal)) {
            const char *methodCStr = JS_ToCString(ctx, methodVal);
            if (methodCStr) {
                [request setHTTPMethod:[NSString stringWithUTF8String:methodCStr]];
                JS_FreeCString(ctx, methodCStr);
            }
        }
        JS_FreeValue(ctx, methodVal);

        // Parse HTTP Body
        JSValue bodyVal = JS_GetPropertyStr(ctx, options, "body");
        if (!JS_IsUndefined(bodyVal) && !JS_IsNull(bodyVal)) {
            const char *bodyCStr = JS_ToCString(ctx, bodyVal);
            if (bodyCStr) {
                NSData *bodyData = [[NSString stringWithUTF8String:bodyCStr] dataUsingEncoding:NSUTF8StringEncoding];
                [request setHTTPBody:bodyData];
                JS_FreeCString(ctx, bodyCStr);
            }
        }
        JS_FreeValue(ctx, bodyVal);

        // Parse Headers (Basic support for flat JS objects)
        JSValue headersVal = JS_GetPropertyStr(ctx, options, "headers");
        if (JS_IsObject(headersVal)) {
            // If it's a standard JS object, pass standard content types
            // Botguard usually needs application/json or text/plain
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
        JS_FreeValue(ctx, headersVal);
    }

    // 3. Perform the Synchronous Network Request safely within the runtime loop
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (error || !data) {
        NSLog(@"[TubeReplacer] Native fetch network failed for: %@", urlString);
        // Return a rejected promise if the network drops completely
        JSValue globalObj = JS_GetGlobalObject(ctx);
        JSValue promiseClass = JS_GetPropertyStr(ctx, globalObj, "Promise");
        JSValue rejectFunc = JS_GetPropertyStr(ctx, promiseClass, "reject");
        JSValue errorMsg = JS_NewString(ctx, "Network request failed");
        JSValueConst args[1] = { errorMsg };
        JSValue rejectedPromise = JS_Call(ctx, rejectFunc, promiseClass, 1, args);
        
        JS_FreeValue(ctx, globalObj);
        JS_FreeValue(ctx, promiseClass);
        JS_FreeValue(ctx, rejectFunc);
        JS_FreeValue(ctx, errorMsg);
        return rejectedPromise;
    }

    // 4. Construct the response string payload
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!responseString) responseString = @"";
    const char *resCStr = [responseString UTF8String];

    // 5. Create a standard compliant Response shim mock
    JSValue responseObj = JS_NewObject(ctx);
    JSValue textData = JS_NewString(ctx, resCStr);
    JS_SetPropertyStr(ctx, responseObj, "_textValue", textData);
    
    // Set typical status properties botguard might check
    NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 200;
    JS_SetPropertyStr(ctx, responseObj, "status", JS_NewInt32(ctx, (int32_t)statusCode));
    JS_SetPropertyStr(ctx, responseObj, "ok", JS_NewBool(ctx, statusCode >= 200 && statusCode < 300));

    // .text() implementation returning a Promise
    NSString *promiseShim = @"function() { return Promise.resolve(this._textValue); }";
    JSValue textFunc = JS_Eval(ctx, [promiseShim UTF8String], strlen([promiseShim UTF8String]), "<input>", JS_EVAL_TYPE_GLOBAL);
    JS_SetPropertyStr(ctx, responseObj, "text", textFunc);

    // .json() implementation returning a parsed Promise
    NSString *jsonShim = @"function() { return Promise.resolve(JSON.parse(this._textValue)); }";
    JSValue jsonFunc = JS_Eval(ctx, [jsonShim UTF8String], strlen([jsonShim UTF8String]), "<input>", JS_EVAL_TYPE_GLOBAL);
    JS_SetPropertyStr(ctx, responseObj, "json", jsonFunc);

    // Wrap your response object wrapper back up into a resolved Promise
    JSValue globalObj = JS_GetGlobalObject(ctx);
    JSValue promiseClass = JS_GetPropertyStr(ctx, globalObj, "Promise");
    JSValue resolveFunc = JS_GetPropertyStr(ctx, promiseClass, "resolve");
    
    JSValueConst args[1] = { responseObj };
    JSValue promiseResult = JS_Call(ctx, resolveFunc, promiseClass, 1, args);
    
    // Clean up
    JS_FreeValue(ctx, globalObj);
    JS_FreeValue(ctx, promiseClass);
    JS_FreeValue(ctx, resolveFunc);
    JS_FreeValue(ctx, responseObj);
    [responseString release];

    return promiseResult;
}
-(BOOL)initJSEngine {
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

    JSValue globalObj = JS_GetGlobalObject(ctx);
    JSValue logFunc = JS_NewCFunction(ctx, native_nslog, "__nativeNSLog", 1);
    JS_SetPropertyStr(ctx, globalObj, "__nativeNSLog", logFunc);
    
    JSValue setTimeoutFunc = JS_NewCFunction(ctx, (JSCFunction *)native_setTimeout, "setTimeout", 2);
    JS_SetPropertyStr(ctx, globalObj, "setTimeout", setTimeoutFunc);
    
    JSValue setIntervalFunc = JS_NewCFunction(ctx, (JSCFunction *)native_setInterval, "setInterval", 2);
    JS_SetPropertyStr(ctx, globalObj, "setInterval", setIntervalFunc);
    
    JSValue clearIntervalFunc = JS_NewCFunction(ctx, (JSCFunction *)native_clearInterval, "clearInterval", 1);
    JS_SetPropertyStr(ctx, globalObj, "clearInterval", clearIntervalFunc);
    JS_SetPropertyStr(ctx, globalObj, "clearTimeout", JS_DupValue(ctx, clearIntervalFunc));

    JSValue fetchFunc = JS_NewCFunction(ctx, native_fetch, "__native_fetch", 1);
    JS_SetPropertyStr(ctx, globalObj, "__native_fetch", fetchFunc);

    js_std_eval_binary(ctx, qjsc_botguard_js, qjsc_botguard_js_size, JS_EVAL_TYPE_GLOBAL);

    JS_FreeValue(ctx, globalObj);
    self->_jsCtx = ctx;
    self->_jsRuntime = rt;
    return YES;
}

// https://www.youtube.com/watch?v=4JkIs37a2JE
-(void)solveIntegrityToken {
    NSDate *start = [NSDate date];
    if (!self->_jsRuntime || !self->_jsCtx) {
        BOOL didInitVM = [self initJSEngine];
        if (!didInitVM) return;
    }
    JSContext *ctx = self->_jsCtx;
    JSRuntime *rt = JS_GetRuntime(ctx);
    
    // Alias window to globalThis to prevent ReferenceErrors
    JSValue globalObj = JS_GetGlobalObject(ctx);
    JS_SetPropertyStr(ctx, globalObj, "window", JS_DupValue(ctx, globalObj));

    const char *challengeCode = [self->_safeScript UTF8String];
    JSValue challengeCodeResult = JS_Eval(ctx, challengeCode, strlen(challengeCode), "<input>", JS_EVAL_TYPE_GLOBAL);
    JS_FreeValue(ctx, challengeCodeResult);

    NSString *checkForToken = [NSString stringWithFormat:@"globalThis.fetchIntegretyChallengeResp2('%@','%@');", self->_globalName, self->_program]; 
    JSValue tokenPromise = JS_Eval(ctx, [checkForToken UTF8String], strlen([checkForToken UTF8String]), "<input>", JS_EVAL_TYPE_GLOBAL);

    // Keep pumping the job queue until token is found or timeout occurs (e.g., 5 seconds)
    JSContext *ctx1;
    int err;
    BOOL tokenFound = NO;
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:80.0];

    while ([timeoutDate timeIntervalSinceNow] > 0 && !tokenFound) {
        
        // 1. Run the native RunLoop briefly to allow NSTimers to fire on this thread
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        // 2. Run all pending JS Microtasks generated by timers or promises
        while ((err = JS_ExecutePendingJob(rt, &ctx1)) > 0) {
            // Processing...
        }
        
        // 3. Check for token condition
        JSValue tokenVal = JS_GetPropertyStr(ctx, globalObj, "finalTokenOutput");
        if (!JS_IsUndefined(tokenVal) && !JS_IsNull(tokenVal)) {
            // ... handle success ...
            tokenFound = YES;
        }
        JS_FreeValue(ctx, tokenVal);
    }

    if (!tokenFound) {
        NSLog(@"Error: Execution timed out or no token returned.");
    } else if ([self->_botguardResponse hasPrefix:@"error"]) {
        NSLog(@"An error occurred inside JS VM: %@", self->_botguardResponse);
    } else {
        NSLog(@"Base integrity solved successfully at %f", [start timeIntervalSinceNow]);
    }

    // Clean up all references
    JS_FreeValue(ctx, globalObj);
    JS_FreeValue(ctx, tokenPromise);
}


-(void)createPOTokenMinter {
    if (!self->_jsRuntime || !self->_jsCtx) {
        NSLog(@"CreatePOTokenMinter called before VM was initalized!");
    }
    JSContext *ctx = self->_jsCtx;

    // get the integrity token
    NSDictionary *solvedIntegrety = [self fetchPOJNNChallengeWithMethod:@"GenerateIT" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo", @"botguard_response":self->_botguardResponse}];
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
    // NSLog(@"actual integrity obtained at %f", [start timeIntervalSinceNow]);

    // async BS x2
    int err = 0;
    JSContext *ctx2;
    while ((err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx2)) > 0) {
        // wheeeee! :3
    }
    JS_FreeValue(ctx, createMinterPromise);
    // NSLog(@"minter created at %f", [start timeIntervalSinceNow]);

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
    for (NSNumber *key in [activeTargets allKeys]) {
        QJSTimerTarget *target = activeTargets[key];
        if (target) {
            JS_FreeValue(self->_jsCtx, target.callback);
        }
    }
    for (NSNumber *key in [activeIntervals allKeys]) {
        NSTimer *timer = activeIntervals[key];
        [timer invalidate];
    }

        [activeIntervals removeAllObjects];
        [activeTargets removeAllObjects];

    if (self->_jsCtx)
        JS_FreeContext(self->_jsCtx);
    if (self->_jsRuntime)
        JS_FreeRuntime(self->_jsRuntime);
    [super dealloc];
}

@end
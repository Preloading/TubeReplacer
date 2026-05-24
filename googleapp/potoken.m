#import "potoken.h"
#import "../base64/NSData+Base64.h"
#import "botguard_js.h"
#import "../lib/quickjs-libc.h"

@implementation TRPOTokenSolver

-(NSDictionary*)fetchChallengeWithMethod:(NSString*)method andBody:(NSDictionary*)body {
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

// https://www.youtube.com/watch?v=4JkIs37a2JE
-(void)solveIntegrityToken {
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
    if (!rt) return;
    JSContext *ctx = JS_NewContext(rt);
    if (!ctx) {
        JS_FreeRuntime(rt);
        return;
    }

    // i need console.log, its getting really annoying w/o
    JSValue globalObj = JS_GetGlobalObject(ctx);
    JSValue logFunc = JS_NewCFunction(ctx, native_nslog, "__nativeNSLog", 1);
    JS_SetPropertyStr(ctx, globalObj, "__nativeNSLog", logFunc);
    JS_FreeValue(ctx, globalObj);
    js_std_eval_binary(ctx, qjsc_botguard_js, qjsc_botguard_js_size, JS_EVAL_TYPE_GLOBAL);

    const char *challengeCode = [self->_safeScript UTF8String];
    size_t challengeCodeLen = strlen(challengeCode);
    JSValue challengeCodeResult = JS_Eval(ctx, challengeCode, challengeCodeLen, "<input>", JS_EVAL_TYPE_GLOBAL);
    JS_FreeValue(ctx, challengeCodeResult);
    NSString *checkForToken = [NSString stringWithFormat:
        @"(async function(){\n"
            "const globalObject = globalThis;\n"
            // "globalThis.finalTokenOutput = JSON.stringify(Object.keys(globalObject)); return;"
            "const vm = globalObject['%@'];\n"

            "if (!vm) {globalThis.finalTokenOutput = 'error vm not found'; return;}\n"
            "if (!vm.a) {globalThis.finalTokenOutput = 'error vm init not found'; return;}\n"

            "const vmFunctions = {};\n"
            "let syncSnapshotFunction = null;\n"
            "const vmFunctionsCallback = (asyncSnapshotFunction, shutdownFunction, passEventFunction, checkCameraFunction) => {\n"
            "  Object.assign(vmFunctions, { asyncSnapshotFunction, shutdownFunction, passEventFunction, checkCameraFunction });\n"
            "};\n"

            "try {\n"
            "  const initResult = await vm.a(\"%@\", vmFunctionsCallback, true, undefined, () => { /** no-op */ }, [ [], [] ]);\n"
            "  syncSnapshotFunction = initResult[0];\n"
            "} catch (error) {\n"
            "  globalThis.finalTokenOutput = 'error vm failed to init'; return;\n"
            "}\n"

            "async function snapshot(args) {\n"
            "    return new Promise((resolve, reject) => {\n"
            "if (!vmFunctions.asyncSnapshotFunction) {\n"
                "return reject(new Error('[BotGuardClient]: Async snapshot function not found'));\n"
            "}\n"
            "vmFunctions.asyncSnapshotFunction((response) => resolve(response),[args.contentBinding, args.signedTimestamp, args.webPoSignalOutput, args.skipPrivacyBuffer]);});}\n"

            "globalThis.webPoSignalOutput = [];\n"
            "const botguardResponse = await snapshot({ globalThis.webPoSignalOutput });\n"
            "globalThis.finalTokenOutput = JSON.stringify(botguardResponse);\n"
        "})();", self->_globalName, self->_program]; 


    const char *jsCode = [checkForToken UTF8String];
    size_t jsCodeLen = strlen(jsCode);
    JSValue tokenPromise = JS_Eval(ctx, jsCode, jsCodeLen, "<input>", JS_EVAL_TYPE_GLOBAL);

    // async BS
    JSContext *ctx1;
    int err;
    while ((err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx1)) > 0) {
        // wheeeee!
    }

    globalObj = JS_GetGlobalObject(ctx);

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
        goto fail;
    }

    JS_FreeValue(ctx, tokenVal);
    JS_FreeValue(ctx, globalObj);
    JS_FreeValue(ctx, tokenPromise);

    if ([botguard_challenge_resp hasPrefix:@"error"]) {
        NSLog(@"An error occured with solving BotGuard! %@", botguard_challenge_resp);
    }
    NSLog(@"botguard_challenge_resp -> %@", botguard_challenge_resp);
    NSDictionary *solvedIntegrety = [self fetchChallengeWithMethod:@"GenerateIT" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo", @"botguard_response":botguard_challenge_resp}];
    NSLog(@"solvedIntegrety -> %@", solvedIntegrety);
    self->_integretyToken = solvedIntegrety[@"integretyToken"];
    self->_integretyTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:[solvedIntegrety[@"estimatedTtlSecs"] intValue]];
    self->_integretyTokenShouldProbablyRenew = [NSDate dateWithTimeIntervalSinceNow:[solvedIntegrety[@"estimatedTtlSecs"] intValue]/12]; // in my test, it lasts 12h, means at 1h we renew;
    



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
    self->_jsCtx = ctx;
    self->_jsRuntime = rt;
    return;

    fail:
        JS_FreeContext(self->_jsCtx);
        JS_FreeRuntime(self->_jsRuntime);

    // NSLog(@"result -> %@", objcResult);
}

-(void)obtainPOToken {
    NSDictionary *rawChallenge = [self fetchChallengeWithMethod:@"Create" andBody:@{@"request_key":@"O43z0dpjhgX20SCx4KAo"}];
    [self descrambleChallenge:rawChallenge[@"scrambledChallenge"]];
    [self solveIntegrityToken];

    NSLog(@"integrety token -> %@", self->_integretyToken);

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
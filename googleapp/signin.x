#include <Foundation/Foundation.h>
#import "signinpolyfil.h"
#import <CommonCrypto/CommonDigest.h>
#include "appheaders.h"
#include "general.h"
#include "Translators/TRTranslators.h"

#import <execinfo.h>

//// START HEADERS

@interface GTMOAuth2AuthorizationArgs : NSObject
// {
//     NSMutableURLRequest *request_;
//     id delegate_;
//     SEL sel_;
//     id completionHandler_;
//     NSThread *thread_;
//     NSError *error_;
// }

+ (id)argsWithRequest:(id)fp8 delegate:(id)fp12 selector:(SEL)selector completionHandler:(id)fp20 thread:(NSThread*)thread;
- (void)setError:(id)fp8;
- (id)error;
- (void)setThread:(id)fp8;
- (id)thread;
- (void)setCompletionHandler:(id)fp8;
- (id)completionHandler;
- (void)setSelector:(SEL)fp8;
- (SEL)selector;
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)setRequest:(id)fp8;
- (id)request;
- (void)dealloc;

@end

@interface SSOAuthAdvice : NSObject

@property (readonly, nonatomic) NSDictionary *json; // ivar: _json
@property (readonly, nonatomic) int adviceCode; // ivar: _adviceCode
@property (readonly, nonatomic) NSURL *URI; // ivar: _URI
@property (readonly, nonatomic) NSString *verifier; // ivar: _verifier
@property (readonly, nonatomic) NSString *clientState; // ivar: _clientState
@property (readonly, nonatomic) NSString *error; // ivar: _error
@property (readonly, nonatomic) NSString *errorDescription; // ivar: _errorDescription
@property (readonly, nonatomic) NSURL *errorURI; // ivar: _errorURI


-(id)init;
-(id)initWithJSONDictionary:(id)arg0 ;
-(id)description;


@end

// 2.0.0
@interface SSOIdentity : NSObject



-(id)userEmail;
-(id)userID;
-(char)isSignedIn;
-(id)userFullName;


@end

@interface SSOIdentityPrivate : SSOIdentity

// @property (readonly, nonatomic) SSOConfiguration *configuration; // ivar: _configuration
@property (retain) GTMOAuth2Authentication *auth; // ivar: _auth
@property (copy, nonatomic) NSString *userFullName; // ivar: _userFullName
@property (getter=isSignedIn) char signedIn; // ivar: _signedIn
@property (getter=isGuestIdentity) char guestIdentity; // ivar: _guestIdentity
// @property (copy, nonatomic) id *signInCallback; // ivar: _signInCallback
@property (nonatomic, getter=isDisabled) char disabled; // ivar: _disabled
@property (copy, nonatomic) NSString *filterAnnotation; // ivar: _filterAnnotation


-(id)fetcherWithRequest:(id)arg0 ;
// -(id)parseJSONResponse:(id)arg0 error:(*id)arg1 ;
-(id)appendJSONDataToError:(id)arg0 data:(id)arg1 fetcher:(id)arg2 ;
// -(void)authenticateWithPresentBlock:(id)arg0 callback:(unk)arg1 authorizationURL:(id)arg2  ;
-(void)signInWithCode:(id)arg0 finishedWithAuth:(id)arg1 error:(id)arg2 ;
-(void)authenticateWithCode:(id)arg0 verifier:(id)arg1 callback:(id)arg2 ;
-(void)requestTokenForService:(id)arg0 callback:(id)arg1 ;
-(void)requestTokenAuthURL:(id)arg0 service:(id)arg1 source:(id)arg2 callback:(id)arg3 ;
-(void)requestResultsOfType:(id)arg0 scopes:(id)arg1 extraParameters:(id)arg2 callback:(id)arg3 ;
-(void)requestAccessTokenForScopes:(id)arg0 callback:(id)arg1 ;
-(void)requestAuthorizationCodeForScopes:(id)arg0 auth:(id)arg1 clientID:(id)arg2 applicationID:(id)arg3 extraParameters:(id)arg4 callback:(id)arg5 ;
-(void)requestAuthAdviceReauthenticating:(id)arg0 callback:(id)arg1 ;
-(id)revokeToken:(id)arg0 ;
-(id)initWithConfiguration:(id)arg0 keychainItem:(id)arg1 ;
-(id)keychainItem;
-(id)initWithConfiguration:(id)arg0 ;
-(id)description;
-(id)userEmail;
-(id)userID;
-(char)isAuthAdviceCleared;
+(id)guestIdentity;
-(GTMOAuth2Authentication*)auth;

@end

@interface SSOKeychain : NSObject

+(void)setAuthAdviceState:(NSString*)adviceState error:(NSError*)error;

@end

@interface AuthorizerCallback : NSObject
+(id)callbackWithRequest:(id)request handler:(id)handler delegate:(id)delegate selector:(SEL)selector thread:(NSThread*)thread;
@end

@interface SSOAuthorizationImpl : NSObject
-(SSOIdentityPrivate*)identity; // **TECHNICALLY** this isn't correct, it's actually SSOIdentity, but objc magic stuff just makes this easier lol
-(id)invokeCallback:(id)callback;
-(BOOL)shouldAuthorizeAllRequests;
@end

//// END HEADERS

%hook SSOIdentityPrivate
-(void)requestAuthAdviceReauthenticating:(id)a3 callback:(void (^)(SSOAuthAdvice *, NSError*))callback {
    NSLog (@"callback class -> %@", NSStringFromClass([callback class]));
    NSString *email = [self userEmail];
    BOOL isSignedIn = ([email length] != 0);

    if (isSignedIn) { // wait is this is we *were* logged in 
        return %orig; // todo: see if this impacts anything
    }
    

    SSOAuthAdvice *authAdvice = [%c(SSOAuthAdvice) alloc];

// @property (readonly, nonatomic) NSString *verifier; // ivar: _verifier
// @property (readonly, nonatomic) NSString *clientState; // ivar: _clientState
// @property (readonly, nonatomic) NSString *error; // ivar: _error
// @property (readonly, nonatomic) NSString *errorDescription; // ivar: _errorDescription
// @property (readonly, nonatomic) NSURL *errorURI; // ivar: _errorURI

    [authAdvice setValue:[NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/supported_browsers&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"] forKey:l(@"URI")];
    [authAdvice setValue:@(2) forKey:l(@"adviceCode")]; // 2 = embeeded
    [authAdvice setValue:@"ChIiEAiDoPbg0jIQ-tua6twzGCESAzAuMQ" forKey:l(@"clientState")]; // i don't know what this does....

    [%c(SSOKeychain) setAuthAdviceState:@"ChIiEAiDoPbg0jIQ-tua6twzGCESAzAuMQ" error:nil];

    callback(authAdvice, nil);

  // v13 = -[SSOAuthAdvice initWithJSONDictionary:](v12, v10);
  // v14 = -[SSOAuthAdvice clientState](v13);
  // v15 = objc_retainAutoreleasedReturnValue(v14);
  // objc_release(v15);
  // if ( v15 )
  // {
  //   v16 = -[SSOAuthAdvice clientState](v13);
  //   v17 = objc_retainAutoreleasedReturnValue(v16);
  //   +[SSOKeychain setAuthAdviceState:error:](v17, 0);

  // }
}

-(NSDictionary*)keychainItem
{
  GTMOAuth2Authentication *auth = [self auth];

  if ([[auth sid] length] > 0) {
    NSDictionary *fun = @{
        (__bridge id)kSecAttrAccount:[auth datasyncID],
        (__bridge id)kSecValueData:[[auth persistenceResponseString] dataUsingEncoding:NSUTF8StringEncoding]
      };
      NSLog(@"fun -> %@", fun);
      return fun;
  }
  return nil;
}
-(SSOIdentityPrivate*)initWithConfiguration:(id)configuration keychainItem:(NSDictionary*)keychainItem {
  SSOIdentityPrivate *identity = [self initWithConfiguration:configuration];
  if ( identity )
  {
    NSData *keychainData = [keychainItem objectForKey:(__bridge id)kSecValueData];
    if ( keychainData )
    {
      NSDictionary *decodedData = [%c(GTMOAuth2Authentication) dictionaryWithResponseString:[[NSString alloc] initWithData:keychainData encoding:4]];
      GTMOAuth2Authentication *auth = [identity auth];
      [auth setParameters:decodedData]; // easiest way to do this
      NSLog(@"fullName -> %@", decodedData[@"fullName"]);
      if ([decodedData[@"fullName"] length] > 0) {
        [self setUserFullName:decodedData[@"fullName"]];
      }
    }

    // later
    // fullNameData = +[SSOKeychain optionalDataForKey:identity:](
    //                  off_660AA0,
    //                  identity);
    // fullNameData = objc_retainAutoreleasedReturnValue(fullNameData);
    // if ( -[NSData length](fullNameData) )
    // {
    //   fullNameString = +[NSString alloc]();
    //   fullNameString = -[NSString initWithData:encoding:](fullNameString, fullNameData, 4);
    //   -[SSOIdentityPrivate setUserFullName:](identity, fullNameString);
    //   objc_release(fullNameString);
    // }
    // objc_release(fullNameData);
    // objc_release(keychainData);
  }
  return identity;
}

// -(void)requestResultsOfType:(id)type scopes:(id)scopes extraParameters:(id)extraParameters callback:(id)callback {
//   void *callstack[128];
//   int frames = backtrace(callstack, 128);
//   char **symbols = backtrace_symbols(callstack, frames);
//   NSMutableString *callstackString = [NSMutableString stringWithFormat:@"uwu >_<"];
//   for (int i = 0; i < frames; i++) {
//   [callstackString appendFormat:@"%s\n", symbols[i]];
//   }
//     NSLog(@"%@", callstackString);
//     return %orig;
// }



// "revoke" that token

-(id)revokeToken:(void(^)(NSError* error))callback 
{
    callback(nil);
    [self setAuth:nil];
    return nil; // maybe this will be fine? it should return the request but like... what request?
}
%end

%hook SSOService

// todo: we could probably make this correct
- (void)requestProfileForIdentity:(SSOIdentity *)identity callback:(void (^)(id profile, NSError *error))callback {
    NSDictionary *newProfile = @{
        @"id": [identity userID],
        @"email": [identity userEmail],
        @"verified_email": @YES,
        @"name": @"todo",
        @"given_name": @"todo",
        @"family_name": @"todo",
        @"picture": @"https://lh3.googleusercontent.com/a/default-user",
        @"locale": @"en"
    };


    dispatch_async(dispatch_get_main_queue(), ^{
        if (callback) {
            callback(newProfile, nil);
        }
    });
}

%end

// %hook GTMOAuth2SignIn
// +(id)googleUserInfoURL
// {
//   NSLog(@"fuck is in GTMO NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
//   return [NSURL URLWithString:@""];
// }
// %end



%hook SSOKeychain
+(BOOL)writeSharedKeychain:(NSMutableDictionary*)keys error:(NSError**)error {
  NSLog(@"dnagling keys -> %@", keys);
  return %orig;
}

%end

%hook GTMOAuth2SignInInternal

+(NSURL*)googleAuthorizationURL {
    return [NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/supported_browsers&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"];
}


-(BOOL)cookiesChanged:(GTMCookieStorage*)cookieStorage {
//   void *authCookie; // r6
//   authorizationURL; // r0
//   id cookieName; // r0
//   unsigned __int8 isSecure; // r1
//   char result; // r0
//   unsigned __int8 isHTTPOnly; // r1
//   id cookieData; // r0
//   code; // r4
//   auth; // r0
//   id cookies; // [sp+10h] [bp-7Ch]

//   authCookie = 0;
    // NSURL *authorizationURL = [self authorizationURL];
    NSURL *authorizationURL = [NSURL URLWithString:@"https://accounts.youtube.com/accounts/SetSID"];
    NSLog(@"authorization URL: %@", authorizationURL);
    NSArray *cookies = [cookieStorage cookiesForURL:authorizationURL];

    NSHTTPCookie *sid = nil;
    NSHTTPCookie *hsid = nil;
    NSHTTPCookie *ssid = nil;
    NSHTTPCookie *sapisid = nil;
    for (NSHTTPCookie* cookie in cookies) {
        NSString *cookieName = [cookie name];
        if ([cookieName isEqual:@"SID"]) {
            sid = cookie;
        }
        if ([cookieName isEqual:@"HSID"]) {
            hsid = cookie;
        }
        if ([cookieName isEqual:@"SSID"]) {
            ssid = cookie;
        }
        if ([cookieName isEqual:@"SAPISID"]) {
            sapisid = cookie;
        }
        if ([cookieName isEqual:@"__Secure-3PAPISID"]) { // same value as sapisid
            sapisid = cookie;
        }
    }

    NSLog(@"things");
    if (sid) {
        NSLog(@"SID: %@", [sid value]);
    }
    if (hsid) {
        NSLog(@"HSID: %@", [hsid value]);
    }
    if (ssid) {
        NSLog(@"ssid: %@", [ssid value]);
    }
    if (sapisid) {
        NSLog(@"sapisid: %@", [sapisid value]);
    }

    BOOL result = 0;
    if (sid && hsid && ssid && sapisid) {
        NSLog(@"SID: %@", [sid value]);
        NSLog(@"HSID: %@", [hsid value]);
        NSLog(@"SSID: %@", [hsid value]);
        NSLog(@"SAPISID: %@", [sapisid value]);

        // if ([sid isSecure])
        // {
        //     result = 0;
        //     if ([sid isHTTPOnly])
        //     {
            NSDictionary *code = @{
                @"code":@"sixty nine", // just to avoid annoying rewrite things
                @"accessToken":@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!",
                @"refreshToken":@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!",
                @"SID":[sid value],
                @"HSID":[hsid value],
                @"SSID":[ssid value],
                @"SAPISID":[sapisid value]
            };
            GTMOAuth2Authentication *auth = [self authentication];
            [auth setKeysForResponseDictionary:code];
            if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"] || [version() isEqualToString:@"1.1.0"]) {
              [self handleCallbackReached];
            } else {
              [self authCodeObtained];
            }
            [cookieStorage deleteCookie:sid];
            return 1;
            // }
        // }
    }
    return result;
}

%end

%hook SSOAuthorizationImpl

-(void)authorizeRequest:(NSMutableURLRequest*)request handler:(id)handler delegate:(id)delegate didFinishSelector:(SEL)selector {
  NSThread *thread = [NSThread currentThread];
  id callback = [%c(AuthorizerCallback) callbackWithRequest:request handler:handler delegate:delegate selector:selector thread:thread];

  // the following is a bit of a hack, but oh well

  GTMOAuth2Authentication *auth = [[self identity] auth];
  int errorCode = 0;
  NSURL *url = [request URL];

  NSString *sid = [auth sid];
  NSString *hsid = [auth hsid];
  NSString *ssid = [auth ssid];
  NSString *sidcc = [auth sidcc];
  NSString *sapisid = [auth sapisid];
  NSString *datasyncID = [auth datasyncID];

  if (![self shouldAuthorizeAllRequests]) {
    errorCode = -1004;
    BOOL isSecure = [[url scheme] caseInsensitiveCompare:@"https"];
    if (isSecure)
      goto requestOK;
  }

  NSString *query = [url query];
  BOOL hasNoauth = NO;
  for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
      NSArray *kv = [pair componentsSeparatedByString:@"="];
      if (kv.count == 2 && [kv[0] isEqualToString:@"noauth"] && [kv[1] isEqualToString:@"1"]) {
          hasNoauth = YES;
          break;
      }
  }

  if (hasNoauth) {
    goto done;
  }

  errorCode = -1001;
  if ([hsid length] && [ssid length] && [sapisid length] && [sid length]&& [sidcc length] && [datasyncID length])
  {
    if ( request )
    {
        // NSHTTPCookieStorage *sharedHTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        // NSArray *cookies = [sharedHTTPCookieStorage cookies];
        // for (id cookie in cookies) {
        //     [sharedHTTPCookieStorage deleteCookie:cookie];
        // }
        [request setHTTPShouldHandleCookies:NO];
        NSString *cookieData = [NSString stringWithFormat:@"hideBrowserUpgradeBox=true; HSID=%@; SSID=%@; SAPISID=%@; __Secure-3PAPISID=%@; SID=%@; SIDCC=%@", hsid,ssid,sapisid,sapisid,sid,sidcc];
        [request setValue:cookieData forHTTPHeaderField:@"Cookie"];

        // SAPISIDHASH
        long unixTime = (long)[[NSDate date] timeIntervalSince1970];
        NSString *unhashedSAPISIDHASH = [NSString stringWithFormat:@"%@ %ld %@ https://www.youtube.com", datasyncID, unixTime, sapisid];
        // NSLog(@"unhashed SAPISIDHASH -> %@", unhashedSAPISIDHASH);

        NSData *unhashedData = [unhashedSAPISIDHASH dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];

        CC_SHA1(unhashedData.bytes, (CC_LONG)unhashedData.length, digest);

        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

        for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        {
            [output appendFormat:@"%02x", digest[i]];
        }
        // NSLog(@"Hashed SAPISID: %@", output);
        [request setValue:[NSString stringWithFormat:@"SAPISIDHASH %ld_%@_u", unixTime, output] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"https://www.youtube.com" forHTTPHeaderField:@"Origin"];
    }
    goto done;
  }
requestOK: ; // i hate compilers, why is this semicolon needed                                                                                                                         
  // todo: i forget why i named it requestOK
  NSDictionary *userInfo = nil;
  if (request)
    userInfo = [NSDictionary dictionaryWithObject:request forKey:@"request"];
  NSError *error = [NSError errorWithDomain:@"com.google.sso" code:errorCode userInfo:userInfo];
  [callback setError:error];

done:
  [self invokeCallback:callback];
}

%new
-(NSString*)channelID {
  return [[[self identity] auth] channelID]; // im lazy and dont wanna change shit
}

%end

// clears all keychain items on start
// %ctor {
// NSArray *secItemClasses = @[
//     (__bridge id)kSecClassGenericPassword,
//     (__bridge id)kSecClassInternetPassword,
//     (__bridge id)kSecClassCertificate,
//     (__bridge id)kSecClassKey,
//     (__bridge id)kSecClassIdentity
// ];

// for (id secItemClass in secItemClasses) {
//     NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
//     SecItemDelete((__bridge CFDictionaryRef)spec);
// }

// }

%hook GTMOAuth2Authentication

// convience
%new
-(NSString*)sid {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"SID"];
}

%new
-(NSString*)hsid {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"HSID"];
}

%new
-(NSString*)ssid {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"SSID"];
}

%new
-(NSString*)sapisid {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"SAPISID"];
}

%new
-(NSString*)sidcc {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"SIDCC"];
}

%new
-(NSString*)datasyncID {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"DATASYNC_ID"];
}

%new
-(NSString*)channelID {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"CHANNEL_ID"];
}


// -(NSString*)userAgent {
//     return @"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329";
// }

-(BOOL)canAuthorize
{
    NSString *sid = [self sid];
    NSString *hsid = [self hsid];
    NSString *ssid = [self ssid];
    NSString *sapisid = [self sapisid];
    NSString *sidcc = [self sidcc];
    NSString *datasyncID = [self datasyncID];

    return [hsid length] && [ssid length] && [sapisid length] && [sid length] && [datasyncID length] && [sidcc length];
}

-(id)persistenceResponseString
{

  NSLog(@"persistance string called!");
  NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:17];
  [data setValue:@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!" forKey:@"refresh_token"];
  [data setValue:@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!" forKey:@"access_token"];

  [data setValue:@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!" forKey:@"refreshToken"];

  [data setValue:[self sid] forKey:@"SID"];
  [data setValue:[self hsid] forKey:@"HSID"];
  [data setValue:[self ssid] forKey:@"SSID"];
  [data setValue:[self sapisid] forKey:@"SAPISID"];
  [data setValue:[self sidcc] forKey:@"SIDCC"];
  [data setValue:[self datasyncID] forKey:@"DATASYNC_ID"];
  [data setValue:[self channelID] forKey:@"CHANNEL_ID"];
  [data setValue:[self datasyncID] forKey:@"userID"]; // idk

  [data setValue:[self serviceProvider] forKey:@"serviceProvider"];
  [data setValue:[[self parameters] objectForKey:@"userEmail"] forKey:@"email"];
  [data setValue:[[self parameters] objectForKey:@"userEmail"] forKey:@"userEmail"];
  [data setValue:[[self parameters] objectForKey:@"fullName"] forKey:@"fullName"];
  [data setValue:[self userEmailIsVerified] forKey:@"isVerified"];
  [data setValue:[self scope] forKey:@"scope"];
  return [%c(GTMOAuth2Authentication) encodedQueryParametersForDictionary:data];
}

-(id)beginTokenFetchWithDelegate:(id)delegate didFinishSelector:(SEL)didFinishSelector {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://m.youtube.com/feed/library?app=mobile"]]; // we need to use this to get the channel id & datasync id. Pain.

   NSString *sid = [self sid];
  NSString *hsid = [self hsid];
  NSString *ssid = [self ssid];
  NSString *sapisid = [self sapisid];

    NSString *cookieData = [NSString stringWithFormat:@"hideBrowserUpgradeBox=true; HSID=%@; SSID=%@; SAPISID=%@; __Secure-3PAPISID=%@; SID=%@", hsid,ssid,sapisid,sapisid,sid];
    [request setValue:cookieData forHTTPHeaderField:@"Cookie"];
    [request setValue:@"https://accounts.google.com/" forHTTPHeaderField:@"Referer"];
    // [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329" forHTTPHeaderField:@"User-Agent"];
    // [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329" forHTTPHeaderField:@"user-agent"];
    
//   GTMHTTPFetcher *fetcherService = [self fetcherService];
//   GTMHTTPFetcher *httpFetcher = nil;
//   if ( fetcherService )
//   {
//     httpFetcher = [fetcherService fetcherWithRequest:request]
//     [httpFetcher setAuthorizer:nil];
//   }
//   else
//   {
  if ([[self datasyncID] length]) { // todo: this is here so it doesn't request after we got everything, since this is the same function used to renew access tokens.
    return nil;
  }

  GTMHTTPFetcher *httpFetcher = [%c(GTMHTTPFetcher) fetcherWithRequest:request];
//   }
  [httpFetcher setCommentWithFormat:@"fetch tokens for"];
  [httpFetcher setRetryEnabled:1];
  [httpFetcher setMaxRetryInterval:15.0];
  [httpFetcher setProperty:delegate forKey:@"delegate"];
  if ( didFinishSelector )
  {
    [httpFetcher setProperty:NSStringFromSelector(didFinishSelector) forKey:@"sel"];
  }
  if ([httpFetcher beginFetchWithDelegate:self didFinishSelector:@selector(tokenFetcher:finishedWithData:error:)])
  {
    [self notifyFetchIsRunning:1 fetcher:httpFetcher type:@"token"];
  }
  else
  {
    httpFetcher = nil;
    NSError *error = [NSError errorWithDomain:@"com.google.HTTPStatus" code:-1 userInfo:nil];
    [%c(GTMOAuth2Authentication) invokeDelegate:delegate selector:didFinishSelector object:self object:0 object:error];
  }
  return httpFetcher;
}

// purpose is to get extra data which isn't included in the other requests. Mainly email & full name
%new
-(void)fillInTokenExtraDataWithParameters:(NSDictionary*)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://m.youtube.com/getAccountSwitcherEndpoint"]]; // thanks for asking, yes, it is the same as the user in myprofile.x. it doesn't include channel id, so we can't use this outright, would make my life easier tho.

    NSString *sid = [self sid];
    NSString *hsid = [self hsid];
    NSString *ssid = [self ssid];
    NSString *sapisid = [self sapisid];

    NSString *cookieData = [NSString stringWithFormat:@"hideBrowserUpgradeBox=true; HSID=%@; SSID=%@; SAPISID=%@; __Secure-3PAPISID=%@; SID=%@", hsid,ssid,sapisid,sapisid,sid];
    [request setValue:cookieData forHTTPHeaderField:@"Cookie"];

    // simple get request, so we don't need the datasync id. Yay!

    [params setValue:@"invalid@email.address" forKey:@"userEmail"];
    [params setValue:@"invalid@email.address" forKey:@"email"];

    NSURLResponse * rsp = nil;
    NSError *err = nil;
    NSData *rawData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&rsp
                                                          error:&err];

    if (err) {
        NSLog(@"Error fetching extra token data! %@",err);
        return;
    } else {
          const unsigned char* bytes = [rawData bytes];
          NSUInteger length = [rawData length];
          NSData *cleanData = rawData;
          if (length >= 5 &&  // jsonp stuff because hell
            bytes[0] == ')' && 
            bytes[1] == ']' && 
            bytes[2] == '}' && 
            bytes[3] == '\'' && 
            bytes[4] == '\n') {
            bytes += 5;
            length -= 5;
            cleanData = [NSData dataWithBytes:bytes length:length];
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:cleanData options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"json -> %@", json);
        NSDictionary *headerInfo = [TRJSONUtils dictFromJSON:json 
            keyPath:@"data.actions[0].getMultiPageMenuAction.menu.multiPageMenuRenderer.sections[0].accountSectionListRenderer.header.googleAccountHeaderRenderer"];

        NSString *email = headerInfo[@"email"][@"simpleText"];
        NSString *name = headerInfo[@"name"][@"simpleText"];

        if ([email length] &&
            [name length]) {
          [params setValue:email forKey:@"userEmail"];
          [params setValue:email forKey:@"email"];
          [params setValue:name forKey:@"fullName"];
        }
    }
}

// check for V6c17240b|| and call it bad
-(void)tokenFetcher:(GTMHTTPFetcher*)fetcher finishedWithData:(NSData*)data error:(NSError*)error
{
  [self notifyFetchIsRunning:NO fetcher:fetcher type:0];
  NSDictionary *responseHeaders = [fetcher responseHeaders];
  NSString *contentType = [responseHeaders valueForKey:@"Content-Type"];
  BOOL isHTML = [contentType hasPrefix:@"text/html"];
  int dataLen = [data length];
  if (!error)
  {
    error = nil;
    if ( dataLen )
    {
      if ( isHTML )
      {
        // Extract DATASYNC_ID from HTML
        NSString *htmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *datasyncID = nil;
        
        NSRange searchRange = [htmlString rangeOfString:@"\"datasyncId\":\""];
        if (searchRange.location != NSNotFound) {
          NSInteger startPos = searchRange.location + searchRange.length;
          NSRange endRange = [htmlString rangeOfString:@"||" options:0 range:NSMakeRange(startPos, [htmlString length] - startPos)];
          
          if (endRange.location != NSNotFound) {
            datasyncID = [htmlString substringWithRange:NSMakeRange(startPos, endRange.location - startPos)];
            NSLog(@"Extracted DATASYNC_ID: %@", datasyncID);

            NSMutableDictionary *params = [[self parameters] mutableCopy];
            if (!params) {
              params = [NSMutableDictionary dictionary];
            }
            [params setObject:datasyncID forKey:@"DATASYNC_ID"];
            [params setObject:datasyncID forKey:@"userID"];

            // I want to at least **try** to get a correct email & full name, so if we are on 2.0.0+, we will run this pain, since I want to do it synchronously. Otherwise, invalid@email.address will suffice.
            
            if ([version() characterAtIndex:0] != '1') {
              [self fillInTokenExtraDataWithParameters:params];
            } else {
                  [params setValue:@"invalid@email.address" forKey:@"userEmail"];
                  [params setValue:@"invalid@email.address" forKey:@"email"];
            }

            [params setValue:@"this value shouldn't be seen. if you see this in a request, ping @Preloading with the request sent!" forKey:@"refresh_token"];


            // BY FAR this is the most unreliable logic here, i change it like every update!
            NSString *channelID = nil;

            // 1. Find the LAST occurrence of the end marker
            NSString *endMarker = @"\\x22,\\x22webPageType\\x22:\\x22WEB_PAGE_TYPE_CHANNEL\\x22";
            NSRange endRange = [htmlString rangeOfString:endMarker options:NSBackwardsSearch];

            if (endRange.location != NSNotFound) {
                // 2. Search BACKWARDS from that position to find the nearest "/channel/"
                NSRange searchRange = NSMakeRange(0, endRange.location);
                NSRange startRange = [htmlString rangeOfString:@"\\/channel\\/" 
                                                      options:NSBackwardsSearch 
                                                        range:searchRange];

                if (startRange.location != NSNotFound) {
                    NSInteger idStart = startRange.location + startRange.length;
                    NSInteger idLength = endRange.location - idStart;
                    
                    if (idLength > 0) {
                        channelID = [htmlString substringWithRange:NSMakeRange(idStart, idLength)];
                        
                        // Clean up any remaining escapes or slashes
                        channelID = [channelID stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                        if ([channelID hasSuffix:@"/"]) {
                            channelID = [channelID substringToIndex:[channelID length] - 1];
                        }
                    }
                }
            }

            if (!channelID) {
              NSLog(@"fallback fetcher!!!");
              NSRange fallbackSearch = [htmlString rangeOfString:@"\"url\":\"/channel/"];
              if (fallbackSearch.location != NSNotFound) {
                NSInteger fallbackStart = fallbackSearch.location + fallbackSearch.length;
                NSRange fallbackEnd = [htmlString rangeOfString:@"/videos\""
                                                        options:0
                                                          range:NSMakeRange(fallbackStart, [htmlString length] - fallbackStart)];
                if (fallbackEnd.location != NSNotFound) {
                  channelID = [htmlString substringWithRange:NSMakeRange(fallbackStart, fallbackEnd.location - fallbackStart)];
                }
              }
            }

            if (channelID) {
              NSLog(@"Extracted CHANNEL_ID: %@", channelID);
              [params setObject:channelID forKey:@"CHANNEL_ID"];
            }

            NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

            for (NSHTTPCookie *cookie in [storage cookiesForURL:[NSURL URLWithString:@"https://www.youtube.com"]]) {
                if ([cookie.name isEqualToString:@"SIDCC"]) {
                    [params setObject:cookie.value forKey:@"SIDCC"];
                }
            }

            [self setParameters:params];
              NSLog(@"params after thingy -> %@", params);
            [params release];

            [self setExpiresIn:@100000000];
          }
        }
        [htmlString release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kGTMOAuth2RefreshTokenChanged" object:self userInfo:0];
      }
    }
  }
  id delegate = [fetcher propertyForKey:@"delegate"];
  NSString *selectorStr = [fetcher propertyForKey:@"sel"];
  SEL selector = nil;
  if ( selectorStr )
    selector = NSSelectorFromString(selectorStr);
  NSLog(@"error from token thingy -> %@", error);
  [%c(GTMOAuth2Authentication) invokeDelegate:delegate selector:selector object:self object:fetcher object:error];
  [fetcher setProperty:nil forKey:@"delegate"];
}

-(BOOL)authorizeRequestImmediateArgs:(GTMOAuth2AuthorizationArgs*)authArgs
{
  int errorCode = 0;

  NSMutableURLRequest *request = [authArgs request];
  NSURL *url = [request URL];

  NSString *sid = [self sid];
  NSString *hsid = [self hsid];
  NSString *ssid = [self ssid];
  NSString *sidcc = [self sidcc];
  NSString *sapisid = [self sapisid];
  NSString *datasyncID = [self datasyncID];

  if (![self shouldAuthorizeAllRequests]) {
    errorCode = -1004;
    BOOL isSecure = [[url scheme] caseInsensitiveCompare:@"https"];
    if (isSecure)
      goto requestOK;
  }

  NSString *query = [url query];
  BOOL hasNoauth = NO;
  for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
      NSArray *kv = [pair componentsSeparatedByString:@"="];
      if (kv.count == 2 && [kv[0] isEqualToString:@"noauth"] && [kv[1] isEqualToString:@"1"]) {
          hasNoauth = YES;
          break;
      }
  }

  if (hasNoauth) {
    goto done;
  }

  errorCode = -1001;
  if ([hsid length] && [ssid length] && [sapisid length] && [sid length]&& [sidcc length] && [datasyncID length])
  {
    if ( request )
    {
        // NSHTTPCookieStorage *sharedHTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        // NSArray *cookies = [sharedHTTPCookieStorage cookies];
        // for (id cookie in cookies) {
        //     [sharedHTTPCookieStorage deleteCookie:cookie];
        // }
        [request setHTTPShouldHandleCookies:NO];
        NSString *cookieData = [NSString stringWithFormat:@"hideBrowserUpgradeBox=true; HSID=%@; SSID=%@; SAPISID=%@; __Secure-3PAPISID=%@; SID=%@; SIDCC=%@", hsid,ssid,sapisid,sapisid,sid,sidcc];
        [request setValue:cookieData forHTTPHeaderField:@"Cookie"];

        // SAPISIDHASH
        long unixTime = (long)[[NSDate date] timeIntervalSince1970];
        NSString *unhashedSAPISIDHASH = [NSString stringWithFormat:@"%@ %ld %@ https://www.youtube.com", datasyncID, unixTime, sapisid];
        // NSLog(@"unhashed SAPISIDHASH -> %@", unhashedSAPISIDHASH);

        NSData *unhashedData = [unhashedSAPISIDHASH dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];

        CC_SHA1(unhashedData.bytes, (CC_LONG)unhashedData.length, digest);

        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

        for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        {
            [output appendFormat:@"%02x", digest[i]];
        }
        // NSLog(@"Hashed SAPISID: %@", output);
        [request setValue:[NSString stringWithFormat:@"SAPISIDHASH %ld_%@_u", unixTime, output] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"https://www.youtube.com" forHTTPHeaderField:@"Origin"];

          
        
      
    }
    [authArgs setError:nil];
    goto done;
  }
requestOK:
  if (![authArgs error])
  {
    NSDictionary *userInfo = nil;
    if (request)
      userInfo = [NSDictionary dictionaryWithObject:request forKey:@"request"];
    NSError *error = [NSError errorWithDomain:@"com.google.GTMOAuth2" code:errorCode userInfo:userInfo];
    [authArgs setError:error];
  }
done:
  if ([authArgs delegate] || [authArgs completionHandler])
  {
    NSThread *authThread = [authArgs thread];
    BOOL areThreadsSame = [authThread isEqual:[NSThread currentThread]];
    [self performSelector:@selector(invokeCallbackArgs:) onThread:authThread withObject:authArgs waitUntilDone:areThreadsSame];
  }
  return [authArgs error] == nil;
}

// -(BOOL) shouldRefreshAccessToken {
//   return 0;
// }

%end

%hook GTMOAuth2SignIn

// void __cdecl -[GTMOAuth2SignIn infoFetcher:finishedWithData:error:](
//         GTMOAuth2SignIn *self,
//         SEL a2,
//         id fetcher,
//         NSData *data,
//         NSError *error)
// {
//   GTMOAuth2Authentication *authentication; // r5
//   NSMutableDictionary *v9; // r0 MAPDST
//   NSString *email; // r0
//   id v12; // r0
//   id v13; // r0

//   authentication = -[GTMOAuth2SignIn authentication](self);
//   -[GTMOAuth2Authentication notifyFetchIsRunning:fetcher:type:](
//     authentication,
//     0,
//     fetcher,
//     0);
//   -[GTMOAuth2SignIn setPendingFetcher:](self, 0);
//   if ( !error )
//   {
//     if ( data )
//     {
//       v9 = -[GTMOAuth2Authentication dictionaryWithJSONData:](authentication, data);
//       if ( v9 )
//       {
//         -[GTMOAuth2SignIn setUserProfile:](self, v9);
//         email = (NSString *)-[NSMutableDictionary objectForKey:](v9, CFSTR("email"));
//         -[GTMOAuth2Authentication setUserEmail:](authentication, email);
//         v12 = -[NSMutableDictionary objectForKey:](v9, CFSTR("verified_email"));
//         v13 = objc_msgSend(v12, "stringValue");
//         -[GTMOAuth2Authentication setUserEmailIsVerified:](authentication, v13);
//       }
//     }
//   }
//   -[GTMOAuth2SignIn finishSignInWithError:](self, error);
// }

-(void)fetchGoogleUserInfo
{
  // based on -[GTMOAuth2SignIn infoFetcher:finishedWithData:error:]
  GTMOAuth2Authentication *authentication = [self authentication];
  // [self setUserProfile:v9];

  // probably not a smart idea to set this >_<
  // [authentication setUserEmail:@"invalid@email.address"];


  // v12 = -[NSMutableDictionary objectForKey:](v9, CFSTR("verified_email"));
  // v13 = objc_msgSend(v12, "`");
  [authentication setUserEmailIsVerified:@"true"];

  [self finishSignInWithError:nil];
  // GTMOAuth2Authentication *v3; // r4
  // id v4; // r0
  // id v5; // r6

  // v3 = -[GTMOAuth2SignIn authentication](self);
  // v4 = -[GTMOAuth2SignIn class](self);
  // v5 = objc_msgSend(v4, "userInfoFetcherWithAuth:", v3);
  // objc_msgSend(v5, "beginFetchWithDelegate:didFinishSelector:", self, "infoFetcher:finishedWithData:error:");
  // -[GTMOAuth2SignIn setPendingFetcher:](self, v5);
  // -[GTMOAuth2Authentication notifyFetchIsRunning:fetcher:type:](
  //   v3,
  //   1,
  //   v5,
  //   off_4A4978[0]);
}
%end

%hook GTMHTTPFetcher
-(void)addCookiesToRequest:(id)unk1 {
  return;
}

// - (id)connection:(id)conn
//  willSendRequest:(NSURLRequest *)request
// redirectResponse:(id)response
// {
//     NSURLRequest *origReq = %orig;

//     NSMutableURLRequest *mutableReq;
//     if ([origReq isKindOfClass:[NSMutableURLRequest class]]) {
//         mutableReq = (NSMutableURLRequest *)origReq;
//     } else {
//         mutableReq = [origReq mutableCopy];
//     }

//     [mutableReq setValue:
//      @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15,gzip(gfe)"
//       forHTTPHeaderField:@"User-Agent"];

//     return mutableReq;
// }

%end

%ctor {
  NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; U; CPU %@ %@ like Mac OS X; %@)",
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"],
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
    [[UIDevice currentDevice] model],
    [[UIDevice currentDevice] systemName],
    [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"],
    [[NSLocale currentLocale] localeIdentifier]];
  NSDictionary *dictionary = @{@"UserAgent": userAgent};
  [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
  [[NSUserDefaults standardUserDefaults] synchronize];

}

// todo: look at -[GTMHTTPFetcher beginFetchMayDelay:mayAuthorize:]


// %hook YTSignInViewController

// -(YTSignInViewController*)initWithAuth:(GTMOAuth2Authentication *)auth authedBlock:(id)authedBlock failedBlock:(id)failedBlock canceledBlock:(id)canceledBlock
// {
//     // GTMOAuth2SignInInternal *signInClass = [%c(GTMOAuth2ViewControllerTouch) signInClass];
//     // NSURL *authorizationURL = [signInClass googleAuthorizationURL];
//     // NSURL *authorizationURL = [%c(GTMOAuth2SignInInternal) googleAuthorizationURL];
//     // NSURL *authorizationURL = [NSURL URLWithString:@"https://preloading.dev"];
//     NSURL *authorizationURL = [NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/signin?action_handle_signin=true&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"];

//     self = [self initWithAuthentication:auth
//                         authorizationURL:authorizationURL
//                         keychainItemName:nil
//                         completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *authentication, NSError *error) {
//                             if (error) {
//                                 NSString *domain = [error domain];
//                                 if ([domain isEqualToString:NSCocoaErrorDomain]) {
//                                     if ([error code] == -1000) {
//                                         // User canceled
//                                         if (canceledBlock) {
//                                             ((void (^)(void))canceledBlock)(); // this is wrong
//                                         }
//                                     } else {
//                                         // Authentication failed with specific error
//                                         if (failedBlock) {
//                                             ((void (^)(NSError *))failedBlock)(error);
//                                         }
//                                     }
//                                 } else {
//                                     // Other domain error
//                                     if (failedBlock) {
//                                         ((void (^)(NSError *))failedBlock)(error);
//                                     }
//                                 }
//                             } else {
//                                 // Authentication succeeded
//                                 if (authedBlock) {
//                                     ((void (^)(void))authedBlock)();
//                                 }
//                             }
//                         }];
//   if ( self )
//   {
//     [self setBrowserCookiesURL:nil];
//     NSHTTPCookieStorage *sharedHTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//     NSArray *cookies = [sharedHTTPCookieStorage cookies];
//     for (id cookie in cookies) {
//         [sharedHTTPCookieStorage deleteCookie:cookie];
//     }
//     NSString *loadingText = @"Loading..."; //localizedStringForKey(@"signin.loading");
//     [self setInitialHTMLString:[NSString stringWithFormat:@"<p style=\"font-size:22px; font-family:Helvetica; margin:auto;position:absolute; top:120px; text-align:center;width:290px;\">%@</p>", loadingText]];
//   }
//   return self;
// }

// %end


// %hook YTNavigation_iPhone 
// -(void)authenticateFailedWithError:(id)error message:(NSString*)message {
//         void *callstack[128];
// 	int frames = backtrace(callstack, 128);
// 	char **symbols = backtrace_symbols(callstack, frames);
// 	NSMutableString *callstackString = [NSMutableString stringWithFormat:@"YTNavigation_iPhone authenticateFailedWithError message: %@", message];
// 	for (int i = 0; i < frames; i++) {
// 		[callstackString appendFormat:@"%s\n", symbols[i]];
// 	}
// 	NSLog(@"%@", callstackString);
// }


// %end



// TODO: check if polyfil isn't loaded already (._.)
// JS Polyfils (i blame iOS 5!) Sadly, this makes iOS 5 kinda slow...
%hook GTMOAuth2ViewControllerTouch

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    %orig;
    
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    if ([systemVersion floatValue] < 6.0) {
      NSString *js = [[NSString alloc] initWithBytes:signinpolyfil_js 
                                          length:signinpolyfil_js_len 
                                        encoding:NSUTF8StringEncoding];
      [webView stringByEvaluatingJavaScriptFromString:js];
      [js release];
    }
}
%end
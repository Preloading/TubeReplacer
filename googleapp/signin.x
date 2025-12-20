#include <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#include "appheaders.h"


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

//// END HEADERS

%hook GTMOAuth2SignInInternal
+(NSURL*)googleAuthorizationURL {
    return [NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/signin?action_handle_signin=true&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"];
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
            [self handleCallbackReached];
            [cookieStorage deleteCookie:sid];
            return 1;
            // }
        // }
    }
    return result;
}

%end

@interface GTMOAuth2Authentication (TubeReplacer)
- (NSString*)sid;
- (NSString*)hsid;
- (NSString*)ssid;
- (NSString*)sapisid;
- (NSString*)datasyncID;
@end

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
-(NSString*)datasyncID {
    NSDictionary *parameters = [self parameters];
    return [parameters objectForKey:@"DATASYNC_ID"];
}

-(NSString*)userAgent {
    return @"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329";
}


-(id)beginTokenFetchWithDelegate:(id)delegate didFinishSelector:(SEL)didFinishSelector {
    NSLog(@"did finish selector: %@", NSStringFromSelector(didFinishSelector)); // -[GTMOAuth2SignIn auth:finishedWithFetcher:error:]
    NSLog(@"sid is: %@", [self sid]);
    %log;

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://m.youtube.com"]];

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
        
        NSRange searchRange = [htmlString rangeOfString:@"\"DATASYNC_ID\":\""];
        if (searchRange.location != NSNotFound) {
          NSInteger startPos = searchRange.location + searchRange.length;
          NSRange endRange = [htmlString rangeOfString:@"||" options:0 range:NSMakeRange(startPos, [htmlString length] - startPos)];
          
          if (endRange.location != NSNotFound) {
            datasyncID = [htmlString substringWithRange:NSMakeRange(startPos, endRange.location - startPos)];
            NSLog(@"Extracted DATASYNC_ID: %@", datasyncID);
            
            // Store it in the authentication object if needed
            NSMutableDictionary *params = [[self parameters] mutableCopy];
            if (!params) {
              params = [NSMutableDictionary dictionary];
            }
            [params setObject:datasyncID forKey:@"DATASYNC_ID"];
            [self setParameters:params];
            [params release];
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
  NSString *sapisid = [self sapisid];
  NSString *datasyncID = [self datasyncID];

  if (![self shouldAuthorizeAllRequests]) {
    errorCode = -1004;
    BOOL isSecure = [[url scheme] caseInsensitiveCompare:@"https"];
    if (isSecure)
      goto requestOK;
  }
  errorCode = -1001;
  if ([hsid length] && [ssid length] && [sapisid length] && [sid length] && [datasyncID length])
  {
    if ( request )
    {
        NSString *cookieData = [NSString stringWithFormat:@"hideBrowserUpgradeBox=true; HSID=%@; SSID=%@; SAPISID=%@; __Secure-3PAPISID=%@; SID=%@", hsid,ssid,sapisid,sapisid,sid];
        [request setValue:cookieData forHTTPHeaderField:@"Cookie"];

        // SAPISIDHASH
        long unixTime = (long)[[NSDate date] timeIntervalSince1970];
        NSString *unhashedSAPISIDHASH = [NSString stringWithFormat:@"%@ %ld %@ %@://%@", datasyncID, unixTime, sapisid, [url scheme], [url host]];
        NSLog(@"unhashed SAPISIDHASH -> %@", unhashedSAPISIDHASH);

        NSData *unhashedData = [unhashedSAPISIDHASH dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];

        CC_SHA1(unhashedData.bytes, (CC_LONG)unhashedData.length, digest);

        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

        for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        {
            [output appendFormat:@"%02x", digest[i]];
        }
        NSLog(@"Hashed SAPISID: %@", output);
        [request setValue:[NSString stringWithFormat:@"SAPISIDHASH %ld_%@_u", unixTime, output] forHTTPHeaderField:@"Authorization"];


          

      
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

%end

%hook GTMHTTPFetcher

- (id)connection:(id)conn
 willSendRequest:(NSURLRequest *)request
redirectResponse:(id)response
{
    NSURLRequest *origReq = %orig;

    NSMutableURLRequest *mutableReq;
    if ([origReq isKindOfClass:[NSMutableURLRequest class]]) {
        mutableReq = (NSMutableURLRequest *)origReq;
    } else {
        mutableReq = [origReq mutableCopy];
    }

    [mutableReq setValue:
     @"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) "
      "AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329"
      forHTTPHeaderField:@"User-Agent"];

    return mutableReq;
}

%end

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
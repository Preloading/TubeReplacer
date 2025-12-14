#include <Foundation/Foundation.h>
#include "appheaders.h"

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
    NSURL *authorizationURL = [self authorizationURL];
    NSArray *cookies = [cookieStorage cookiesForURL:authorizationURL];

    NSHTTPCookie *sid = nil;
    NSHTTPCookie *hsid = nil;
    for (NSHTTPCookie* cookie in cookies) {
        NSString *cookieName = [cookie name];
        if ([cookieName isEqual:@"SID"]) {
            sid = cookie;
        }
        if ([cookieName isEqual:@"HSID"]) {
            hsid = cookie;
        }
    }

    NSLog(@"things");
    if (sid) {
        NSLog(@"SID: %@", [sid value]);
    }
    if (hsid) {
        NSLog(@"HSID: %@", [hsid value]);
    }

    BOOL result = 0;
    if (sid && hsid) {
        NSLog(@"SID: %@", [sid value]);
        NSLog(@"HSID: %@", [hsid value]);

        

        // if ([sid isSecure])
        // {
        //     result = 0;
        //     if ([sid isHTTPOnly])
        //     {
            NSString *cookieData = [sid value];
            NSDictionary *code = [NSDictionary dictionaryWithObject:cookieData forKey:@"code"];
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
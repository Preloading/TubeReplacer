#import "challengesolver-webview.h"
#import "challengesolver-potokens.h"
#include "TRChallengeSolverPolyfillProtocol.h"

@implementation TRPOTokenSolver (WebView)
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"web error: %@", error);
}


-(void)initWebViewWithCallback:(void(^)())callback {
    if (self.isWebViewReady) {
        callback();
        return;
    }
    self.webviewReadyCallback = callback;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = @"/Library/Application Support/TubeReplacer/challenge_solver.html";
        NSError *error = nil;

        NSString *html = [NSString stringWithContentsOfFile:path
                                                    encoding:NSUTF8StringEncoding
                                                        error:&error];

        [NSURLProtocol registerClass:[TRChallengeSolverPolyfillProtocol class]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.webView) return;

            UIWindow *window = [UIApplication sharedApplication].keyWindow;

            // self.webView = [[UIWebView alloc] initWithFrame:window.bounds]; // visible
            self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(-500, -500, 100, 100)] autorelease]; // invisible
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
        });
    });
}

-(void)webViewScriptsLoaded:(UIWebView*)webView {
    self.isWebViewReady = true;
    self.webviewReadyCallback();
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
        if ([url isEqualToString:@"status://poReady"]) {
            self.isReadyToMintTokens = YES; 
            self.poGenReady();
        }
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

@end
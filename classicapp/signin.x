#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface YTAccountAuthenticator : NSObject
+(instancetype)sharedAuthenticator;
-(void)setAccountYouTubeName:(NSString*)name;
-(void)_postNewAccountTokenAvailable;
-(void)setAccountToken:(NSString*)token;
-(void)setAccount:(NSString*)account; // maybe
-(void)setPassword:(NSString*)password;
-(void)setAccountTokenDate:(NSDate*)date;
@end

@interface YTCustomAlert : UIView
@property (nonatomic, retain) UIView *panel;
@property (nonatomic, retain) UIWebView *web;

- (instancetype)init;
- (void)show;
- (void)dismiss;
- (void)cookiesChanged:(NSNotification *)notification;
@end

@implementation YTCustomAlert

- (instancetype)init {
    // this is kinda terrible, but it "works" so im gonna roll with it for now.
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {

        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];

        // Panel (alert box)
        
        self.panel = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 420)] autorelease];
        self.panel.center = self.center;
        UIColor *backgroundColor = [UIColor colorWithRed:0.15f green:0.21f blue:0.36f alpha:0.75f];
        self.panel.backgroundColor = backgroundColor;
        self.panel.layer.cornerRadius = 12.0;
        self.panel.layer.masksToBounds = NO;

        // border
        self.panel.layer.borderColor = [UIColor whiteColor].CGColor;
        self.panel.layer.borderWidth = 2.0f;
        self.panel.clipsToBounds = YES; // Recommended if using cornerRadius


        // shadow
        self.panel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.panel.layer.shadowOpacity = 0.5;
        self.panel.layer.shadowRadius = 6.0;
        self.panel.layer.shadowOffset = CGSizeMake(0, 3);

        [self addSubview:self.panel];

        // Title
        UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, 260, 30)] autorelease];
        title.text = @"YouTube Password";
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:17];
        title.backgroundColor = [UIColor clearColor];
        title.textColor = [UIColor whiteColor];
        [self.panel addSubview:title];

        // WebView
        self.web = [[[UIWebView alloc] initWithFrame:CGRectMake(10, 50, 260, 300)] autorelease];
        self.web.scrollView.bounces = NO;
        [self.panel addSubview:self.web];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(cookiesChanged:)
                                             name:NSHTTPCookieManagerCookiesChangedNotification
                                           object:nil];

        // Button
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
        cancel.frame = CGRectMake(10, 360, 260, 50);
        cancel.layer.cornerRadius = 8.0f;
        cancel.layer.masksToBounds = YES;
        cancel.layer.borderWidth = 1.0f;
        cancel.layer.borderColor = [UIColor colorWithWhite:0.15 alpha:1.0].CGColor;

        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        cancel.titleLabel.font = [UIFont boldSystemFontOfSize:10.0f];
        cancel.titleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.6];
        cancel.titleLabel.shadowOffset = CGSizeMake(0, -1);

        // iOS 6 style dark gradient
        CAGradientLayer *bg = [CAGradientLayer layer];
        bg.frame = cancel.bounds;
        bg.colors = @[
            (id)[UIColor colorWithRed:0.662 green:0.686 blue:0.749 alpha:1.0].CGColor, // top
            (id)[UIColor colorWithRed:0.404 green:0.443 blue:0.553 alpha:1.0].CGColor  // bottom
        ];
        bg.locations = @[@0.0, @1.0];
        [cancel.layer insertSublayer:bg atIndex:0];

        // Gloss highlight (top half)
        CAGradientLayer *gloss = [CAGradientLayer layer];
        gloss.frame = CGRectMake(0, 0, cancel.bounds.size.width, cancel.bounds.size.height * 0.5);
        gloss.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.30].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.05].CGColor
        ];
        gloss.locations = @[@0.0, @1.0];
        [cancel.layer insertSublayer:gloss above:bg];

        [cancel addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self.panel addSubview:cancel];
    }
    return self;
}

- (void)cookiesChanged:(NSNotification *)notification {
    NSURL *authorizationURL = [NSURL URLWithString:@"https://accounts.youtube.com/accounts/SetSID"];
    NSLog(@"authorization URL: %@", authorizationURL);
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:authorizationURL];

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

    YTAccountAuthenticator *auth = [%c(YTAccountAuthenticator) sharedAuthenticator];
    [auth setAccount:@"AzureDiamond"];
    [auth setPassword:@"hunter2"];
    [auth setAccountToken:@"GoogleLogin auth=tokenz"];
    [auth setAccountTokenDate:[NSDate date]];
    [auth setAccountYouTubeName:@"AzureDiamond"];
    [auth _postNewAccountTokenAvailable];

    if (sid && hsid && ssid && sapisid) {
        NSLog(@"SID: %@", [sid value]);
        NSLog(@"HSID: %@", [hsid value]);
        NSLog(@"SSID: %@", [hsid value]);
        NSLog(@"SAPISID: %@", [sapisid value]);

        // we have all da account info now.
        NSString *htmlString = @"<html><body><p>Please wait...</p></body></html>";
        [self.web loadHTMLString:htmlString baseURL:nil];

        
        
    }
    // return result;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];

    self.alpha = 0.0;
    self.panel.transform = CGAffineTransformMakeScale(1.2, 1.2);

    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
        self.panel.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismiss {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end


@interface UIAlertView (Private)
- (UITextField *)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
@end

%hook YTAuthenticator

+(id)authenticationDialogWithTarget:(id)target action:(SEL)action
{




    YTCustomAlert *alert = [[[YTCustomAlert alloc] init] autorelease];

    // purge cookies
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([cookie.domain rangeOfString:@"accounts.google.com"].location != NSNotFound) {
            [cookieStorage deleteCookie:cookie];
        }
    }

    NSURL *url = [NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/supported_browsers&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"];
    [alert.web loadRequest:[NSURLRequest requestWithURL:url]];

    [alert show];

    return nil;
}

%end


// @interface UIAlertView (Private)
// - (UITextField *)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
// @end

// %hook YTAuthenticator

// +(id)authenticationDialogWithTarget:(id)target action:(SEL)action
// {
//     UIAlertView *alertBox = [[UIAlertView alloc] initWithTitle:@"YouTube Password"
//                 message:nil
//                 delegate:target
//                 cancelButtonTitle:@"Cancel"
//                 otherButtonTitles:nil];

//     UIWebView *web = [[UIWebView alloc] initWithFrame:CGRectZero];
//     web.tag = 1337;

//     NSURL *url = [NSURL URLWithString:@"https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://www.youtube.com/supported_browsers&app=m&hl=en&next=%2F&hl=en&flowName=WebLiteSignIn"];
//     NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
//     [web loadRequest:urlRequest];

//     [alertBox addSubview:web];

//     return [alertBox autorelease];
// }

// %end

// %hook UIAlertView

// // i vibecoded this im sorry >_<
// - (void)layoutSubviews {
//     %orig;

//     UIWebView *web = (UIWebView *)[self viewWithTag:1337];
//     if (!web) return;

//     CGFloat padding = 10.0;
//     CGFloat webHeight = 360.0;

//     // Expand alert
//     CGRect frame = self.frame;
//     frame.size.height += webHeight + 35.0;
//     self.frame = frame;

//     // Find last label (title/message)
//     UIView *lastLabel = nil;
//     for (UIView *view in self.subviews) {
//         if ([view isKindOfClass:[UILabel class]]) {
//             lastLabel = view;
//         }
//     }

//     CGFloat y = lastLabel ? CGRectGetMaxY(lastLabel.frame) + 10 : 50;

//     // Position webview
//     CGFloat usableWidth = self.bounds.size.width - 20.0;
//     web.frame = CGRectMake(
//         padding,
//         y,
//         usableWidth,
//         webHeight
//     );

//     web.scrollView.bounces = NO;

//     // Push buttons down
//     for (UIView *view in self.subviews) {
//         if ([view isKindOfClass:NSClassFromString(@"UIButton")]) {
//             CGRect vFrame = view.frame;
//             if (vFrame.origin.y > y) {
//                 vFrame.origin.y += webHeight;
//                 view.frame = vFrame;
//             }
//         }
//     }
// }

// %end
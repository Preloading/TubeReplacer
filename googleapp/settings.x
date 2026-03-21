#import <Foundation/Foundation.h>
#import "appheaders.h"
#import "general.h"

@interface YTSettingsViewController : YTBaseViewController_iPhone

+ (id)openSourceLicensesURL;
+ (id)privacyPolicyURL;
+ (id)termsOfServiceURL;
+ (id)helpURL;
- (void)dismissModalViewControllerWithAnimation;
- (id)reuseableCellForTableView:(id)fp8;
- (id)youtubeCellForRow:(int)fp8;
- (id)aboutCellForRow:(int)fp8;
- (id)getSafeSearchString:(int)fp8;
- (id)getHomeFeedContentString:(int)fp8;
- (void)showWebViewWithURL:(id)fp8;
- (void)presentModalViewController:(id)fp8;
- (void)tableView:(id)fp8 didSelectRowAtIndexPath:(id)fp12;
- (int)tableView:(id)fp8 numberOfRowsInSection:(int)fp12;
- (float)tableView:(id)fp8 heightForFooterInSection:(int)fp12;
- (float)tableView:(id)fp8 heightForHeaderInSection:(int)fp12;
- (id)tableView:(id)fp8 viewForHeaderInSection:(int)fp12;
- (int)numberOfSectionsInTableView:(id)fp8;
- (id)tableView:(id)fp8 cellForRowAtIndexPath:(id)fp12;
- (void)showSendFeedbackPopup;
- (void)didSelectItemAtIndex:(id)fp8 inPicker:(id)fp12;
- (void)dealloc;
- (id)initWithServices:(id)fp8 navigation:(id)fp12;

@end


@interface YTSettingsPickerViewController : YTContainerViewController <UITableViewDataSource, UITableViewDelegate>
- (void)tableView:(id)fp8 didSelectRowAtIndexPath:(id)fp12;
- (int)tableView:(id)fp8 numberOfRowsInSection:(int)fp12;
- (int)numberOfSectionsInTableView:(id)fp8;
- (id)tableView:(id)fp8 cellForRowAtIndexPath:(id)fp12;
- (void)setChoiceTarget:(id)fp8 action:(SEL)fp12;
- (void)dealloc;
- (id)init;
- (id)initWithResourceLoader:(id)fp8 title:(id)fp12 items:(id)fp16 selectedItemIndex:(unsigned int)fp20;

@end

@interface UIColor (YouTube)
+(id)backgroundDarkColor;
@end

@interface GIPWebViewController : NSObject
+ (BOOL)URLValidForSafari:(id)fp8;
- (void)setClearHistoryOnLoad:(BOOL)fp8;
- (BOOL)clearHistoryOnLoad;
- (id)toolbarColor;
- (void)setTimeoutInterval:(double)fp8;
- (double)timeoutInterval;
- (void)setCachePolicy:(unsigned int)fp8;
- (unsigned int)cachePolicy;
- (BOOL)webViewLoaded;
- (void)setWebView:(id)fp8;
- (id)webView;
- (void)setUsePageTitleAsViewTitle:(BOOL)fp8;
- (BOOL)usePageTitleAsViewTitle;
- (void)setToolbar:(id)fp8;
- (id)toolbar;
- (void)setShowsOpenInSafariInToolbar:(BOOL)fp8;
- (BOOL)showsOpenInSafariInToolbar;
- (BOOL)showsToolbar;
- (void)setShowsSpinner:(BOOL)fp8;
- (BOOL)showsSpinner;
- (void)setShowSpinnerInToolbar:(BOOL)fp8;
- (BOOL)showSpinnerInToolbar;
- (void)setAllowBrowserSelection:(BOOL)fp8;
- (BOOL)allowBrowserSelection;
- (void)setShowPromptWhenOpeningSafari:(BOOL)fp8;
- (BOOL)showPromptWhenOpeningSafari;
- (void)setShowErrorPageOnLoadFail:(BOOL)fp8;
- (BOOL)showErrorPageOnLoadFail;
- (void)setRewriteNewWindowLinks:(BOOL)fp8;
- (BOOL)rewriteNewWindowLinks;
- (void)setOpenInSafariURL:(id)fp8;
- (id)openInSafariURL;
- (int)numberOfItemsLoading;
- (void)setInitialRequest:(id)fp8;
- (id)initialRequest;
- (void)setHistory:(id)fp8;
- (id)history;
- (void)setHideToolbarWithoutHistory:(BOOL)fp8;
- (BOOL)hideToolbarWithoutHistory;
- (void)setDetectExternalURLs:(BOOL)fp8;
- (BOOL)detectExternalURLs;
- (id)delegate;
- (void)setCurrentURL:(id)fp8;
- (id)currentURL;
- (void)setCurrentPageTitle:(id)fp8;
- (id)currentPageTitle;
- (void)setToolbarColor:(id)fp8;
- (void)openExternalURL:(id)fp8;
- (void)alertView:(id)fp8 clickedButtonAtIndex:(int)fp12;
- (void)actionSheet:(id)fp8 clickedButtonAtIndex:(int)fp12;
- (void)showBrowserSelectionPrompt;
- (void)showOpenInSafariPrompt;
- (void)openURLInSafari:(id)fp8;
- (id)convertURLToChrome:(id)fp8;
- (BOOL)isChromeInstalled;
- (void)displayErrorMessage:(id)fp8 withReload:(BOOL)fp12;
- (void)hideSpinner;
- (void)showSpinner;
- (void)updateSpinnerFrame;
- (id)spinner;
- (void)didReceiveMemoryWarning;
- (void)didRotateFromInterfaceOrientation:(int)fp8;
- (BOOL)shouldAutorotateToInterfaceOrientation:(int)fp8;
- (void)openInSafari;
- (id)safariURL;
- (void)goForward;
- (void)goBack;
- (void)reload;
- (void)emptyPage;
- (void)callDidExhaustHistoryStack;
- (BOOL)shouldCallDidExhaustHistoryStack;
- (id)getPageTitle;
- (void)addURLToHistory:(id)fp8;
- (void)recordCurrentRequestInHistory;
- (void)webView:(id)fp8 didFailLoadWithError:(id)fp12;
- (void)webViewDidFinishLoad:(id)fp8;
- (void)webViewDidStartLoad:(id)fp8;
- (BOOL)webView:(id)fp8 shouldStartLoadWithRequest:(id)fp12 navigationType:(int)fp16;
- (void)loadRequest:(id)fp8;
- (void)loadURL:(id)fp8;
- (void)loadHTML:(id)fp8 baseURL:(id)fp12;
- (id)createWebViewIfNeeded;
- (void)showsOpenInSafariInToolbar:(BOOL)fp8;
- (void)setShowsToolbar:(BOOL)fp8;
- (void)setDelegate:(id)fp8;
- (struct CGRect)toolbarFrame;
- (struct CGRect)webViewFrame;
- (void)setWebViewFrame:(struct CGRect)fp8;
- (void)updateToolbarState;
- (void)setSafariButtonEnabled:(BOOL)fp8;
- (void)setReloadButtonEnabled:(BOOL)fp8;
- (void)setForwardButtonEnabled:(BOOL)fp8;
- (void)setBackButtonEnabled:(BOOL)fp8;
- (void)unloadToolbar;
- (void)loadToolbar;
- (void)viewDidUnload;
- (void)loadView;
- (void)dealloc;
- (id)initWithDelegate:(id)fp8 loader:(id)fp12 webViewClass:(Class)fp16 clearHistoryOnLoad:(BOOL)fp20;
- (id)initWithDelegate:(id)fp8 loader:(id)fp12 webViewClass:(Class)fp16;
- (id)initWithDelegate:(id)fp8 loader:(id)fp12;
- (id)initWithDelegate:(id)fp8;
- (id)init;

@end

@interface YTSettingsTableControllerDelegate
-(void)presentViewController:(id)fp8;
@end


%hook YTSettingsViewController
// -(YTSettingsViewController*) initWithServices:(YTServices*)services navigation:(YTLiveServices*)navigation {
//     YTSettingsViewController *controller = %orig;

//     [[%c(YTSettingsPickerViewController) alloc] initWithResourceLoader:[services resourceLoader] title:@"tubereplacer" items:@[@"red pill", @"blue pill"] selectedItemIndex:0];
    
//     return controller;
// }

// per the license, you are allowed are not allowed to remove this bit.
-(void)showWebViewWithURL:(id)url {
    NSURL *targetURL = [%c(YTSettingsViewController) openSourceLicensesURL];
    if (![[url standardizedURL] isEqual:[targetURL standardizedURL]]) {
        return %orig;
    }
  GIPResourceLoader *resourseLoader = [[[%c(GIPResourceLoader) alloc] initWithBundleName:@"GIPWebViewResources.bundle"] autorelease];
  GIPWebViewController *webView = [[[%c(GIPWebViewController) alloc] initWithDelegate:nil loader:resourseLoader] autorelease];
  [webView setToolbarColor:[UIColor backgroundDarkColor]];
  [webView loadURL:url];
  [self presentModalViewController:webView];
  [(UIWebView*)[webView webView] stringByEvaluatingJavaScriptFromString:
   @"window.addEventListener('load', function () {"
    "document.body.insertAdjacentHTML('afterbegin', '<h3>TubeReplacer Specific</h3><pre>"
    "TubeReplacer<br>"
    "Copyright (C) 2026 Preloading<br><br>"
    "This program is free software: you can redistribute it and/or modify "
    "it under the terms of the GNU General Public License as published by "
    "the Free Software Foundation, either version 3 of the License, or "
    "(at your option) any later version.<br><br>"

    "This program is distributed in the hope that it will be useful,"
    " but WITHOUT ANY WARRANTY; without even the implied warranty of"
    "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
    "GNU General Public License for more details.<br><br>"

    "You should have received a copy of the GNU General Public License "
    "along with this program.  If not, see <a href=\"https://www.gnu.org/licenses/\">https://www.gnu.org/licenses/</a>.<br><br>"
    "A copy of this program\\'s source can be found at <a href=\"https://github.com/Preloading/TubeReplacer\">https://github.com/Preloading/TubeReplacer</a>"
  "</pre>"
  "<p><a href=\"https://github.com/nicklockwood/Base64\">Base64</a></p><pre>"
  "Version 1.0<br><br>"
  "Created by Nick Lockwood on 12/01/2012.<br>"
  "Copyright (C) 2012 Charcoal Design<br><br>"

  "Distributed under the permissive zlib License<br>"
  "Get the latest version from here: <a href=\"https://github.com/nicklockwood/Base64\">https://github.com/nicklockwood/Base64</a><br><br>"

  "This software is provided \\'as-is\\', without any express or implied"
  "warranty.  In no event will the authors be held liable for any damages"
  "arising from the use of this software."
  "Permission is granted to anyone to use this software for any purpose,"
  "including commercial applications, and to alter it and redistribute it"
  "freely, subject to the following restrictions:<br>"
  "1. The origin of this software must not be misrepresented; you must not"
  "claim that you wrote the original software. If you use this software"
  "in a product, an acknowledgment in the product documentation would be"
  "appreciated but is not required.<br><br>"
  "2. Altered source versions must be plainly marked as such, and must not be"
  "misrepresented as being the original software.<br>"
  "3. This notice may not be removed or altered from any source distribution."
  "</pre>"
  "');"
  "})"
  ];

}

%end

%hook YTSettingsTableController
// per the license, you are allowed are not allowed to remove this bit.
-(void)showWebViewWithURL:(id)url {
    NSURL *targetURL = [%c(YTSettingsTableController) openSourceLicensesURL];
    if (![[url standardizedURL] isEqual:[targetURL standardizedURL]]) {
        return %orig;
    }
  GIPResourceLoader *resourseLoader = [[[%c(GIPResourceLoader) alloc] initWithBundleName:@"GIPWebViewResources.bundle"] autorelease];
  GIPWebViewController *webView = [[[%c(GIPWebViewController) alloc] initWithDelegate:nil loader:resourseLoader] autorelease];
  [webView setToolbarColor:[UIColor backgroundDarkColor]];
  [webView loadURL:url];
  // [self presentModalViewController:webView];
  [(YTSettingsTableControllerDelegate*)[self valueForKey:l(@"delegate")] presentViewController:webView];
  [(UIWebView*)[webView webView] stringByEvaluatingJavaScriptFromString: // todo: make this text easier to manage
   @"window.addEventListener('load', function () {"
    "document.body.insertAdjacentHTML('afterbegin', '<h3>TubeReplacer Specific</h3><pre>"
    "TubeReplacer<br>"
    "Copyright (C) 2026 Preloading<br><br>"
    "This program is free software: you can redistribute it and/or modify "
    "it under the terms of the GNU General Public License as published by "
    "the Free Software Foundation, either version 3 of the License, or "
    "(at your option) any later version.<br><br>"

    "This program is distributed in the hope that it will be useful,"
    " but WITHOUT ANY WARRANTY; without even the implied warranty of"
    "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
    "GNU General Public License for more details.<br><br>"

    "You should have received a copy of the GNU General Public License "
    "along with this program.  If not, see <a href=\"https://www.gnu.org/licenses/\">https://www.gnu.org/licenses/</a>.<br><br>"
    "A copy of this program\\'s source can be found at <a href=\"https://github.com/Preloading/TubeReplacer\">https://github.com/Preloading/TubeReplacer</a>"
  "</pre>"
  "<p><a href=\"https://github.com/nicklockwood/Base64\">Base64</a></p><pre>"
  "Version 1.0<br><br>"
  "Created by Nick Lockwood on 12/01/2012.<br>"
  "Copyright (C) 2012 Charcoal Design<br><br>"

  "Distributed under the permissive zlib License<br>"
  "Get the latest version from here: <a href=\"https://github.com/nicklockwood/Base64\">https://github.com/nicklockwood/Base64</a><br><br>"

  "This software is provided \\'as-is\\', without any express or implied"
  "warranty.  In no event will the authors be held liable for any damages"
  "arising from the use of this software."
  "Permission is granted to anyone to use this software for any purpose,"
  "including commercial applications, and to alter it and redistribute it"
  "freely, subject to the following restrictions:<br>"
  "1. The origin of this software must not be misrepresented; you must not"
  "claim that you wrote the original software. If you use this software"
  "in a product, an acknowledgment in the product documentation would be"
  "appreciated but is not required.<br><br>"
  "2. Altered source versions must be plainly marked as such, and must not be"
  "misrepresented as being the original software.<br>"
  "3. This notice may not be removed or altered from any source distribution."
  "</pre>"
  "');"
  "})"
  ];

}

%end
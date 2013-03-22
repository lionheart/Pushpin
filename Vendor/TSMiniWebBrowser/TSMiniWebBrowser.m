//
//  TSMiniWebBrowser.m
//  TSMiniWebBrowserDemo
//
//  Created by Toni Sala Echaurren on 18/01/12.
//  Copyright 2012 Toni Sala. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TSMiniWebBrowser.h"
#import "AppDelegate.h"
#import "RDActionSheet.h"

@implementation TSMiniWebBrowser

@synthesize delegate;
@synthesize mode;
@synthesize showURLStringOnActionSheetTitle;
@synthesize showPageTitleOnTitleBar;
@synthesize showReloadButton;
@synthesize showActionButton;
@synthesize barStyle;
@synthesize modalDismissButtonTitle;
@synthesize numLoads;

#define kToolBarHeight  44
#define kTabBarHeight   49

#pragma mark - Private Methods

-(void)setTitleBarText:(NSString*)pageTitle {
    if (mode == TSMiniWebBrowserModeModal) {
        navigationBarModal.topItem.title = pageTitle;
        
    } else if(mode == TSMiniWebBrowserModeNavigation) {
        if(pageTitle) [[self navigationItem] setTitle:pageTitle];
    }
}

-(void) toggleBackForwardButtons {
    buttonGoBack.enabled = webView.canGoBack;
    buttonGoForward.enabled = webView.canGoForward;
}

-(void)showActivityIndicators {
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    self.numLoads++;
}

-(void)hideActivityIndicators {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    self.numLoads--;
}

-(void) dismissController {
    if ( webView.loading ) {
        [webView stopLoading];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Notify the delegate
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(tsMiniWebBrowserDidDismiss)]) {
        [delegate tsMiniWebBrowserDidDismiss];
    }
}

//Added in the dealloc method to remove the webview delegate, because if you use this in a navigation controller
//TSMiniWebBrowser can get deallocated while the page is still loading and the web view will call its delegate-- resulting in a crash
-(void)dealloc
{
    [webView setDelegate:nil];
}

#pragma mark - Init

-(void) initToolBar {
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 30;
    
    UIButton *forwardButton = [[UIButton alloc] init];
    [forwardButton setImage:[UIImage imageNamed:@"forward_icon"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    forwardButton.frame = CGRectMake(0, 0, 30, 30);
    buttonGoForward = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    buttonGoForward.action = @selector(forwardButtonTouchUp:);
    buttonGoForward.target = self;
    
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 30, 30);
    buttonGoBack = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIButton *reloadButton = [[UIButton alloc] init];
    [reloadButton setImage:[UIImage imageNamed:@"reload_icon"] forState:UIControlStateNormal];
    [reloadButton addTarget:self action:@selector(reloadButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    reloadButton.frame = CGRectMake(0, 0, 30, 30);
    buttonReload = [[UIBarButtonItem alloc] initWithCustomView:reloadButton];
    buttonReload.enabled = NO;
    
    UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace2.width = 20;
    
    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton setImage:[UIImage imageNamed:@"UIButtonBarAction"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(buttonActionTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *buttonAction = [[UIBarButtonItem alloc] initWithCustomView:actionButton];

    // Activity indicator is a bit special
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(11, 7, 20, 20);
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 43, 33)];
    [containerView addSubview:activityIndicator];
    UIBarButtonItem *buttonContainer = [[UIBarButtonItem alloc] initWithCustomView:containerView];
    
    // Add butons to an array
    NSMutableArray *toolBarButtons = [[NSMutableArray alloc] init];
    [toolBarButtons addObject:buttonGoBack];
    [toolBarButtons addObject:fixedSpace];
    [toolBarButtons addObject:buttonGoForward];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonContainer];
    if (showReloadButton) { 
        [toolBarButtons addObject:buttonReload];
    }
    if (showActionButton) {
        [toolBarButtons addObject:fixedSpace2];
        [toolBarButtons addObject:buttonAction];
    }
    
    // Set buttons to tool bar
    [toolBar setItems:toolBarButtons animated:YES];
}

-(void) initWebView {
    CGSize viewSize = self.view.frame.size;
    if (mode == TSMiniWebBrowserModeModal) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight, viewSize.width, viewSize.height-kToolBarHeight*2)];
    } else if(mode == TSMiniWebBrowserModeNavigation) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, viewSize.width, viewSize.height-kToolBarHeight)];
    } else if(mode == TSMiniWebBrowserModeTabBar) {
        self.view.backgroundColor = [UIColor redColor];
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight-1, viewSize.width, viewSize.height-kToolBarHeight+1)];
    }
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:webView];
    
    webView.scalesPageToFit = YES;
    
    webView.delegate = self;
    
    // Load the URL in the webView
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:urlToLoad];
    [webView loadRequest:requestObj];
}

#pragma mark -

- (id)initWithUrl:(NSURL*)url {
    self = [self init];
    if(self)
    {
        urlToLoad = url;
        
        // Defaults
        mode = TSMiniWebBrowserModeNavigation;
        showURLStringOnActionSheetTitle = YES;
        showPageTitleOnTitleBar = YES;
        showReloadButton = YES;
        showActionButton = YES;
        modalDismissButtonTitle = NSLocalizedString(@"Done", nil);
        forcedTitleBarText = nil;
        barStyle = UIBarStyleDefault;
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Main view frame.
    if (mode == TSMiniWebBrowserModeTabBar) {
        CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height - kTabBarHeight;
        if (![UIApplication sharedApplication].statusBarHidden) {
            viewHeight -= [UIApplication sharedApplication].statusBarFrame.size.height;
        }
        self.view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    }
    
    // Init tool bar
    [self initToolBar];

    // Init web view
    [self initWebView];

    // UI state
    buttonGoBack.enabled = NO;
    buttonGoForward.enabled = NO;
    if (forcedTitleBarText != nil) {
        [self setTitleBarText:forcedTitleBarText];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.numLoads = 0;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (webView.loading) {
        [webView stopLoading];
    }
    
    while (self.numLoads > 0) {
        [self hideActivityIndicators];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/* Fix for landscape + zooming webview bug.
 * If you experience perfomance problems on old devices ratation, comment out this method.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGFloat ratioAspect = webView.bounds.size.width/webView.bounds.size.height;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            // Going to Portrait mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview 
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale/ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale/ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale/ratioAspect) animated:YES];
                }
            }
            break;
        default:
            // Going to Landscape mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview 
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale *ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale *ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale*ratioAspect) animated:YES];
                }
            }
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Sheet

- (void)showActionSheet {
    NSString *urlString = @"";
    if (showURLStringOnActionSheetTitle) {
        NSURL* url = [webView.request URL];
        urlString = [url absoluteString];
    }
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ohttp://"]]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Opera", nil)];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dolphin://"]]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Dolphin", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cyber://"]]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Cyberspace", nil)];
    }

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
    [actionSheet showFrom:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSURL *theURL = [webView.request URL];
    NSURL *url;
    if (theURL == nil || [theURL isEqual:[NSURL URLWithString:@""]]) {
        theURL = urlToLoad;
    }
    NSString *urlString = [theURL absoluteString];
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        return;
    }
    else if ([title isEqualToString:NSLocalizedString(@"Open in Safari", nil)]) {
        [[UIApplication sharedApplication] openURL:theURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Open in Chrome", nil)]) {
        url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:[urlString rangeOfString:@"http"] withString:@"googlechrome"]];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Open in Opera", nil)]) {
        url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:[urlString rangeOfString:@"http"] withString:@"ohttp"]];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Open in Dolphin", nil)]) {
        url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:[urlString rangeOfString:theURL.scheme] withString:@"dolphin"]];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Open in Cyberspace", nil)]) {
        url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:[urlString rangeOfString:@"http"] withString:@"cyber"]];
    }

    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Actions

- (void)backButtonTouchUp:(id)sender {
    [webView goBack];
    
    [self toggleBackForwardButtons];
}

- (void)forwardButtonTouchUp:(id)sender {
    [webView goForward];
    
    [self toggleBackForwardButtons];
}

- (void)reloadButtonTouchUp:(id)sender {
    [webView reload];
    buttonReload.enabled = NO;
    [self toggleBackForwardButtons];
}

- (void)buttonActionTouchUp:(id)sender {
    [self showActionSheet];
}

#pragma mark - Public Methods

- (void)setFixedTitleBarText:(NSString*)newTitleBarText {
    forcedTitleBarText = newTitleBarText;
    showPageTitleOnTitleBar = NO;
}

- (void)loadURL:(NSURL*)url {
    [webView loadRequest: [NSURLRequest requestWithURL: url]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] hasPrefix:@"sms:"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    if ([[request.URL absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
        [[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
        [[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self toggleBackForwardButtons];
    [self showActivityIndicators];
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView {
    // Show page title on title bar?
    if (showPageTitleOnTitleBar) {
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [self setTitleBarText:pageTitle];
    }

    buttonReload.enabled = YES;
    [self hideActivityIndicators];
    [self toggleBackForwardButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self hideActivityIndicators];
    
    // To avoid getting an error alert when you click on a link
    // before a request has finished loading.
    if ([error code] == NSURLErrorCancelled) {
        return;
    }

    // Show error alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not load page", nil)
                                                    message:error.localizedDescription
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
	[alert show];
}

@end

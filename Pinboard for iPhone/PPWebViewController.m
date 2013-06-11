//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <MessageUI/MessageUI.h>
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>

#import "PPWebViewController.h"
#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "NSString+URLEncoding2.h"
#import "KeychainItemWrapper.h"
#import "OAuthConsumer.h"
#import "PocketAPI.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.stopped = NO;
    

    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - kToolbarHeight - self.navigationController.navigationBar.frame.size.height)];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = CGRectMake(0, 0, 40, 40);
    layer.cornerRadius = 20;
    layer.masksToBounds = YES;
    layer.borderWidth = 0.8;
    layer.borderColor = HEX(0x4C586AFF).CGColor;
    layer.colors = @[(id)HEX(0xFDFDFDFF).CGColor, (id)HEX(0xCED4E0FF).CGColor];

    CALayer *enterReaderModeImageLayer = [CALayer layer];
    enterReaderModeImageLayer.frame = CGRectMake(10, 10, 20, 20);
    enterReaderModeImageLayer.contents = (id)[UIImage imageNamed:@"expand-dash"].CGImage;
    
    CALayer *exitReaderModeImageLayer = [CALayer layer];
    exitReaderModeImageLayer.frame = CGRectMake(10, 10, 20, 20);
    exitReaderModeImageLayer.contents = (id)[UIImage imageNamed:@"compress-dash"].CGImage;

    [layer addSublayer:enterReaderModeImageLayer];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [layer renderInContext:context];
    UIImage *buttonBackground = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:3 topCapHeight:15];
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    context = UIGraphicsGetCurrentContext();
    layer.colors = @[(id)HEX(0xCED4E0FF).CGColor, (id)HEX(0xFDFDFDFF).CGColor];
    [layer renderInContext:context];
    UIImage *buttonBackgroundHighlighted = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:3 topCapHeight:15];
    UIGraphicsEndImageContext();
    
    [enterReaderModeImageLayer removeFromSuperlayer];
    [layer addSublayer:exitReaderModeImageLayer];

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    context = UIGraphicsGetCurrentContext();
    [layer renderInContext:context];
    UIImage *exitReaderModeButtonBackgroundHighlighted = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:3 topCapHeight:15];
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    context = UIGraphicsGetCurrentContext();
    layer.colors = @[(id)HEX(0xFDFDFDFF).CGColor, (id)HEX(0xCED4E0FF).CGColor];
    [layer renderInContext:context];
    UIImage *exitReaderModeButtonBackground = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:3 topCapHeight:15];
    UIGraphicsEndImageContext();
    
    self.enterReaderModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.enterReaderModeButton addTarget:self action:@selector(toggleFullScreen) forControlEvents:UIControlEventTouchUpInside];
    self.enterReaderModeButton.frame = CGRectMake(self.webView.bounds.size.width - 50, self.webView.bounds.size.height - 50, 40, 40);
    [self.enterReaderModeButton setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [self.enterReaderModeButton setBackgroundImage:buttonBackgroundHighlighted forState:UIControlStateHighlighted];

    self.exitReaderModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.exitReaderModeButton addTarget:self action:@selector(toggleFullScreen) forControlEvents:UIControlEventTouchUpInside];
    self.exitReaderModeButton.frame = CGRectMake(self.webView.bounds.size.width - 50, self.webView.bounds.size.height - 50, 40, 40);
    [self.exitReaderModeButton setBackgroundImage:exitReaderModeButtonBackground forState:UIControlStateNormal];
    [self.exitReaderModeButton setBackgroundImage:exitReaderModeButtonBackgroundHighlighted forState:UIControlStateHighlighted];
    self.exitReaderModeButton.hidden = YES;

    self.panGestureRecognizerForNormalMode = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.panGestureRecognizerForNormalMode.minimumNumberOfTouches = 1;
    self.panGestureRecognizerForNormalMode.maximumNumberOfTouches = 1;

    self.panGestureRecognizerForReaderMode = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.panGestureRecognizerForReaderMode.minimumNumberOfTouches = 1;
    self.panGestureRecognizerForReaderMode.maximumNumberOfTouches = 1;
    [self.exitReaderModeButton addGestureRecognizer:self.panGestureRecognizerForReaderMode];
    [self.enterReaderModeButton addGestureRecognizer:self.panGestureRecognizerForNormalMode];

    [self.webView addSubview:self.enterReaderModeButton];
    [self.webView addSubview:self.exitReaderModeButton];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator startAnimating];
    self.activityIndicator.frame = CGRectMake(0, 0, 30, 30);
    self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    self.toolbar = [[PPToolbar alloc] init];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"back-dash"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 30, 30);
    self.backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.backBarButtonItem.enabled = NO;

    UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [forwardButton setImage:[UIImage imageNamed:@"forward-dash"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    forwardButton.frame = CGRectMake(0, 0, 30, 30);
    self.forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    self.forwardBarButtonItem.enabled = NO;
    
    self.readerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.readerButton addTarget:self action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
    [self.readerButton setImage:[UIImage imageNamed:@"stop-dash"] forState:UIControlStateNormal];
    self.readerButton.frame = CGRectMake(0, 0, 30, 30);
    self.readerBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.readerButton];

    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton setImage:[UIImage imageNamed:@"action-dash"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];

    UIButton *socialButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [socialButton setImage:[UIImage imageNamed:@"share2-dash"] forState:UIControlStateNormal];
    [socialButton addTarget:self action:@selector(socialActionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    socialButton.frame = CGRectMake(0, 0, 30, 30);
    self.socialBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:socialButton];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbar.items = @[self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, self.readerBarButtonItem, flexibleSpace, self.socialBarButtonItem, flexibleSpace, self.actionBarButtonItem];
    self.toolbar.frame = CGRectMake(0, size.height - kToolbarHeight, size.width, kToolbarHeight);
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.toolbar];
}

- (CGPoint)adjustedPuckPositionWithPoint:(CGPoint)point {
    CGFloat x;
    CGFloat y;
    if (point.y > self.webView.bounds.size.height / 2) {
        y = self.webView.bounds.size.height - 50;
    }
    else {
        y = 10;
    }
    
    if (point.x > self.webView.bounds.size.width / 2) {
        x = self.webView.bounds.size.width - 50;
    }
    else {
        x = 10;
    }
    return CGPointMake(x, y);
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.panGestureRecognizerForReaderMode || recognizer == self.panGestureRecognizerForNormalMode) {
        CGPoint point = [recognizer locationInView:self.webView];
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            self.exitReaderModeButton.center = point;
            self.enterReaderModeButton.center = point;
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            CGPoint newPoint = [self adjustedPuckPositionWithPoint:point];
            
            [UIView animateWithDuration:0.25 animations:^{
                self.enterReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
                self.exitReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
    if (self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
    if ([UIApplication sharedApplication].statusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)stopLoading {
    self.stopped = YES;
    [self.webView stopLoading];
}

- (void)toggleFullScreen {
    UIButton *visibleButton = self.enterReaderModeButton.hidden ? self.exitReaderModeButton : self.enterReaderModeButton;

    if (self.navigationController.navigationBarHidden) {
        [UIView animateWithDuration:0.25 animations:^{
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            CGSize size = self.view.frame.size;
            self.webView.frame = CGRectMake(0, 0, size.width, size.height - kToolbarHeight);
            self.toolbar.frame = CGRectMake(0, size.height - kToolbarHeight , size.width, kToolbarHeight);

            CGPoint newPoint = [self adjustedPuckPositionWithPoint:visibleButton.frame.origin];
            self.enterReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
            self.exitReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
            self.enterReaderModeButton.hidden = NO;
            self.exitReaderModeButton.hidden = YES;
        }];
    }
    else {
        [UIView animateWithDuration:0.25 animations:^{
            CGSize size = SCREEN.bounds.size;
            self.webView.frame = CGRectMake(0, 0, size.width, size.height);
            self.toolbar.frame = CGRectMake(0, size.height, size.width, kToolbarHeight);
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

            CGPoint newPoint = [self adjustedPuckPositionWithPoint:visibleButton.frame.origin];
            self.enterReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
            self.exitReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
            self.enterReaderModeButton.hidden = YES;
            self.exitReaderModeButton.hidden = NO;
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.alreadyLoaded) {
        [self loadURL];
    }
}

- (void)loadURL {
    self.stopped = NO;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)socialActionButtonTouchUp:(id)sender {
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Twitter", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Facebook", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Messages", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Email URL", nil)];
    [actionSheet showFrom:self.navigationController.view];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.numberOfRequestsInProgress--;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.numberOfRequestsInProgress--;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];
}

- (void)enableOrDisableButtons {
    if (self.numberOfRequestsInProgress > 0) {
        self.backBarButtonItem.enabled = NO;
        self.forwardBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem;
        [self.readerButton addTarget:self action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
        [self.readerButton setImage:[UIImage imageNamed:@"stop-dash"] forState:UIControlStateNormal];
    }
    else {
        self.backBarButtonItem.enabled = self.webView.canGoBack;
        self.forwardBarButtonItem.enabled = self.webView.canGoForward;
        self.alreadyLoaded = YES;
        
        NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.title = pageTitle;

        NSString *theURLString = self.url.absoluteString;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[[self urlStringForDemobilizedURL:[NSURL URLWithString:theURLString]]]];
            [results next];
            BOOL bookmarkExists = [results intForColumnIndex:0] > 0;
            [db close];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bookmarkExists) {
                    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(showEditViewController)];
                    self.navigationItem.rightBarButtonItem = editBarButtonItem;
                }
                else {
                    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(showAddViewController)];
                    self.navigationItem.rightBarButtonItem = addBarButtonItem;
                }
                
                if (self.stopped) {
                    [self.readerButton addTarget:self action:@selector(loadURL) forControlEvents:UIControlEventTouchUpInside];
                    [self.readerButton setImage:[UIImage imageNamed:@"reload-dash"] forState:UIControlStateNormal];
                }
                else {
                    [self.readerButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
                    if (self.isMobilized) {
                        [self.readerButton setImage:[UIImage imageNamed:@"globe-dash"] forState:UIControlStateNormal];
                    }
                    else {
                        [self.readerButton setImage:[UIImage imageNamed:@"paper-dash"] forState:UIControlStateNormal];
                    }
                }
            });
        });
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.numberOfRequestsInProgress++;
    self.title = @"Loading...";
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [self enableOrDisableButtons];
}

- (void)backButtonTouchUp:(id)sender {
    [self.webView goBack];
}

- (void)forwardButtonTouchUp:(id)sender {
    [self.webView goForward];
}

- (void)actionButtonTouchUp:(id)sender {
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
        case BROWSER_SAFARI:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
            break;
            
        case BROWSER_OPERA:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Opera", nil)];
            break;
            
        case BROWSER_ICAB_MOBILE:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in iCab Mobile", nil)];
            break;
            
        case BROWSER_DOLPHIN:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Dolphin", nil)];
            break;
            
        case BROWSER_CYBERSPACE:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Cyberspace", nil)];
            break;
            
        case BROWSER_CHROME:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
            break;
            
        default:
            break;
    }
    
    NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
    if (readlater == READLATER_INSTAPAPER) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
    }
    else if (readlater == READLATER_READABILITY) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
    }
    else if (readlater == READLATER_POCKET) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
    }
    
    [actionSheet showFrom:self.navigationController.view];
}

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    NSURL *url = [NSURL URLWithString:urlString];
    NSRange range = [urlString rangeOfString:url.scheme];

    if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
        [self copyURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Email URL", nil)]) {
        [self emailURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        return;
    }
    else if ([title isEqualToString:NSLocalizedString(@"Share on Twitter", nil)]) {
        SLComposeViewController *socialComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [socialComposeViewController setInitialText:self.title];
        [socialComposeViewController addURL:url];
        [self presentViewController:socialComposeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Share on Facebook", nil)]) {
        SLComposeViewController *socialComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [socialComposeViewController setInitialText:self.title];
        [socialComposeViewController addURL:url];
        [self presentViewController:socialComposeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Share on Messages", nil)]) {
        MFMessageComposeViewController *composeViewController = [[MFMessageComposeViewController alloc] init];
        composeViewController.messageComposeDelegate = self;
        [composeViewController setBody:[NSString stringWithFormat:@"%@ %@", self.title, urlString]];
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
        [self sendToReadLater];
    }
    else {
        if ([title isEqualToString:NSLocalizedString(@"Open in Chrome", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
            }
            else {
                url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
            }
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Opera", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"ohttp"]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Dolphin", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"dolphin"]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Cyberspace", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"cyber"]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in iCab Mobile", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"icabmobile"]];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)sendToReadLater {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/bookmarks/add"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        NSMutableArray *parameters = [[NSMutableArray alloc] init];
        [parameters addObject:[OARequestParameter requestParameter:@"url" value:urlString]];
        [parameters addObject:[OARequestParameter requestParameter:@"description" value:@"Sent from Pushpin"]];
        [request setParameters:parameters];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   if (httpResponse.statusCode == 200) {
                                       notification.alertBody = NSLocalizedString(@"Sent to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                   }
                                   else if (httpResponse.statusCode == 1221) {
                                       notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[[OARequestParameter requestParameter:@"url" value:urlString]]];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   if (httpResponse.statusCode == 202) {
                                       notification.alertBody = @"Sent to Readability.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                   }
                                   else if (httpResponse.statusCode == 409) {
                                       notification.alertBody = @"Link already sent to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = @"Error sending to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_POCKET) {
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:urlString]
                             withTitle:self.title
                               handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                   if (!error) {
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertBody = @"Sent to Pocket.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                       
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                   }
                               }];
    }
}

- (NSString *)urlStringForDemobilizedURL:(NSURL *)url {
    if ([self isURLStringMobilized:url.absoluteString]) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                return [url.absoluteString substringFromIndex:57];
                break;
                
            case MOBILIZER_INSTAPAPER:
                return [url.absoluteString substringFromIndex:30];
                break;
                
            case MOBILIZER_READABILITY:
                return [url.absoluteString substringFromIndex:33];
                break;
        }
    }
    return url.absoluteString;
}

- (void)toggleMobilizer {
    NSURL *url;
    if (self.isMobilized) {
        [AppDelegate sharedDelegate].openLinksWithMobilizer = NO;
        url = [NSURL URLWithString:[self urlStringForDemobilizedURL:self.url]];
    }
    else {
        [AppDelegate sharedDelegate].openLinksWithMobilizer = YES;
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", self.url.absoluteString]];
                break;
                
            case MOBILIZER_INSTAPAPER:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.instapaper.com/m?u=%@", self.url.absoluteString]];
                break;
                
            case MOBILIZER_READABILITY:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.url.absoluteString]];
                break;
        }
    }
    self.stopped = NO;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)emailURL {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setMessageBody:[self urlStringForDemobilizedURL:self.url] isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self urlStringForDemobilizedURL:self.url]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSURL *)url {
    NSURL *url = [self.webView.request URL];
    if (!url || [url class] != [NSURL class] || [url.absoluteString isEqualToString:@""]) {
        return [NSURL URLWithString:self.urlString];
    }
    return url;
}

- (void)showAddViewController {
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSDictionary *post = @{
        @"title": pageTitle,
        @"url": [self urlStringForDemobilizedURL:self.url]
    };

    UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(NO) delegate:self callback:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        #warning XXX - make generic
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[[self urlStringForDemobilizedURL:self.url]]];
        [results next];
        NSDictionary *post = @{
            @"title": [results stringForColumn:@"title"],
            @"description": [results stringForColumn:@"description"],
            @"unread": @([results boolForColumn:@"unread"]),
            @"url": [results stringForColumn:@"url"],
            @"private": @([results boolForColumn:@"private"]),
            @"tags": [results stringForColumn:@"tags"],
            @"created_at": [results dateForColumn:@"created_at"],
            @"starred": @([results boolForColumn:@"starred"])
        };
        [db close];

        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) delegate:self callback:nil];
            [self presentViewController:vc animated:YES completion:nil];
        });
    });
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isMobilized {
    return [self isURLStringMobilized:self.url.absoluteString];
}

- (BOOL)isURLStringMobilized:(NSString *)url {
    BOOL googleMobilized = [url hasPrefix:@"http://www.google.com/gwt/x"];
    BOOL readabilityMobilized = [url hasPrefix:@"http://www.readability.com/m?url="];
    BOOL instapaperMobilized = [url hasPrefix:@"http://www.instapaper.com/m?u="];
    return googleMobilized || readabilityMobilized || instapaperMobilized;
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    NSString *urlString;
    if (![webViewController isURLStringMobilized:url]) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                urlString = [NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", url];
                break;
                
            case MOBILIZER_INSTAPAPER:
                urlString = [NSString stringWithFormat:@"http://www.instapaper.com/m?u=%@", url];
                break;
                
            case MOBILIZER_READABILITY:
                urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", url];
                break;
                
            default:
                break;
        }
    }
    else {
        urlString = url;
    }

    webViewController.urlString = urlString;
    return webViewController;
}

@end

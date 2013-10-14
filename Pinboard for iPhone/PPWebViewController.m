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
#import <Twitter/Twitter.h>

#import "PPWebViewController.h"
#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "NSString+URLEncoding2.h"
#import "KeychainItemWrapper.h"
#import "OAuthConsumer.h"
#import "PocketAPI.h"
#import "UIApplication+AppDimensions.h"
#import "UIApplication+Additions.h"
#import <UIView+LHSAdditions.h>

#import "PPNavigationController.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

@synthesize shouldMobilize, urlString;
@synthesize tapViewBottom, tapViewTop;

- (void)viewDidLayoutSubviews {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.stopped = NO;
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.webView.autoresizingMask = UIViewAutoresizingNone;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.bounces = NO;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.progress = 0;
    self.progressView.tintColor = [UIColor lightGrayColor];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressView];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.webView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view lhs_addConstraints:@"H:|[view]|" views:@{@"view": self.progressView}];
    
    // Tap views and gesture recognizers
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.tapViewTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 20)];
    [self.view addSubview:self.tapViewTop];
    self.tapViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, screen.size.height - 20, screen.size.width, 20)];
    [self.view addSubview:self.tapViewBottom];
    self.tapGestureForTopFullscreenMode = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disableFullscreen:)];
    self.tapGestureForTopFullscreenMode.numberOfTapsRequired = 1;
    self.tapGestureForTopFullscreenMode.numberOfTouchesRequired = 1;
    self.tapGestureForTopFullscreenMode.enabled = NO;
    [self.tapViewTop addGestureRecognizer:self.tapGestureForTopFullscreenMode];
    self.tapGestureForBottomFullscreenMode = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disableFullscreen:)];
    self.tapGestureForBottomFullscreenMode.numberOfTapsRequired = 1;
    self.tapGestureForBottomFullscreenMode.numberOfTouchesRequired = 1;
    self.tapGestureForBottomFullscreenMode.enabled = NO;
    [self.tapViewBottom addGestureRecognizer:self.tapGestureForBottomFullscreenMode];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityIndicator startAnimating];
    self.activityIndicator.frame = CGRectMake(0, 0, 30, 30);
    self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    self.toolbar = [[PPToolbar alloc] init];
    self.toolbar.translucent = YES;
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
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
    
    UIButton *expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [expandButton setImage:[UIImage imageNamed:@"expand-dash"] forState:UIControlStateNormal];
    [expandButton addTarget:self action:@selector(expandWebViewToFullScreen) forControlEvents:UIControlEventTouchUpInside];
    expandButton.frame = CGRectMake(0, 0, 30, 30);
    self.expandBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:expandButton];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbar.items = @[self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, self.readerBarButtonItem, flexibleSpace, self.expandBarButtonItem, flexibleSpace, self.actionBarButtonItem];
    self.toolbar.frame = CGRectMake(0, size.height - kToolbarHeight, size.width, kToolbarHeight);

    [self.view addSubview:self.toolbar];
    
    // Setup auto-layout constraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:0 metrics:nil views:@{ @"toolbar": self.toolbar }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolbar]|" options:0 metrics:@{ @"toolbarHeight": @(kToolbarHeight) } views:@{ @"webView": self.webView, @"toolbar": self.toolbar }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:@{ @"webView": self.webView }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:@{ @"webView": self.webView, @"toolbar": self.toolbar }]];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Determine if we should mobilize or not
    NSString *mobilizedUrlString;
    if (![self isURLStringMobilized:self.urlString] && self.shouldMobilize) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                mobilizedUrlString = [NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", self.urlString];
                break;
                
            case MOBILIZER_INSTAPAPER:
                mobilizedUrlString = [NSString stringWithFormat:@"http://mobilizer.instapaper.com/m?u=%@", self.urlString];
                break;
                
            case MOBILIZER_READABILITY:
                mobilizedUrlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.urlString];
                break;
                
            default:
                break;
        }
        
        self.urlString = mobilizedUrlString;
    }
    
    // Setup a content inset on the webview under the toolbar
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.toolbar.frame.size.height, 0);

    CGSize buttonSize = self.webView.frame.size;
    CGPoint newPoint = [self adjustedPuckPositionWithPoint:CGPointMake(buttonSize.width, buttonSize.height)];
    self.enterReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
    self.exitReaderModeButton.frame = CGRectMake(newPoint.x, newPoint.y, 40, 40);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.alreadyLoaded) {
        [self loadURL];
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

- (void)expandWebViewToFullScreen {
    [self setFullscreen:YES];
}

- (void)setFullscreen:(BOOL)fullscreen {
    // Just return if we're already in the desired state
    if (fullscreen == self.isFullscreen)
        return;
    
    if (fullscreen) {
        self.toolbarFrame = self.toolbar.frame;
        // Show the hidden UIView to get tap notifications
        self.tapGestureForTopFullscreenMode.enabled = YES;
        self.tapGestureForBottomFullscreenMode.enabled = YES;
        
        [self.tapViewTop setHidden:NO];
        [self.tapViewBottom setHidden:NO];
        
        // Hide the navigation and status bars
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [UIView animateWithDuration:0.25 animations:^{
            // Slide down the bottom toolbar
            self.toolbar.frame = CGRectMake(self.toolbarFrame.origin.x, self.view.frame.size.height, self.toolbarFrame.size.width, self.toolbarFrame.size.height);
            self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            
            self.isFullscreen = YES;
        }];
    } else {
        // Hide the tap view
        self.tapGestureForTopFullscreenMode.enabled = NO;
        self.tapGestureForBottomFullscreenMode.enabled = NO;
        [self.tapViewTop setHidden:YES];
        [self.tapViewBottom setHidden:YES];
        
        // Reset the content offset
        self.webView.scrollView.contentOffset = CGPointMake(0, 0);
        
        // Reveal the navigation and status bars
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [UIView animateWithDuration:0.25 animations:^{
            // Show the bottom toolbar
            [self.toolbar setFrame:CGRectMake(self.toolbarFrame.origin.x, self.view.frame.size.height - self.toolbarFrame.size.height, self.toolbarFrame.size.width, self.toolbarFrame.size.height)];
            self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, kToolbarHeight, 0);
            
            self.isFullscreen = NO;
        }];
    }
}

- (void)disableFullscreen:(id)sender {
    CGRect frame = self.navigationController.navigationBar.frame;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + frame.origin.y + frame.size.height, 0, 0, 0);
    [self setFullscreen:NO];
}

- (void)loadURL {
    self.stopped = NO;
    
    self.title = self.urlString;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)socialActionButtonTouchUp:(id)sender {
    if (!self.actionSheet) {
        NSString *urlString = [self urlStringForDemobilizedURL:self.url];
        
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        BOOL isIOS6 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0;
        BOOL canSendTweet;
        BOOL canPostToFacebook;
        if (isIOS6) {
            canSendTweet = [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
            canPostToFacebook = [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
        }
        else {
            canSendTweet = [TWTweetComposeViewController canSendTweet];
            canPostToFacebook = NO;
        }

        if (canSendTweet) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Twitter", nil)];
        }

        if (canPostToFacebook) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Facebook", nil)];
        }

        if ([MFMessageComposeViewController canSendText]) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Messages", nil)];
        }
        
        if ([MFMailComposeViewController canSendMail]) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Email URL", nil)];
        }

        // Properly set the cancel button index
        [self.actionSheet addButtonWithTitle:@"Cancel"];
        self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;

        [(UIActionSheet *)self.actionSheet showFromBarButtonItem:self.socialBarButtonItem animated:YES];
    }
    else {
        if ([UIApplication isIPad]) {
            [(UIActionSheet *)self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
            self.actionSheet = nil;
        }
    }
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

        NSString *theURLString = [self urlStringForDemobilizedURL:self.url];

        if (theURLString) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[theURLString]];
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

                    [self.readerButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
                    if (self.isMobilized) {
                        [self.readerButton setImage:[UIImage imageNamed:@"globe-dash"] forState:UIControlStateNormal];
                    }
                    else {
                        [self.readerButton setImage:[UIImage imageNamed:@"paper-dash"] forState:UIControlStateNormal];
                    }
                });
            });
        }
    }
}

- (void)backButtonTouchUp:(id)sender {
    [self.webView goBack];
}

- (void)forwardButtonTouchUp:(id)sender {
    [self.webView goForward];
}

- (void)actionButtonTouchUp:(id)sender {
    if (!self.actionSheet) {
        NSString *alertTitle = [self urlStringForDemobilizedURL:self.url];

        self.actionSheet = [[UIActionSheet alloc] initWithTitle:alertTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
        switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
            case BROWSER_SAFARI:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
                break;
                
            case BROWSER_OPERA:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Opera", nil)];
                break;
                
            case BROWSER_ICAB_MOBILE:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in iCab Mobile", nil)];
                break;
                
            case BROWSER_DOLPHIN:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Dolphin", nil)];
                break;
                
            case BROWSER_CYBERSPACE:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Cyberspace", nil)];
                break;
                
            case BROWSER_CHROME:
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
                break;
                
            default:
                break;
        }
        
        NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
        if (readlater == READLATER_INSTAPAPER) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
        }
        else if (readlater == READLATER_READABILITY) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
        }
        else if (readlater == READLATER_POCKET) {
            [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
        }

        // Properly set the cancel button index
        [self.actionSheet addButtonWithTitle:@"Cancel"];
        self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;

        [(UIActionSheet *)self.actionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
    }
    else {
        if ([UIApplication isIPad]) {
            [(UIActionSheet *)self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
            self.actionSheet = nil;
        }
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        self.actionSheet = nil;
        NSString *urlString = [self urlStringForDemobilizedURL:self.url];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url.scheme) {
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
                BOOL isIOS6 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0;
                if (isIOS6) {
                    SLComposeViewController *socialComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                    [socialComposeViewController setInitialText:self.title];
                    [socialComposeViewController addURL:url];
                    [self presentViewController:socialComposeViewController animated:YES completion:nil];
                }
                else {
                    TWTweetComposeViewController *tweetComposeViewController = [[TWTweetComposeViewController alloc] init];
                    [tweetComposeViewController setInitialText:self.title];
                    [tweetComposeViewController addURL:url];
                    [self presentViewController:tweetComposeViewController animated:YES completion:nil];
                }
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
                return [url.absoluteString substringFromIndex:36];
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
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobilizer.instapaper.com/m?u=%@", self.url.absoluteString]];
                break;
                
            case MOBILIZER_READABILITY:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.url.absoluteString]];
                break;
        }
    }
    self.stopped = NO;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.title = self.urlString;
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

    PPNavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(NO) delegate:self callback:nil];
    
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlString = [self urlStringForDemobilizedURL:self.url];
        if (urlString) {
            #warning XXX - make generic
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[urlString]];
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
                PPNavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) delegate:self callback:nil];
                
                if ([UIApplication isIPad]) {
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                }

                [self presentViewController:vc animated:YES completion:nil];
            });
        }
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
    BOOL instapaperMobilized = [url hasPrefix:@"http://mobilizer.instapaper.com/m?u="];
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
                urlString = [NSString stringWithFormat:@"http://mobilizer.instapaper.com/m?u=%@", url];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGSize size = [UIApplication currentSize];
    self.webView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGSize size = self.view.frame.size;
    self.webView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

- (NSInteger)numberOfRequestsInProgress {
    return self.numberOfRequests - self.numberOfRequestsCompleted;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.y <= 0) {
        [self setFullscreen:NO];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.numberOfRequestsCompleted = 0;
    self.numberOfRequests = 0;
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.numberOfRequestsCompleted++;

    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.numberOfRequestsCompleted++;

    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];

    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.title = pageTitle;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.numberOfRequests++;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [self enableOrDisableButtons];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];

    [self.progressView setProgress:((CGFloat)self.data.length / self.response.expectedContentLength) animated:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.webView loadData:self.data MIMEType:self.response.MIMEType textEncodingName:self.response.textEncodingName baseURL:self.response.URL];
}

@end

//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

@import MessageUI;
@import Social;
@import QuartzCore;
@import Twitter;
@import SafariServices;

#import "PPWebViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPBrowserActivity.h"
#import "PPReadLaterActivity.h"
#import "PPNavigationController.h"
#import "PPGenericPostViewController.h"
#import "PPActivityViewController.h"
#import "PPUtilities.h"
#import "PPMobilizerUtility.h"
#import "PPSettings.h"
#import "NSData+AES256.h"

#ifdef PINBOARD
#import "PPPinboardDataSource.h"
#endif

#import <JavaScriptCore/JavaScriptCore.h>
#import <LHSCategoryCollection/NSData+Base64.h>
#import "NSString+URLEncoding2.h"
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <UIView+LHSAdditions.h>
#import <FMDB/FMDatabase.h>
#import <PocketAPI/PocketAPI.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <RNCryptor/RNDecryptor.h>
#import <RNCryptor/RNCryptor.h>

#define HIDE_STATUS_BAR_WHILE_SCROLLING NO

static NSInteger kToolbarHeight = 44;
static NSInteger kTitleHeight = 40;
static CGFloat kPPReaderViewAnimationDuration = 0.3;

@interface PPWebViewController ()

@property (nonatomic) CGFloat yOffsetToStartShowingToolbar;
@property (nonatomic) CGPoint previousContentOffset;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) PPActivityViewController *activityView;
@property (nonatomic, strong) UIKeyCommand *goBackKeyCommand;
@property (nonatomic, strong) UIWebView *readerWebView;
@property (nonatomic) BOOL mobilized;
@property (nonatomic, strong) NSMutableSet *loadedURLs;

- (void)updateInterfaceWithComputedWebPageBackgroundColor;
- (void)updateInterfaceWithComputedWebPageBackgroundColorTimedOut:(BOOL)timedOut;
- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;
- (void)markAsReadButtonTouchUpInside:(id)sender;
//- (BOOL)mobilized;
- (UIWebView *)currentWebView;

- (void)setReaderViewVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarVisible:(BOOL)visible animated:(BOOL)animated;

- (void)addTouchOverridesForWebView:(UIWebView *)webView;

@end

@implementation PPWebViewController

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)viewDidLayoutSubviews {
    self.topLayoutConstraint.constant = [self.topLayoutGuide length];
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.prefersStatusBarHidden = NO;
    self.preferredStatusBarStyle = UIStatusBarStyleDefault;
    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.history = [NSMutableArray array];
    self.loadedURLs = [NSMutableSet set];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
    
    self.bottomTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.bottomTapGestureRecognizer.numberOfTapsRequired = 1;
    
    self.webViewTimeoutTimer = [NSTimer timerWithTimeInterval:5 target:self.webView selector:@selector(stopLoading) userInfo:nil repeats:NO];
    
    self.statusBarBackgroundView = [[UIView alloc] init];
    self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
    self.statusBarBackgroundView.userInteractionEnabled = NO;
    self.statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusBarBackgroundView];

    self.webView = [[UIWebView alloc] init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, kToolbarHeight, 0);
    [self.view addSubview:self.webView];
    
    self.readerWebView = [[UIWebView alloc] init];
    self.readerWebView.backgroundColor = [UIColor whiteColor];
    self.readerWebView.delegate = self;
    self.readerWebView.alpha = 0;
    self.readerWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, kToolbarHeight, 0);
    self.readerWebView.scrollView.delegate = self;
    self.readerWebView.scrollView.scrollsToTop = NO;
    self.readerWebView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.readerWebView];
    
    self.showToolbarAndTitleBarHiddenView = [[UIView alloc] init];
    self.showToolbarAndTitleBarHiddenView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showToolbarAndTitleBarHiddenView addGestureRecognizer:self.bottomTapGestureRecognizer];
    [self.view addSubview:self.showToolbarAndTitleBarHiddenView];
    
    // Long press gesture for custom menu
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.longPressGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.longPressGestureRecognizer];

    self.readerLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.readerLongPressGestureRecognizer.delegate = self;
    [self.readerWebView addGestureRecognizer:self.readerLongPressGestureRecognizer];
    
    self.toolbar = [[UIView alloc] init];
    self.toolbar.backgroundColor = [UIColor whiteColor];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;

    self.toolbarBackgroundView = [[UIView alloc] init];
    self.toolbarBackgroundView.backgroundColor = [UIColor whiteColor];
    self.toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.toolbarBackgroundView];
    
    self.backButtonLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [self.backButtonLongPressGestureRecognizer addTarget:self action:@selector(gestureDetected:)];

    UIImage *stopButtonImage = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:stopButtonImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton addGestureRecognizer:self.backButtonLongPressGestureRecognizer];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.backButton];

    UIImage *markAsReadImage = [[UIImage imageNamed:@"mark-as-read"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.markAsReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.markAsReadButton setImage:markAsReadImage forState:UIControlStateNormal];
    [self.markAsReadButton addTarget:self action:@selector(markAsReadButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    self.markAsReadButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.markAsReadButton.enabled = NO;
    self.markAsReadButton.hidden = YES;
    [self.toolbar addSubview:self.markAsReadButton];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    [self.toolbar addSubview:self.indicator];

    UIImage *viewMobilizeButtonImage = [[UIImage imageNamed:@"mobilize"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *viewRawButtonImage = [[UIImage imageNamed:@"mobilized"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.mobilizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mobilizeButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
    [self.mobilizeButton setImage:viewMobilizeButtonImage forState:UIControlStateNormal];
    [self.mobilizeButton setImage:viewRawButtonImage forState:UIControlStateSelected];
    self.mobilizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.mobilizeButton];

    UIImage *actionButtonImage = [[UIImage imageNamed:@"share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:actionButtonImage forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.actionButton];
    
    UIImage *editButtonImage = [[UIImage imageNamed:@"edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editButton setImage:editButtonImage forState:UIControlStateNormal];
    [self.editButton addTarget:self action:@selector(showEditViewController) forControlEvents:UIControlEventTouchUpInside];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editButton.enabled = NO;
    [self.toolbar addSubview:self.editButton];
    
    UIImage *addButtonImage = [[UIImage imageNamed:@"add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addButton setImage:addButtonImage forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(showAddViewController) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.hidden = YES;
    self.addButton.enabled = NO;
    [self.toolbar addSubview:self.addButton];
    
    UIView *toolbarBorderView = [[UIView alloc] init];
    toolbarBorderView.backgroundColor = HEX(0xb2b2b2ff);
    toolbarBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:toolbarBorderView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.5;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    NSDictionary *toolbarViews = @{
        @"back": self.backButton,
        @"read": self.markAsReadButton,
        @"mobilize": self.mobilizeButton,
        @"action": self.actionButton,
        @"edit": self.editButton,
        @"add": self.addButton,
        @"background": self.toolbarBackgroundView,
        @"border": toolbarBorderView
    };

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.indicator
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.markAsReadButton
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1
                                                              constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.indicator
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.markAsReadButton
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                              constant:0]];

    [self.toolbar lhs_addConstraints:@"H:|[back][read(==back)][mobilize(==back)][edit(==back)][action(==back)]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[background]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[background(height)]" metrics:@{@"height": @(kToolbarHeight + 60)} views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[back]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[mobilize]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[action]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[edit]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[add]|" views:toolbarViews];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.addButton
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:0]];
    
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.addButton
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:0]];
    
    [self tintButtonsWithColor:[UIColor darkGrayColor]];

    [self.view addSubview:self.toolbar];
    
    NSDictionary *views = @{
        @"toolbar": self.toolbar,
        @"background": self.statusBarBackgroundView,
        @"show": self.showToolbarAndTitleBarHiddenView,
        @"webview": self.webView,
        @"reader": self.readerWebView,
        @"bottom": self.bottomLayoutGuide
    };

    // Setup auto-layout constraints
    [self.view lhs_addConstraints:@"H:|[background]|" views:views];
    [self.view lhs_addConstraints:@"H:|[toolbar]|" views:views];
    [self.view lhs_addConstraints:@"H:|[webview]|" views:views];
    [self.view lhs_addConstraints:@"H:|[reader]|" views:views];
    [self.view lhs_addConstraints:@"H:|[show]|" views:views];
    
    // Make sure the height of the reader view is the same as the web view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.readerWebView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.webView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.readerWebView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.webView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.readerWebView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.webView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
    
    NSDictionary *metrics = @{@"height": @(kToolbarHeight)};

    [self.view lhs_addConstraints:@"V:[show(height)][bottom]" metrics:metrics views:views];
    [self.view lhs_addConstraints:@"V:|[background][webview][bottom]" metrics:metrics views:views];
    [self.view lhs_addConstraints:@"V:[toolbar(>=height)]" metrics:metrics views:views];
    
    self.toolbarConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.toolbar
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:kToolbarHeight];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationLessThanOrEqual
                                                             toItem:self.toolbar
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:self.toolbarConstraint];

    self.topLayoutConstraint = [self.statusBarBackgroundView lhs_setHeight:0];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer || recognizer == self.readerLongPressGestureRecognizer) {
        UIWebView *webView = (UIWebView *)recognizer.view;

        // Get the coordinates of the selected element
        CGPoint webViewCoordinates = [recognizer locationInView:webView];
        CGSize viewSize = webView.frame.size;
        CGFloat webViewContentWidth = [[webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
        CGFloat scaleRatio = webViewContentWidth / viewSize.width;
        webViewCoordinates.x = webViewCoordinates.x * scaleRatio;
        webViewCoordinates.y = webViewCoordinates.y * scaleRatio;
        
        // We were getting multiple gesture notifications, so make sure we only process one
        if (self.selectedActionSheetIsVisible) {
            return;
        }

        // Search the DOM for the link - will just return immediately if there is an A element at our exact coordinates
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"PINBOARD_ACTIVE_ELEMENT = PINBOARD_CLOSEST_LINK_AT(%f, %f)", webViewCoordinates.x, webViewCoordinates.y]];
        NSString *locatorString = @"PINBOARD_ACTIVE_ELEMENT.nodeName";
        
        // Only process link elements any further
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.nodeName";
        if (![[webView stringByEvaluatingJavaScriptFromString:locatorString] isEqualToString:@"A"]) {
            return;
        }
        
        // Parse the link and title into an NSDictionary
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.innerText";
        NSString *title = [webView stringByEvaluatingJavaScriptFromString:locatorString];
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.href";
        NSString *url = [webView stringByEvaluatingJavaScriptFromString:locatorString];
        self.selectedLink = @{ @"url": url, @"title": title };
        
        // Show the context menu
        self.selectedActionSheet = [[UIActionSheet alloc] initWithTitle:url
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:NSLocalizedString(@"Add to Pinboard", nil), NSLocalizedString(@"Copy URL", nil), nil];
        [self setSelectedActionSheetIsVisible:YES];
        [(UIActionSheet *)self.selectedActionSheet showFromRect:self.actionButton.frame inView:self.toolbar animated:YES];
    }
    else if (recognizer == self.backButtonLongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            self.backActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

            NSRange range = NSMakeRange(MAX(0, (NSInteger)self.history.count - 5), MIN(5, self.history.count));
            NSArray *lastFiveHistoryItems = [self.history subarrayWithRange:range];
            for (NSInteger i=lastFiveHistoryItems.count - 1; i>0; i--) {
                NSDictionary *item = lastFiveHistoryItems[i];
                [self.backActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@", item[@"host"]]];
            }

            [self.backActionSheet addButtonWithTitle:@"Close Browser"];
            [self.backActionSheet addButtonWithTitle:@"Cancel"];
            self.backActionSheet.cancelButtonIndex = self.backActionSheet.numberOfButtons - 1;

            CGPoint point = [self.backButtonLongPressGestureRecognizer locationInView:self.backButton];
            if ([UIApplication isIPad]) {
                [self.backActionSheet showFromRect:(CGRect){point, {1, 1}} inView:self.backButton animated:YES];
            }
            else {
                [self.backActionSheet showInView:self.toolbar];
            }
        }
    }
    else if (recognizer == self.bottomTapGestureRecognizer) {
        UIWebView *webView = self.currentWebView;
        self.yOffsetToStartShowingToolbar = webView.scrollView.contentOffset.y;

        if (webView.scrollView.scrollsToTop && webView.scrollView.scrollEnabled) {
            [self setToolbarVisible:YES animated:YES];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
    // Determine if we should mobilize or not
    if (self.shouldMobilize && !self.mobilized && [PPMobilizerUtility canMobilizeURL:self.url]) {
        [self toggleMobilizerAnimated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (![self.loadedURLs containsObject:self.url]) {
        [self loadURL];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopLoading];
}

- (void)stopLoading {
    [self.webViewTimeoutTimer invalidate];
    [self.webView stopLoading];
    [self.readerWebView stopLoading];
}

- (void)loadURL {
    self.title = self.urlString;
    self.titleLabel.text = self.url.host;

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)enableOrDisableButtons {
    if (self.numberOfRequestsInProgress <= 0) {
        self.markAsReadButton.hidden = NO;
        [self.indicator stopAnimating];
        
        if (self.webView.scrollView.contentOffset.y == 0) {
            [self setToolbarVisible:YES animated:NO];
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __block BOOL bookmarkExists;
            __block BOOL isRead;

            [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:@"SELECT COUNT(*), unread FROM bookmark WHERE url=?" withArgumentsInArray:@[self.url.absoluteString]];
                [results next];
                bookmarkExists = [results intForColumnIndex:0] > 0;
                isRead = ![results boolForColumnIndex:1];

                [results close];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.rightBarButtonItem = nil;

                if (bookmarkExists) {
                    self.editButton.hidden = NO;
                    self.editButton.enabled = YES;
                    self.addButton.hidden = YES;
                }
                else {
                    self.editButton.hidden = YES;
                    self.addButton.hidden = NO;
                    self.addButton.enabled = YES;
                }

                self.markAsReadButton.enabled = !isRead;
            });
        });
    }
}

- (void)backButtonTouchUp:(id)sender {
    if ([self.webView canGoBack]) {
        if (self.mobilized) {
            [self setReaderViewVisible:NO animated:NO completion:nil];
        }

        [self.webView goBack];
    }
    else {
        if (!self.mobilized) {
            // Hide the reader web view.
            [self setReaderViewVisible:NO animated:NO completion:nil];
        }

        [UIView animateWithDuration:0.3
                         animations:^{
                             self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
                             [self setNeedsStatusBarAppearanceUpdate];
                         }];

        if ([self.presentingViewController respondsToSelector:@selector(setNeedsUpdate:)]) {
            [(PPGenericPostViewController *)self.presentingViewController setNeedsUpdate:YES];
        }

        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)forwardButtonTouchUp:(id)sender {
    [self.webView goForward];
}

- (void)actionButtonTouchUp:(id)sender {
    NSString *title = self.title;

    NSArray *activityItems = @[title, self.url];
    self.activityView = [[PPActivityViewController alloc] initWithActivityItems:activityItems];

    __weak PPWebViewController *weakself = self;
    self.activityView.completionHandler = ^(NSString *activityType, BOOL completed) {
        [weakself setNeedsStatusBarAppearanceUpdate];

        if (weakself.popover) {
            [weakself.popover dismissPopoverAnimated:YES];
        }
    };
    
    if ([UIApplication isIPad]) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.activityView];
        [self.popover presentPopoverFromRect:self.actionButton.frame
                                      inView:self.toolbar
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];
    }
    else {
        [self presentViewController:self.activityView animated:YES completion:nil];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.selectedActionSheet) {
        [self setSelectedActionSheetIsVisible:NO];
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
            // Copy URL to clipboard
            [self copyURL:[NSURL URLWithString:[self.selectedLink valueForKey:@"url"]]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Add to Pinboard", nil)]) {
            // Add to bookmarks
            [self showAddViewController:self.selectedLink];
        }
    }
    else if (actionSheet == self.backActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (buttonIndex < actionSheet.numberOfButtons - 2) {
            NSInteger i=0;
            while (i<buttonIndex+1) {
                [self.webView goBack];
                i++;
            }
        }
        else if ([title isEqualToString:@"Close Browser"]) {
            self.readerWebView.hidden = YES;
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)sendToReadLater {
    // Send to the default read later service
    [self sendToReadLater:[PPSettings sharedSettings].readLater];
}

- (void)sendToReadLater:(PPReadLaterType)service {
    if (self.activityView) {
        [self.activityView dismissViewControllerAnimated:YES completion:nil];
    }
    
    [PPUtilities shareToReadLater:service
                              URL:self.url.absoluteString
                            title:self.title
                            delay:0
                       completion:nil];
}

- (void)toggleMobilizer {
    [self toggleMobilizerAnimated:YES];
}

- (void)toggleMobilizerAnimated:(BOOL)animated {
    [PPSettings sharedSettings].openLinksWithMobilizer = !self.mobilized;

    self.mobilizeButton.selected = !self.mobilized;
    self.mobilized = !self.mobilized;

    [self.indicator startAnimating];
    self.markAsReadButton.hidden = YES;
    if (self.mobilized) {
        self.webView.scrollView.scrollsToTop = NO;
        self.readerWebView.scrollView.scrollsToTop = YES;
        
        [self.webViewTimeoutTimer invalidate];
        [self.webView stopLoading];
        [self.readerWebView loadHTMLString:@"<html><head><script type='text/javascript'>var isLoaded=false;</script></head></html>" baseURL:self.url];
    }
    else {
        [self.readerWebView stopLoading];
        self.webView.scrollView.scrollsToTop = YES;
        self.readerWebView.scrollView.scrollsToTop = NO;

        __weak PPWebViewController *weakself = self;
        [self setReaderViewVisible:NO animated:animated completion:^(BOOL finished) {
            if (![weakself.loadedURLs containsObject:weakself.url]) {
                [weakself loadURL];
            }
            [weakself.indicator stopAnimating];
            weakself.markAsReadButton.hidden = NO;
        }];
    }
}

- (void)copyURL:(NSURL *)url {
    [PPNotification notifyWithMessage:NSLocalizedString(@"URL copied to clipboard.", nil)
                              success:YES
                              updated:NO];
    
    [[UIPasteboard generalPasteboard] setString:self.url.absoluteString];
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
    if (!url || ![url isKindOfClass:[NSURL class]] || [url.absoluteString isEqualToString:@""]) {
        return [NSURL URLWithString:self.urlString];
    }
    return url;
}

- (void)showAddViewController {
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSDictionary *post = @{
        @"title": pageTitle,
        @"url": self.url.absoluteString
    };
    [self showAddViewController:post];
}

- (void)showAddViewController:(NSDictionary *)data {
    PPNavigationController *vc = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:data update:@(NO) callback:nil];
    
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSDictionary *post;

        [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
            FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[self.url.absoluteString]];
            [results next];
            post = [PPUtilities dictionaryFromResultSet:results];
            [results close];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            PPNavigationController *vc = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) callback:nil];
            
            if ([UIApplication isIPad]) {
                vc.modalPresentationStyle = UIModalPresentationFormSheet;
            }

            [self presentViewController:vc animated:YES completion:nil];
        });
    });
}

- (void)closeModal:(UIViewController *)sender success:(void (^)())success {
    [self dismissViewControllerAnimated:YES completion:success];
}

- (void)closeModal:(UIViewController *)sender {
    [self closeModal:sender success:nil];
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

- (NSInteger)numberOfRequestsInProgress {
    return self.numberOfRequests - self.numberOfRequestsCompleted;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (![UIApplication isIPad]) {
        BOOL hideToolbar = self.toolbarConstraint.constant < (kToolbarHeight / 2);
        self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y;
        if (hideToolbar) {
            [self setToolbarVisible:NO animated:YES];
        }
        else {
            [self setToolbarVisible:YES animated:YES];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (![UIApplication isIPad]) {
        CGPoint currentContentOffset = scrollView.contentOffset;
        
        // Only change if the offset is less than the content size minus the height of the toolbar.
        CGFloat distanceFromBottomOfView = scrollView.contentSize.height - currentContentOffset.y - CGRectGetHeight(scrollView.frame);
        BOOL isAtBottomOfView = distanceFromBottomOfView < kToolbarHeight;
        BOOL isAtTopOfView = currentContentOffset.y < 0;
        BOOL isScrollingDown = self.previousContentOffset.y < currentContentOffset.y;
        BOOL isToolbarVisible = self.toolbarConstraint.constant > 0;
        self.previousContentOffset = currentContentOffset;
        
#if HIDE_STATUS_BAR_WHILE_SCROLLING
        if (isScrollingDown && !isAtBottomOfView) {
            [UIView animateWithDuration:0.3 animations:^{
                self.prefersStatusBarHidden = YES;
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        }
#endif

        if (!isAtBottomOfView && !isAtTopOfView && isToolbarVisible) {
            CGFloat height = kToolbarHeight - MAX(0, MIN(kToolbarHeight, currentContentOffset.y - self.yOffsetToStartShowingToolbar));
            self.toolbarConstraint.constant = MAX(0, height);
            [self.view layoutIfNeeded];

            if (!isScrollingDown && self.toolbarConstraint.constant == kToolbarHeight) {
                self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y);
            }
        }
        else if (distanceFromBottomOfView < 0) {
            [self setToolbarVisible:YES animated:YES];
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y);
        }
        else {
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y);
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y;

    if (self.toolbarConstraint.constant == kToolbarHeight) {
        return YES;
    }

    [self setToolbarVisible:YES animated:YES];
    return NO;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        // Reset the "loaded" state on the reader view.
        [[self.readerWebView stringByEvaluatingJavaScriptFromString:@"isLoaded"] isEqualToString:@"false"];
    }

    if (webView == self.webView) {
        if (self.mobilized) {
            return NO;
        }
        else {
            if ([@[@"http", @"https", @"file"] containsObject:request.URL.scheme] || [request.URL.scheme isEqualToString:@"about"]) {
                self.numberOfRequestsCompleted = 0;
                self.numberOfRequests = 0;
                self.markAsReadButton.hidden = YES;
                [self.indicator startAnimating];
                
                switch (navigationType) {
                    case UIWebViewNavigationTypeLinkClicked:
                        break;

                    case UIWebViewNavigationTypeOther:
                        break;
                        
                    case UIWebViewNavigationTypeReload:
                        break;
                        
                    case UIWebViewNavigationTypeBackForward:
                        // We've disabled forward in the UI, so it must be a pop of the stack.
                        [self.history removeLastObject];
                        
                    default:
                        webView.scrollView.contentOffset = CGPointMake(0, 0);
                        break;
                }
                
                return YES;
            }
            else {
                if (!self.openLinkExternallyAlertView) {
                    self.openLinkExternallyAlertView = [[UIAlertView alloc] initWithTitle:@"Leave Pushpin?"
                                                                                  message:@"The link is requesting to open an external application. Would you like to continue?"
                                                                                 delegate:self
                                                                        cancelButtonTitle:@"Cancel"
                                                                        otherButtonTitles:@"Open", nil];
                    [self.openLinkExternallyAlertView show];
                    self.urlToOpenExternally = webView.request.URL;
                }
                return NO;
            }
        }
    }
    else {
        if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            [self toggleMobilizer];
            
            NSURLRequest *newRequest = [NSURLRequest requestWithURL:request.URL];
            [self.webView loadRequest:newRequest];
            return NO;
        }
        else {
            return YES;
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (webView == self.webView) {
        self.numberOfRequestsCompleted++;
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
    }

    [self enableOrDisableButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView == self.webView) {
        self.numberOfRequestsCompleted++;
        
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        [self enableOrDisableButtons];
        
        // Only run the following when this is an actual web URL.
        if (![self.url.scheme isEqualToString:@"file"]) {
            self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];

            if ([[self.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
                self.titleLabel.text = self.url.host;
            }
            else {
                self.titleLabel.text = self.title;
            }
            
            if (![[self.history lastObject][@"url"] isEqualToString:self.url.absoluteString]) {
                NSArray *titleComponents = [self.title componentsSeparatedByString:@" "];
                NSMutableArray *finalTitleComponents = [NSMutableArray array];
                for (NSString *component in titleComponents) {
                    if ([finalTitleComponents componentsJoinedByString:@" "].length + component.length + 1 < 24) {
                        [finalTitleComponents addObject:component];
                    }
                    else {
                        break;
                    }
                }
                
                [self.history addObject:@{@"url": self.url.absoluteString,
                                          @"host": self.url.host,
                                          @"title": [finalTitleComponents componentsJoinedByString:@" "] }];
            }

            self.mobilizeButton.enabled = [PPMobilizerUtility canMobilizeURL:self.url];
            
            // Disable the default action sheet
            [self addTouchOverridesForWebView:webView];
            
            if (self.numberOfRequestsInProgress == 0) {
                [self updateInterfaceWithComputedWebPageBackgroundColor];
                [self.loadedURLs addObject:self.url];
            }
            
            if ([self.webView canGoBack]) {
                UIImage *backButtonImage = [[UIImage imageNamed:@"back_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.backButton setImage:backButtonImage forState:UIControlStateNormal];
            }
            else {
                UIImage *stopButtonImage = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.backButton setImage:stopButtonImage forState:UIControlStateNormal];
            }
        }
    }
    else {
        BOOL isLoaded = [[self.readerWebView stringByEvaluatingJavaScriptFromString:@"isLoaded"] isEqualToString:@"true"];
        if (isLoaded) {
            [self updateInterfaceWithComputedWebPageBackgroundColor];
            
            self.markAsReadButton.hidden = NO;
            [self.indicator stopAnimating];

            [self setReaderViewVisible:YES animated:YES completion:nil];
            [self addTouchOverridesForWebView:self.readerWebView];
            [self enableOrDisableButtons];
        }
        else {
            [PPWebViewController mobilizedPageForURL:self.url withCompletion:^(NSDictionary *article, NSError *error) {
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (article) {
                            NSString *content = [[PPSettings sharedSettings].readerSettings readerHTMLForArticle:article];
                            [self.readerWebView loadHTMLString:content baseURL:self.url];
                        }
                        else {
                            self.mobilizeButton.selected = NO;
                        }
                    });
                }
            }];
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView == self.webView) {
        [self.webViewTimeoutTimer invalidate];
        
    #warning https://crashlytics.com/lionheart-software2/ios/apps/io.aurora.pushpin/issues/532e17d2fabb27481b18f9ce
        self.webViewTimeoutTimer = [NSTimer timerWithTimeInterval:5
                                                           target:self
                                                         selector:@selector(webViewLoadTimedOut)
                                                         userInfo:nil
                                                          repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.webViewTimeoutTimer forMode:NSRunLoopCommonModes];

        self.numberOfRequests++;
        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
        [self enableOrDisableButtons];
    }
}

- (void)webViewLoadTimedOut {
    [self updateInterfaceWithComputedWebPageBackgroundColorTimedOut:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.openLinkExternallyAlertView) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Open"]) {
            [[UIApplication sharedApplication] openURL:self.urlToOpenExternally];
        }
    }
    
    self.openLinkExternallyAlertView = nil;
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    self.openLinkExternallyAlertView = nil;
}

#pragma mark - Utils

- (void)updateInterfaceWithComputedWebPageBackgroundColor {
    [self updateInterfaceWithComputedWebPageBackgroundColorTimedOut:NO];
}

- (void)updateInterfaceWithComputedWebPageBackgroundColorTimedOut:(BOOL)timedOut {
#if HIDE_STATUS_BAR_WHILE_SCROLLING
    self.prefersStatusBarHidden = NO;
#endif
    UIWebView *webView = self.currentWebView;
    UIColor *backgroundColor = [UIColor whiteColor];
    BOOL isDark = NO;

    if (!timedOut) {
        NSString *response = [webView stringByEvaluatingJavaScriptFromString:@"window.getComputedStyle(document.body, null).getPropertyValue(\"background-color\")"];
        
        NSError *error;
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"rgba?\\((\\d*), (\\d*), (\\d*)(, (\\d*))?\\)" options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult *match = [expression firstMatchInString:response options:0 range:NSMakeRange(0, response.length)];
        if (match) {
            NSString *redString = [response substringWithRange:[match rangeAtIndex:1]];
            NSString *greenString = [response substringWithRange:[match rangeAtIndex:2]];
            NSString *blueString = [response substringWithRange:[match rangeAtIndex:3]];
            CGFloat R = [redString floatValue] / 255;
            CGFloat G = [greenString floatValue] / 255;
            CGFloat B = [blueString floatValue] / 255;
            CGFloat alpha = 1;
            
            NSRange alphaRange = [match rangeAtIndex:5];
            if (alphaRange.location != NSNotFound) {
                NSString *alphaString = [response substringWithRange:alphaRange];
                alpha = [alphaString floatValue];
            }
            
            // Formula derived from here:
            // http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
            
            // Alpha blending:
            // http://stackoverflow.com/a/746937/39155
            CGFloat newR = (255 * (1 - alpha) + 255 * R * alpha) / 255.;
            CGFloat newG = (255 * (1 - alpha) + 255 * G * alpha) / 255.;
            CGFloat newB = (255 * (1 - alpha) + 255 * B * alpha) / 255.;
            isDark = ((newR * 255 * 299) + (newG * 255 * 587) + (newB * 255 * 114)) / 1000 < 200;
            backgroundColor = [UIColor colorWithRed:newR green:newG blue:newB alpha:1];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            self.statusBarBackgroundView.backgroundColor = backgroundColor;
            self.toolbarBackgroundView.backgroundColor = backgroundColor;
            webView.backgroundColor = backgroundColor;
            
            if (isDark) {
                [self tintButtonsWithColor:[UIColor whiteColor]];
                self.titleLabel.textColor = [UIColor whiteColor];
                self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
            }
            else {
                [self tintButtonsWithColor:HEX(0x555555FF)];
                self.titleLabel.textColor = [UIColor darkTextColor];
                self.preferredStatusBarStyle = UIStatusBarStyleDefault;
            }

            [self setNeedsStatusBarAppearanceUpdate];
        }];
    });
}

- (void)tintButtonsWithColor:(UIColor *)color {
    self.actionButton.tintColor = color;
    self.backButton.tintColor = color;
    self.editButton.tintColor = color;
    self.addButton.tintColor = color;
    self.mobilizeButton.tintColor = color;
    self.markAsReadButton.tintColor = color;
}

- (void)setToolbarVisible:(BOOL)visible animated:(BOOL)animated {
    CGFloat constant;
    if (visible) {
        constant = kToolbarHeight;
    }
    else {
        constant = 0;
    }
    
    void (^UpdateConstraint)() = ^{
        self.toolbarConstraint.constant = constant;
        [self.view layoutIfNeeded];
        
#if HIDE_STATUS_BAR_WHILE_SCROLLING
        if (visible) {
            self.prefersStatusBarHidden = NO;
            [self setNeedsStatusBarAppearanceUpdate];
        }
#endif
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.5
              initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:UpdateConstraint
                         completion:nil];
    }
    else {
        UpdateConstraint();
    }
}

#pragma mark - UIKeyCommand

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.goBackKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.goBackKeyCommand) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -

- (UIWebView *)currentWebView {
    UIWebView *webView;
    if (self.mobilized) {
        webView = self.readerWebView;
    }
    else {
        webView = self.webView;
    }
    return webView;
}

+ (void)mobilizedPageForURL:(NSURL *)url withCompletion:(void (^)(NSDictionary *, NSError *))completion {
    NSURL *mobilizedURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://pushpin-readability.herokuapp.com/v1/parser?url=%@&format=json&onerr=", [url.absoluteString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"pushpin-readability.herokuapp.com"
                                                                                  port:80
                                                                              protocol:@"http"
                                                                                 realm:@"Pushpin"
                                                                  authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    NSURLCredentialStorage *credentials = [NSURLCredentialStorage sharedCredentialStorage];
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:@"pushpin"
                                                             password:@"9346edb36e542dab1e7861227f9222b7"
                                                          persistence:NSURLCredentialPersistenceForSession];
    [credentials setDefaultCredential:credential forProtectionSpace:protectionSpace];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCredentialStorage = credentials;
    configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:mobilizedURL
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:10];
    
    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
#warning Sometimes getting a 401 here. Not sure why.
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];

                                                if ([[(NSHTTPURLResponse *)response MIMEType] isEqualToString:@"text/plain"]) {
                                                    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                    NSData *encodedData = [NSData dataWithBase64EncodedString:string];
                                                    NSData *decryptedData = [RNDecryptor decryptData:encodedData
                                                                                        withPassword:@"Isabelle and Dante"
                                                                                               error:nil];
                                                    id article = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                                                                 options:NSJSONReadingAllowFragments
                                                                                                   error:nil];

                                                    if ([article[@"work_count"] isEqualToNumber:@(0)]) {
#warning TODO
                                                        completion(nil, nil);
                                                    }
                                                    else {
                                                        completion(article, nil);
                                                    }
                                                }
                                                else {
                                                    completion(nil, error);
                                                }
                                            }];
    [task resume];
}

- (void)setReaderViewVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    void (^animations)();

    if (visible) {
        self.readerWebView.hidden = NO;

        animations = ^{
            self.readerWebView.alpha = 1;
        };
    }
    else {
        animations = ^{
            self.readerWebView.alpha = 0;
        };
    }
    
    if (animated) {
        [UIView animateWithDuration:kPPReaderViewAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:^(BOOL finished) {
                             if (visible) {
                                 [self.indicator stopAnimating];
                                 self.markAsReadButton.hidden = NO;
                             }
                             else {
                                 self.readerWebView.hidden = YES;
                             }
                             
                             if (completion) {
                                 completion(finished);
                             }
                         }];
    }
    else {
        animations();
    }
}

- (void)markAsReadButtonTouchUpInside:(id)sender {
#ifdef PINBOARD
    id<PPDataSource> dataSource = [[PPPinboardDataSource alloc] init];
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSDictionary *post;
        
        [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
            FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[self.url.absoluteString]];
            [results next];
            post = [PPUtilities dictionaryFromResultSet:results];
            [results close];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
            [self.indicator startAnimating];
            self.markAsReadButton.hidden = YES;

            [dataSource markPostAsRead:post[@"url"] callback:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                    [self.indicator stopAnimating];

                    NSString *message;
                    BOOL success = YES, updated = YES;
                    self.markAsReadButton.hidden = NO;

                    // If we have any errors, update the local notification
                    if (error) {
                        success = NO;
                        updated = NO;
                        message = NSLocalizedString(@"There was an error marking your bookmarks as read.", nil);
                    }
                    else {
                        self.markAsReadButton.enabled = NO;
                        message = NSLocalizedString(@"Bookmark marked as read.", nil);
                    }

                    [PPNotification notifyWithMessage:message success:success updated:updated];
                });
            }];
        });
    });
}

- (void)addTouchOverridesForWebView:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"webview-helpers" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil]];
}

@end

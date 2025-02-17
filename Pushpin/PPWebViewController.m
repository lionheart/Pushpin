// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

#if !TARGET_OS_MACCATALYST
@import Twitter;
#endif

@import SafariServices;
@import LHSCategoryCollection;
@import RNCryptor_objc;
@import JavaScriptCore;
@import KeychainItemWrapper;

#import "PPWebViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPBrowserActivity.h"
#import "PPNavigationController.h"
#import "PPGenericPostViewController.h"
#import "PPActivityViewController.h"
#import "PPUtilities.h"
#import "PPMobilizerUtility.h"
#import "PPSettings.h"
#import "PPCachingURLProtocol.h"
#import "PPPinboardDataSource.h"
#import "PPNotification.h"

#import "NSData+AES256.h"
#import "NSString+URLEncoding2.h"
#import "UIView+LHSAdditions.h"

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

#if TARGET_OS_MACCATALYST
@property (nonatomic, strong) WKWebView *readerWebView;
#else
@property (nonatomic, strong) UIWebView *readerWebView;
#endif

@property (nonatomic) BOOL mobilized;
@property (nonatomic, strong) NSMutableSet *loadedURLs;
@property (nonatomic) UIStatusBarStyle statusBarStyle;

- (void)updateInterfaceWithComputedWebPageBackgroundColor;
- (void)updateInterfaceWithComputedWebPageBackgroundColorTimedOut:(BOOL)timedOut;
- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;
- (void)markAsReadButtonTouchUpInside:(id)sender;
//- (BOOL)mobilized;

#if TARGET_OS_MACCATALYST
- (WKWebView *)currentWebView;
#else
- (UIWebView *)currentWebView;
#endif

- (void)setReaderViewVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setToolbarVisible:(BOOL)visible animated:(BOOL)animated;

#if TARGET_OS_MACCATALYST
- (void)addTouchOverridesForWebView:(WKWebView *)webView;
#else
- (void)addTouchOverridesForWebView:(UIWebView *)webView;
#endif

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

    self.statusBarStyle = UIStatusBarStyleDefault;
    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.history = [NSMutableArray array];
    self.loadedURLs = [NSMutableSet set];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];

    self.bottomTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.bottomTapGestureRecognizer.numberOfTapsRequired = 1;

    self.statusBarBackgroundView = [[UIView alloc] init];
    self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
    self.statusBarBackgroundView.userInteractionEnabled = NO;
    self.statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusBarBackgroundView];

#if TARGET_OS_MACCATALYST
    self.webView = [[WKWebView alloc] init];
#else
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
#endif
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, kToolbarHeight, 0);
    [self.view addSubview:self.webView];

    self.webViewTimeoutTimer = [NSTimer timerWithTimeInterval:5 target:self.webView selector:@selector(stopLoading) userInfo:nil repeats:NO];

#if TARGET_OS_MACCATALYST
    self.readerWebView = [[WKWebView alloc] init];
#else
    self.readerWebView = [[UIWebView alloc] init];
    self.readerWebView.delegate = self;
#endif
    self.readerWebView.backgroundColor = [UIColor whiteColor];
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

    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
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
    [self.view addSubview:self.toolbar];



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

    [self.indicator.centerXAnchor constraintEqualToAnchor:self.markAsReadButton.centerXAnchor].active = YES;
    [self.indicator.centerYAnchor constraintEqualToAnchor:self.markAsReadButton.centerYAnchor].active = YES;

    [self.toolbar lhs_addConstraints:@"H:|[back][read(==back)][mobilize(==back)][edit(==back)][action(==back)]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[background(height)]" metrics:@{@"height": @(kToolbarHeight + 60)} views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];

    NSArray<UIView *> *fullHeightViews = @[
        self.backButton,
        self.markAsReadButton,
        self.mobilizeButton,
        self.actionButton,
        self.editButton,
        self.addButton,
    ];

    NSArray <UIView *> *fullWidthViews = @[
        toolbarBorderView,
        self.toolbarBackgroundView,
        self.statusBarBackgroundView,
        self.toolbar,
        self.webView,
        self.readerWebView,
        self.showToolbarAndTitleBarHiddenView,
    ];

    [UIView lhs_addConstraints:@"V:|[view]|" views:fullHeightViews];
    [UIView lhs_addConstraints:@"H:|[view]|" views:fullWidthViews];

    [self.editButton.leftAnchor constraintEqualToAnchor:self.addButton.leftAnchor].active = YES;
    [self.editButton.rightAnchor constraintEqualToAnchor:self.addButton.rightAnchor].active = YES;

    [self tintButtonsWithColor:[UIColor darkGrayColor]];

    NSDictionary *views = @{
        @"toolbar": self.toolbar,
        @"background": self.statusBarBackgroundView,
        @"show": self.showToolbarAndTitleBarHiddenView,
        @"webview": self.webView,
        @"reader": self.readerWebView,
        @"bottom": self.bottomLayoutGuide
    };

    // Make sure the height of the reader view is the same as the web view
    [self.readerWebView.heightAnchor constraintEqualToAnchor:self.webView.heightAnchor].active = YES;
    [self.readerWebView.centerXAnchor constraintEqualToAnchor:self.webView.centerXAnchor].active = YES;
    [self.readerWebView.centerYAnchor constraintEqualToAnchor:self.webView.centerYAnchor].active = YES;

    NSDictionary *metrics = @{@"height": @(kToolbarHeight)};

    [self.view lhs_addConstraints:@"V:[show(height)][bottom]" metrics:metrics views:views];
    [self.view lhs_addConstraints:@"V:|[background][webview][bottom]" metrics:metrics views:views];
    [self.view lhs_addConstraints:@"V:[toolbar(>=height)]" metrics:metrics views:views];

    self.toolbarConstraint = [self.bottomLayoutGuide.bottomAnchor constraintEqualToAnchor:self.toolbar.topAnchor constant:kToolbarHeight];
    //self.toolbarConstraint.active = YES;

    [self.bottomLayoutGuide.bottomAnchor constraintLessThanOrEqualToAnchor:self.toolbar.bottomAnchor];
    self.topLayoutConstraint = [self.statusBarBackgroundView lhs_setHeight:0];

    UIView *myView = [[UIView alloc] init];
    [self.view addSubview:myView];
    myView.backgroundColor = self.toolbar.backgroundColor;
    myView.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
    [myView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor].active = YES;
    [myView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor].active = YES;
    [myView.topAnchor constraintEqualToAnchor:guide.bottomAnchor].active = YES;
    [myView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.toolbar.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor].active = YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer || (recognizer == self.readerLongPressGestureRecognizer && !self.selectedActionSheet)) {
        UIWebView *webView = (UIWebView *)recognizer.view;

        // Get the coordinates of the selected element
        CGPoint webViewCoordinates = [recognizer locationInView:webView];
        CGSize viewSize = webView.frame.size;
        CGFloat webViewContentWidth = [[webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
        CGFloat scaleRatio = webViewContentWidth / viewSize.width;
        webViewCoordinates.x = webViewCoordinates.x * scaleRatio;
        webViewCoordinates.y = webViewCoordinates.y * scaleRatio;

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
        self.selectedActionSheet = [UIAlertController lhs_actionSheetWithTitle:url];

        [self.selectedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Add to Pinboard", nil)
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [self showAddViewController:self.selectedLink];
            self.selectedActionSheet = nil;
        }];

        [self.selectedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Copy URL", nil)
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [self copyURL:[NSURL URLWithString:self.selectedLink[@"url"]]];
            self.selectedActionSheet = nil;
        }];

        [self.selectedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *action) {
            self.selectedActionSheet = nil;
        }];

        self.selectedActionSheet.popoverPresentationController.sourceView = self.view;
        self.selectedActionSheet.popoverPresentationController.sourceRect = (CGRect){webViewCoordinates, {1, 1}};
        [self presentViewController:self.selectedActionSheet animated:YES completion:nil];
    } else if (recognizer == self.backButtonLongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            self.backActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];

            NSRange range = NSMakeRange(MAX(0, (NSInteger)self.history.count - 5), MIN(5, self.history.count));
            NSArray *lastFiveHistoryItems = [self.history subarrayWithRange:range];
            for (NSInteger i=lastFiveHistoryItems.count - 1; i>0; i--) {
                NSDictionary *item = lastFiveHistoryItems[i];
                [self.backActionSheet lhs_addActionWithTitle:[NSString stringWithFormat:@"%@", item[@"host"]]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                    NSInteger buttonIndex = [self.backActionSheet.actions indexOfObject:action];
                    NSInteger i=0;
                    while (i<buttonIndex+1) {
                        [self.webView goBack];
                        i++;
                    }
                }];
            }

            [self.backActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Close Browser", nil)
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
                self.readerWebView.hidden = YES;
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }];

            [self.backActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
            CGPoint point = [self.backButtonLongPressGestureRecognizer locationInView:self.backButton];

            self.backActionSheet.popoverPresentationController.sourceView = self.backButton;
            self.backActionSheet.popoverPresentationController.sourceRect = (CGRect){point, {1, 1}};
            [self presentViewController:self.backActionSheet animated:YES completion:nil];
        }
    } else if (recognizer == self.bottomTapGestureRecognizer) {
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
        [self toggleMobilizerAnimated:NO loadOriginalURL:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.yOffsetToStartShowingToolbar = self.webView.scrollView.contentOffset.y + kToolbarHeight;

    if (![self.loadedURLs containsObject:self.url]) {
        [self loadURL];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopLoading];

    self.webView.scrollView.delegate = nil;
    self.readerWebView.scrollView.delegate = nil;
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

            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
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
                } else {
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
    } else {
        if (!self.mobilized) {
            // Hide the reader web view.
            [self setReaderViewVisible:NO animated:NO completion:nil];
        }

        [UIView animateWithDuration:0.3
                         animations:^{
            self.statusBarStyle = UIStatusBarStyleLightContent;
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

    self.activityView.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
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
    } else {
        [self presentViewController:self.activityView animated:YES completion:nil];
    }
}

- (void)toggleMobilizer {
    [self toggleMobilizerAnimated:YES loadOriginalURL:YES];
}

- (void)toggleMobilizerAnimated:(BOOL)animated loadOriginalURL:(BOOL)loadOriginalURL {
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
    } else {
        [self.readerWebView stopLoading];
        self.webView.scrollView.scrollsToTop = YES;
        self.readerWebView.scrollView.scrollsToTop = NO;

        __weak PPWebViewController *weakself = self;
        [self setReaderViewVisible:NO animated:animated completion:^(BOOL finished) {
            if (loadOriginalURL) {
                if (![weakself.loadedURLs containsObject:weakself.url]) {
                    [weakself loadURL];
                }
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

}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSURL *)url {
#if TARGET_OS_MACCATALYST
    NSURL *url = self.webView.URL;
#else
    NSURL *url = [self.webView.request URL];
#endif

    if (!url || ![url isKindOfClass:[NSURL class]] || [url.absoluteString isEqualToString:@""]) {
        return [NSURL URLWithString:self.urlString];
    }
    return url;
}

- (void)showAddViewController {
#if TARGET_OS_MACCATALYST
    [self.webView evaluateJavaScript:@"document.title" completionHandler:^(NSString * _Nullable title, NSError * _Nullable error) {
        NSDictionary *post = @{
            @"title": title,
            @"url": self.url.absoluteString
        };
        [self showAddViewController:post];
    }];
#else
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSDictionary *post = @{
        @"title": pageTitle,
        @"url": self.url.absoluteString
    };
    [self showAddViewController:post];
#endif
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

        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
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

- (void)closeModal:(UIViewController *)sender success:(void (^)(void))success {
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

- (NSInteger)numberOfRequestsInProgress {
    return self.numberOfRequests - self.numberOfRequestsCompleted;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (![UIApplication isIPad]) {
        BOOL hideToolbar = self.toolbarConstraint.constant < (kToolbarHeight / 2);
        if (hideToolbar) {
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y);
            [self setToolbarVisible:NO animated:YES];
        } else {
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y) + kToolbarHeight;
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
        BOOL isAtTopOfView = currentContentOffset.y <= 0;
        BOOL isScrollingDown = self.previousContentOffset.y < currentContentOffset.y;
        BOOL isToolbarPartlyVisible = self.toolbarConstraint.constant > 0;
        BOOL isToolbarFullyVisible = self.toolbarConstraint.constant == kToolbarHeight;
        self.previousContentOffset = currentContentOffset;

#if HIDE_STATUS_BAR_WHILE_SCROLLING
        if (isScrollingDown && !isAtBottomOfView) {
            [UIView animateWithDuration:0.3 animations:^{
                self.prefersStatusBarHidden = YES;
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        }
#endif
        CGFloat distanceFromToolbarShowingOffset = MAX(0, self.yOffsetToStartShowingToolbar - currentContentOffset.y);

        if (!isAtBottomOfView && !isAtTopOfView) {
            if (isToolbarFullyVisible) {
                if (isScrollingDown) {
                    self.toolbarConstraint.constant = MIN(kToolbarHeight, distanceFromToolbarShowingOffset);
                    [self.view layoutIfNeeded];
                } else {
                    self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y + kToolbarHeight;
                }
            } else if (isToolbarPartlyVisible) {
                self.toolbarConstraint.constant = MIN(kToolbarHeight, distanceFromToolbarShowingOffset);
                [self.view layoutIfNeeded];
            } else {
                if (isScrollingDown) {
                    self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y;
                } else {
                    self.toolbarConstraint.constant = MIN(kToolbarHeight, distanceFromToolbarShowingOffset);
                    [self.view layoutIfNeeded];

                }
            }
        } else if (distanceFromBottomOfView < 0) {
            [self setToolbarVisible:YES animated:YES];
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y);
        } else {
            self.yOffsetToStartShowingToolbar = MAX(0, scrollView.contentOffset.y) + kToolbarHeight;
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y + kToolbarHeight;

    if (self.toolbarConstraint.constant == kToolbarHeight) {
        return YES;
    }

    [self setToolbarVisible:YES animated:YES];
    return NO;
}

#pragma mark - UIWebViewDelegate

#if TARGET_OS_MACCATALYST

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
}

#else

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (self.selectedActionSheet) {
        return NO;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        // Reset the "loaded" state on the reader view.
        [[self.readerWebView stringByEvaluatingJavaScriptFromString:@"isLoaded"] isEqualToString:@"false"];
    }

    if (webView == self.webView) {
        if (self.mobilized) {
            return NO;
        } else {
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
            } else {
#warning is this right?
                if (!self.openLinkExternallyAlertView.presentingViewController) {
                    self.openLinkExternallyAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Leave Pushpin?", nil)
                                                                                         message:NSLocalizedString(@"The link is requesting to open an external application. Would you like to continue?", nil)];

                    [self.openLinkExternallyAlertView lhs_addActionWithTitle:NSLocalizedString(@"Open", nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                        [[UIApplication sharedApplication] openURL:webView.request.URL options:@{} completionHandler:nil];;
                    }];

                    [self.openLinkExternallyAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:nil];

                    [self presentViewController:self.openLinkExternallyAlertView animated:YES completion:nil];
                }
                return NO;
            }
        }
    } else {
        if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            [self toggleMobilizerAnimated:YES loadOriginalURL:NO];

            NSURLRequest *newRequest = [NSURLRequest requestWithURL:request.URL];
            [self.webView loadRequest:newRequest];
            return NO;
        } else {
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
            } else {
                self.titleLabel.text = self.title;
            }

            if (![[self.history lastObject][@"url"] isEqualToString:self.url.absoluteString]) {
                NSArray *titleComponents = [self.title componentsSeparatedByString:@" "];
                NSMutableArray *finalTitleComponents = [NSMutableArray array];
                for (NSString *component in titleComponents) {
                    if ([finalTitleComponents componentsJoinedByString:@" "].length + component.length + 1 < 24) {
                        [finalTitleComponents addObject:component];
                    } else {
                        break;
                    }
                }

                if ([finalTitleComponents count] > 0) {
                    [self.history addObject:@{@"url": self.url.absoluteString,
                                              @"host": self.url.host,
                                              @"title": [finalTitleComponents componentsJoinedByString:@" "] }];
                }
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
            } else {
                UIImage *stopButtonImage = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.backButton setImage:stopButtonImage forState:UIControlStateNormal];
            }
        }
    } else {
        BOOL isLoaded = [[self.readerWebView stringByEvaluatingJavaScriptFromString:@"isLoaded"] isEqualToString:@"true"];
        if (isLoaded) {
            [self updateInterfaceWithComputedWebPageBackgroundColor];

            self.markAsReadButton.hidden = NO;
            [self.indicator stopAnimating];

            [self setReaderViewVisible:YES animated:YES completion:nil];
            [self addTouchOverridesForWebView:self.readerWebView];
            [self enableOrDisableButtons];
        } else {
            [PPWebViewController mobilizedPageForURL:self.url withCompletion:^(NSDictionary *article, NSError *error) {
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (article) {
                            NSString *content = [[PPSettings sharedSettings].readerSettings readerHTMLForArticle:article];
                            [self.readerWebView loadHTMLString:content baseURL:self.url];
                            self.readerWebView.hidden = NO;
                        } else {
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

      dispatch_async(dispatch_get_main_queue(), ^{
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
      });
    }
}
#endif

- (void)webViewLoadTimedOut {
    [self updateInterfaceWithComputedWebPageBackgroundColorTimedOut:YES];
}

#pragma mark - Utils

- (void)updateInterfaceWithComputedWebPageBackgroundColor {
    [self updateInterfaceWithComputedWebPageBackgroundColorTimedOut:NO];
}

- (void)updateInterfaceWithComputedWebPageBackgroundColorTimedOut:(BOOL)timedOut {
#if HIDE_STATUS_BAR_WHILE_SCROLLING
    self.prefersStatusBarHidden = NO;
#endif

#if TARGET_OS_MACCATALYST
    WKWebView *webView = self.currentWebView;
#else
    UIWebView *webView = self.currentWebView;
#endif

    UIColor *backgroundColor = [UIColor whiteColor];
    BOOL isDark = NO;

#if !TARGET_OS_MACCATALYST
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
#endif

    [UIView animateWithDuration:0.3 animations:^{
        self.statusBarBackgroundView.backgroundColor = backgroundColor;
        self.toolbarBackgroundView.backgroundColor = backgroundColor;
        webView.backgroundColor = backgroundColor;

        if (isDark) {
            [self tintButtonsWithColor:[UIColor whiteColor]];
            self.titleLabel.textColor = [UIColor whiteColor];
            self.statusBarStyle = UIStatusBarStyleLightContent;
        } else {
            [self tintButtonsWithColor:HEX(0x555555FF)];
            self.titleLabel.textColor = [UIColor darkTextColor];
            self.statusBarStyle = UIStatusBarStyleDefault;
        }

        [self setNeedsStatusBarAppearanceUpdate];
    }];
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
    } else {
        constant = 0;
    }

    void (^UpdateConstraint)(void) = ^{
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
    } else {
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

#if TARGET_OS_MACCATALYST
- (WKWebView *)currentWebView {
    WKWebView *webView;
    if (self.mobilized) {
        webView = self.readerWebView;
    } else {
        webView = self.webView;
    }
    return webView;
}
#else
- (UIWebView *)currentWebView {
    UIWebView *webView;
    if (self.mobilized) {
        webView = self.readerWebView;
    } else {
        webView = self.webView;
    }
    return webView;
}
#endif

+ (void)mobilizedPageForURL:(NSURL *)url withCompletion:(void (^)(NSDictionary *, NSError *))completion {
    NSURL *mobilizedURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://pushpin-readability.herokuapp.com/v1/parser?url=%@&format=json&onerr=", [url.absoluteString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];

    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"pushpin-readability.herokuapp.com"
                                                                                  port:443
                                                                              protocol:@"https"
                                                                                 realm:@"Pushpin"
                                                                  authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    NSURLCredentialStorage *credentials = [NSURLCredentialStorage sharedCredentialStorage];

    NSURLCredential *credential = [NSURLCredential credentialWithUser:@"pushpin"
                                                             password:@"9346edb36e542dab1e7861227f9222b7"
                                                          persistence:NSURLCredentialPersistenceForSession];
    [credentials setDefaultCredential:credential forProtectionSpace:protectionSpace];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCredentialStorage = credentials;
    configuration.URLCache = [PPAppDelegate sharedDelegate].urlCache;
    configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:mobilizedURL
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:10];

    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];

        if ([[(NSHTTPURLResponse *)response MIMEType] isEqualToString:@"text/plain"]) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSData *encodedData = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
            NSData *decryptedData = [RNDecryptor decryptData:encodedData withPassword:@"Isabelle and Dante" error:nil];
            id article = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

            if ([article[@"work_count"] isEqualToNumber:@(0)]) {
#warning TODO
                completion(nil, nil);
            } else {
                completion(article, nil);
            }
        } else {
            completion(nil, error);
        }
    }];
    [task resume];
}

- (void)setReaderViewVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    void (^animations)(void);

    if (visible) {
        self.readerWebView.hidden = NO;

        animations = ^{
            self.readerWebView.alpha = 1;
        };
    } else {
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
            } else {
                self.readerWebView.hidden = YES;
            }

            if (completion) {
                completion(finished);
            }
        }];
    } else {
        animations();
    }
}

- (void)markAsReadButtonTouchUpInside:(id)sender {
    id<PPDataSource> dataSource = [[PPPinboardDataSource alloc] init];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSDictionary *post;

        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
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
                    } else {
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end


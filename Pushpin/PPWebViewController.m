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
#import <SafariServices/SafariServices.h>

#import "PPWebViewController.h"
#import "AddBookmarkViewController.h"
#import "PPBrowserActivity.h"
#import "PPReadLaterActivity.h"
#import "PPNavigationController.h"
#import "GenericPostViewController.h"
#import "PPMobilizerUtility.h"

#import "NSString+URLEncoding2.h"
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <UIView+LHSAdditions.h>
#import <FMDB/FMDatabase.h>
#import <PocketAPI/PocketAPI.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSInteger kToolbarHeight = 44;
static NSInteger kTitleHeight = 40;

@interface PPWebViewController ()

@property (nonatomic) BOOL mobilized;
@property (nonatomic, strong) PPMobilizerUtility *mobilizerUtility;
@property (nonatomic) CGFloat yOffsetToStartShowingToolbar;
@property (nonatomic) CGPoint previousContentOffset;

@end

@implementation PPWebViewController

- (void)viewDidLayoutSubviews {
    self.topLayoutConstraint.constant = [self.topLayoutGuide length];
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.mobilizerUtility = [PPMobilizerUtility sharedInstance];
    self.mobilized = NO;
    self.prefersStatusBarHidden = NO;
    self.preferredStatusBarStyle = UIStatusBarStyleDefault;
    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.stopped = NO;
    self.history = [NSMutableArray array];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    
    self.bottomTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.bottomTapGestureRecognizer.numberOfTapsRequired = 1;
    
    self.webViewTimeoutTimer = [NSTimer timerWithTimeInterval:5 target:self.webView selector:@selector(stopLoading) userInfo:nil repeats:NO];
    
    self.statusBarBackgroundView = [[UIView alloc] init];
    self.statusBarBackgroundView.userInteractionEnabled = YES;
    self.statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.statusBarBackgroundView];

    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.webView.autoresizingMask = UIViewAutoresizingNone;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.bounces = YES;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.userInteractionEnabled = YES;
    [self.view addSubview:self.webView];
    
    self.showToolbarAndTitleBarHiddenView = [[UIView alloc] init];
    self.showToolbarAndTitleBarHiddenView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showToolbarAndTitleBarHiddenView addGestureRecognizer:self.bottomTapGestureRecognizer];
    [self.view addSubview:self.showToolbarAndTitleBarHiddenView];
    
    // Long press gesture for custom menu
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.longPressGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.longPressGestureRecognizer];
    
    self.toolbar = [[UIView alloc] init];
    self.toolbar.backgroundColor = [UIColor whiteColor];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;

    self.toolbarBackgroundView = [[UIView alloc] init];
    self.toolbarBackgroundView.backgroundColor = [UIColor whiteColor];
    self.toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.toolbarBackgroundView];

    UIImage *backButtonImage = [[UIImage imageNamed:@"back_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:backButtonImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];

    self.backButtonLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [self.backButtonLongPressGestureRecognizer addTarget:self action:@selector(gestureDetected:)];
    [self.backButton addGestureRecognizer:self.backButtonLongPressGestureRecognizer];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.backButton];

    UIImage *markAsReadImage = [[UIImage imageNamed:@"mark-as-read"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.markAsReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.markAsReadButton setImage:markAsReadImage forState:UIControlStateNormal];
    [self.markAsReadButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    self.markAsReadButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.markAsReadButton.enabled = NO;
    [self.toolbar addSubview:self.markAsReadButton];

    UIImage *stopButtonImage = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stopButton addTarget:self action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton setImage:stopButtonImage forState:UIControlStateNormal];
    self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.stopButton.hidden = YES;
    [self.toolbar addSubview:self.stopButton];

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
    self.actionButton.enabled = NO;
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
    
    NSDictionary *toolbarViews = @{@"back": self.backButton,
                                   @"read": self.markAsReadButton,
                                   @"mobilize": self.mobilizeButton,
                                   @"action": self.actionButton,
                                   @"edit": self.editButton,
                                   @"stop": self.stopButton,
                                   @"add": self.addButton,
                                   @"background": self.toolbarBackgroundView,
                                   @"border": toolbarBorderView };

    [self.toolbar lhs_addConstraints:@"H:|[back][read(==back)][stop(==back)][edit(==back)][action(==back)]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[background]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[background(height)]" metrics:@{@"height": @(kToolbarHeight + 60)} views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[back]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[mobilize]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[action]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[edit]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[stop]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[add]|" views:toolbarViews];
    
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.stopButton attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.mobilizeButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.mobilizeButton attribute:NSLayoutAttributeRight multiplier:1 constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.addButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.addButton attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    
    [self tintButtonsWithColor:[UIColor darkGrayColor]];

    [self.view addSubview:self.toolbar];
    
    NSDictionary *views = @{@"toolbar": self.toolbar,
                            @"background": self.statusBarBackgroundView,
                            @"show": self.showToolbarAndTitleBarHiddenView,
                            @"webview": self.webView };

    // Setup auto-layout constraints
    [self.view lhs_addConstraints:@"H:|[background]|" views:views];
    [self.view lhs_addConstraints:@"H:|[toolbar]|" views:views];
    [self.view lhs_addConstraints:@"H:|[webview]|" views:views];
    [self.view lhs_addConstraints:@"H:|[show]|" views:views];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.showToolbarAndTitleBarHiddenView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.webView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view lhs_addConstraints:@"V:[show(20)]" views:views];
    
    NSDictionary *metrics = @{@"height": @(kToolbarHeight)};
    [self.view lhs_addConstraints:@"V:|[background][webview][toolbar(>=height)]" metrics:metrics views:views];
    
    self.toolbarConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.toolbar attribute:NSLayoutAttributeTop multiplier:1 constant:kToolbarHeight];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.toolbar attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:self.toolbarConstraint];

    self.topLayoutConstraint = [self.statusBarBackgroundView lhs_setHeight:0];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        // Get the coordinates of the selected element
        CGPoint webViewCoordinates = [recognizer locationInView:self.webView];
        CGSize viewSize = self.webView.frame.size;
        CGFloat webViewContentWidth = [[self.webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
        CGFloat scaleRatio = webViewContentWidth / viewSize.width;
        webViewCoordinates.x = webViewCoordinates.x * scaleRatio;
        webViewCoordinates.y = webViewCoordinates.y * scaleRatio;
        
        // We were getting multiple gesture notifications, so make sure we only process one
        if (self.selectedActionSheetIsVisible) {
            return;
        }
        
        // Search the DOM for the link - will just return immediately if there is an A element at our exact coordinates
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"PINBOARD_ACTIVE_ELEMENT = PINBOARD_CLOSEST_LINK_AT(%f, %f)", webViewCoordinates.x, webViewCoordinates.y]];
        NSString *locatorString = @"PINBOARD_ACTIVE_ELEMENT.nodeName";
        
        // Only process link elements any further
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.nodeName";
        if (![[self.webView stringByEvaluatingJavaScriptFromString:locatorString] isEqualToString:@"A"]) {
            return;
        }
        
        // Parse the link and title into an NSDictionary
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.innerText";
        NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:locatorString];
        locatorString = @"PINBOARD_ACTIVE_ELEMENT.href";
        NSString *url = [self.webView stringByEvaluatingJavaScriptFromString:locatorString];
        self.selectedLink = @{ @"url": url, @"title": title };
        
        // Show the context menu
        self.selectedActionSheet = [[UIActionSheet alloc] initWithTitle:url delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add to Pinboard", nil), NSLocalizedString(@"Copy URL", nil), nil];
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

            [self.backActionSheet addButtonWithTitle:@"← Back"];
            [self.backActionSheet addButtonWithTitle:@"Cancel"];
            self.backActionSheet.cancelButtonIndex = self.backActionSheet.numberOfButtons - 1;
            [self.backActionSheet showInView:self.toolbar];
        }
    }
    else if (recognizer == self.tapGestureRecognizer || recognizer == self.bottomTapGestureRecognizer) {
        if (self.webView.scrollView.scrollsToTop && self.webView.scrollView.scrollEnabled) {
            [self showToolbarAnimated:YES];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // Determine if we should mobilize or not
    if (self.shouldMobilize && ![self.mobilizerUtility isURLMobilized:self.url]) {
        self.urlString = [self.mobilizerUtility urlStringForMobilizerForURL:self.url];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:YES];

    if (!self.alreadyLoaded) {
        [self loadURL];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.webView stopLoading];
    
    if ([UIApplication sharedApplication].statusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)stopLoading {
    self.stopped = YES;
    [self.webView stopLoading];
}

- (void)loadURL {
    self.stopped = NO;
    
    self.title = self.urlString;
    self.titleLabel.text = self.url.host;

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)enableOrDisableButtons {
    self.stopButton.hidden = YES;

    if (self.numberOfRequestsInProgress <= 0) {
        self.alreadyLoaded = YES;
        
        self.addButton.enabled = YES;
        self.editButton.enabled = YES;
        self.actionButton.enabled = YES;
        self.mobilizeButton.enabled = YES;

        NSString *theURLString = [self.mobilizerUtility originalURLStringForURL:self.url];

        if (theURLString) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                FMResultSet *results = [db executeQuery:@"SELECT COUNT(*), unread FROM bookmark WHERE url=?" withArgumentsInArray:@[theURLString]];
                [results next];
                BOOL bookmarkExists = [results intForColumnIndex:0] > 0;
                BOOL isRead = ![results boolForColumnIndex:1];
                [db close];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.rightBarButtonItem = nil;

                    if (bookmarkExists) {
                        self.editButton.hidden = NO;
                        self.addButton.hidden = YES;
                    }
                    else {
                        self.editButton.hidden = YES;
                        self.addButton.hidden = NO;
                    }

                    self.markAsReadButton.enabled = !isRead;
                });
            });
        }
    }
}

- (void)backButtonTouchUp:(id)sender {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)forwardButtonTouchUp:(id)sender {
    [self.webView goForward];
}

- (void)actionButtonTouchUp:(id)sender {
    // Browsers
    NSMutableArray *browserActivites = [NSMutableArray array];
    PPBrowserActivity *browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"http" browser:@"Safari"];
    [browserActivity setUrlString:[self.mobilizerUtility originalURLStringForURL:self.url]];
    [browserActivites addObject:browserActivity];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"icabmobile" browser:@"iCab Mobile"];
        [browserActivites addObject:browserActivity];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"googlechrome" browser:@"Chrome"];
        [browserActivites addObject:browserActivity];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ohttp://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"ohttp" browser:@"Opera"];
        [browserActivites addObject:browserActivity];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dolphin://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"dolphin" browser:@"Dolphin"];
        [browserActivites addObject:browserActivity];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cyber://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"cyber" browser:@"Cyberspace"];
        [browserActivites addObject:browserActivity];
    }

    
    // Read later
    NSMutableArray *readLaterActivities = [NSMutableArray array];
    PPReadLaterType readLater = [AppDelegate sharedDelegate].readLater;
    
    // Always include the native Reading List
    PPReadLaterActivity *nativeReadLaterActivity = [[PPReadLaterActivity alloc] initWithService:PPReadLaterNative];
    nativeReadLaterActivity.delegate = self;
    [readLaterActivities addObject:nativeReadLaterActivity];

    // If they have a third-party read later service configured, add it too
    if (readLater != PPReadLaterNone) {
        PPReadLaterActivity *readLaterActivity = [[PPReadLaterActivity alloc] initWithService:readLater];
        readLaterActivity.delegate = self;
        [readLaterActivities addObject:readLaterActivity];
    }
    
    NSString *title = NSLocalizedString(@"\r\nShared via Pinboard", nil);
    NSString *tempUrl = [self.mobilizerUtility originalURLStringForURL:self.url];
    NSURL *url = [NSURL URLWithString:tempUrl];
    
    NSMutableArray *allActivities = [NSMutableArray arrayWithArray:readLaterActivities];
    [allActivities addObjectsFromArray:browserActivites];
    
    NSArray *activityItems = [NSArray arrayWithObjects:url, title, nil];
    self.activityView = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:allActivities];
    self.activityView.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypePostToVimeo, UIActivityTypeAddToReadingList];
    
    __weak id weakself = self;
    self.activityView.completionHandler = ^(NSString *activityType, BOOL completed) {
        [weakself setNeedsStatusBarAppearanceUpdate];
    };
    
    [self presentViewController:self.activityView animated:YES completion:nil];
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
        if (buttonIndex < actionSheet.numberOfButtons - 2) {
            NSInteger i=0;
            while (i<buttonIndex+1) {
                [self.webView goBack];
                i++;
            }
        }
        else if (buttonIndex == actionSheet.numberOfButtons - 2) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)sendToReadLater {
    // Send to the default read later service
    [self sendToReadLater:[AppDelegate sharedDelegate].readLater];
}

- (void)sendToReadLater:(PPReadLaterType)service {
    if (self.activityView) {
        [self.activityView dismissViewControllerAnimated:YES completion:nil];
    }

    NSString *tempUrl = [self.mobilizerUtility originalURLStringForURL:self.url];
    
    switch (service) {
        case PPReadLaterInstapaper: {
            KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
            NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
            NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/bookmarks/add"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
            OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            NSMutableArray *parameters = [[NSMutableArray alloc] init];
            [parameters addObject:[OARequestParameter requestParameter:@"url" value:tempUrl]];
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
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                       }
                                       else if (httpResponse.statusCode == 1221) {
                                           notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       else {
                                           notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                   }];
            break;
        }
            
        case PPReadLaterReadability: {
            KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
            NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
            NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
            OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            [request setParameters:@[[OARequestParameter requestParameter:@"url" value:_urlString]]];
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
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                       }
                                       else if (httpResponse.statusCode == 409) {
                                           notification.alertBody = @"Link already sent to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       else {
                                           notification.alertBody = @"Error sending to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                   }];
            break;
        }
            
        case PPReadLaterPocket:
            [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:_urlString]
                                 withTitle:self.title
                                   handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                       if (!error) {
                                           UILocalNotification *notification = [[UILocalNotification alloc] init];
                                           notification.alertBody = @"Sent to Pocket.";
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                           
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                       }
                                   }];
            break;
            
        case PPReadLaterNative: {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertAction = @"Open Pushpin";
            
            // Add to the native Reading List
            NSError *error;
            [[SSReadingList defaultReadingList] addReadingListItemWithURL:self.url title:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"] previewText:nil error:&error];
            if (error) {
                notification.alertBody = @"Error adding to Reading List";
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
            } else {
                notification.alertBody = @"Added to Reading List";
                notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
            }
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Native Reading List"}];
            break;
        }
            
        default:
            break;
    }
}

- (void)toggleMobilizer {
    if ([self.mobilizerUtility canMobilizeURL:self.url]) {
        self.mobilized = !self.mobilized;
        self.mobilizeButton.selected = self.mobilized;

        NSURL *url;
        if (self.mobilized) {
            url = [NSURL URLWithString:[self.mobilizerUtility urlStringForMobilizerForURL:self.url]];
        }
        else {
            url = [NSURL URLWithString:[self.mobilizerUtility originalURLStringForURL:self.url]];
        }

        self.title = self.urlString;

        NSString *previousURLString = [self.history lastObject][@"url"];
        if ([previousURLString isEqualToString:url.absoluteString]) {
            [self.history removeLastObject];
            [self.webView goBack];
        }
        else {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    }
}

- (void)emailURL {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setMessageBody:[self.mobilizerUtility originalURLStringForURL:self.url] isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)copyURL {
    [self copyURL:self.url];
}

- (void)copyURL:(NSURL *)url {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self.mobilizerUtility originalURLStringForURL:url]];
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
        @"url": [self.mobilizerUtility originalURLStringForURL:self.url]
    };
    [self showAddViewController:post];
}

- (void)showAddViewController:(NSDictionary *)data {
    PPNavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:data update:@(NO) callback:nil];
    
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *editUrlString = [self.mobilizerUtility originalURLStringForURL:self.url];
        if (editUrlString) {
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[editUrlString]];
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
                PPNavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) callback:nil];
                
                if ([UIApplication isIPad]) {
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                }

                [self presentViewController:vc animated:YES completion:nil];
            });
        }
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

+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    NSString *urlString;
    if (![webViewController.mobilizerUtility isURLMobilized:[NSURL URLWithString:url]] && [webViewController.mobilizerUtility canMobilizeURL:[NSURL URLWithString:url]]) {
        urlString = [webViewController.mobilizerUtility urlStringForMobilizerForURL:[NSURL URLWithString:url]];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.toolbarConstraint.constant > kToolbarHeight / 2.) {
        self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y;
        [self showToolbarAnimated:YES];
    }
    else {
        [self hideToolbarAnimated:NO];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.webView.scrollView.contentOffset.y + CGRectGetHeight(self.webView.frame) > self.webView.scrollView.contentSize.height - kToolbarHeight) {
        self.showToolbarAndTitleBarHiddenView.userInteractionEnabled = NO;
    }
    else {
        self.showToolbarAndTitleBarHiddenView.userInteractionEnabled = YES;
    }

    CGPoint currentContentOffset = scrollView.contentOffset;
    self.previousContentOffset = currentContentOffset;

    CGFloat height = kToolbarHeight - ABS(currentContentOffset.y - self.yOffsetToStartShowingToolbar);
    self.toolbarConstraint.constant = MAX(0, height);
    [self.view layoutIfNeeded];
    
    if (self.toolbarConstraint.constant <= 0) {
        self.yOffsetToStartShowingToolbar = 0;
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    self.yOffsetToStartShowingToolbar = scrollView.contentOffset.y;

    if (self.toolbarConstraint.constant == kToolbarHeight) {
        return YES;
    }

    [self showToolbarAnimated:YES];
    return NO;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([@[@"http", @"https"] containsObject:request.URL.scheme] || [request.URL.scheme isEqualToString:@"about"]) {
        self.numberOfRequestsCompleted = 0;
        self.numberOfRequests = 0;

        self.markAsReadButton.enabled = NO;
        self.addButton.enabled = NO;
        self.editButton.enabled = NO;
        self.actionButton.enabled = NO;
        self.mobilizeButton.enabled = NO;
        
        switch (navigationType) {
            case UIWebViewNavigationTypeOther:
                break;
                
            case UIWebViewNavigationTypeReload:
                break;
                
            case UIWebViewNavigationTypeBackForward:
                // We've disabled forward in the UI, so it must be a pop of the stack.
                [self.history removeLastObject];
                
            default:
                webView.scrollView.contentOffset = CGPointMake(0, 0);
                webView.scrollView.scrollEnabled = NO;
                webView.scrollView.scrollsToTop = NO;
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.numberOfRequestsCompleted++;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.numberOfRequestsCompleted++;
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

    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];

    // Disable the default action sheet
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"webview-helpers" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil]];

    if (self.webView.scrollView.contentSize.height > CGRectGetHeight(self.webView.frame)) {
        self.webView.scrollView.scrollEnabled = YES;
        self.webView.scrollView.scrollsToTop = YES;
    }

    if (self.numberOfRequestsInProgress == 0) {
        [self updateInterfaceWithComputedWebPageBackgroundColor];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.webViewTimeoutTimer invalidate];
    self.webViewTimeoutTimer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(webViewLoadTimedOut) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.webViewTimeoutTimer forMode:NSRunLoopCommonModes];

    self.numberOfRequests++;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [self enableOrDisableButtons];
}

- (void)webViewLoadTimedOut {
    [self updateInterfaceWithComputedWebPageBackgroundColor];
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
    if (self.webView.scrollView.contentOffset.y == 0) {
        [self showToolbarAnimated:NO];
    }
    
    self.prefersStatusBarHidden = NO;
    
    if (self.webView.scrollView.contentSize.height > CGRectGetHeight(self.webView.frame)) {
        self.webView.scrollView.scrollEnabled = YES;
        self.webView.scrollView.scrollsToTop = YES;
    }
    
    NSString *response = [self.webView stringByEvaluatingJavaScriptFromString:@"window.getComputedStyle(document.body, null).getPropertyValue(\"background-color\")"];

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
        BOOL isDark = ((newR * 255 * 299) + (newG * 255 * 587) + (newB * 255 * 114)) / 1000 < 125;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                UIColor *backgroundColor = [UIColor colorWithRed:newR green:newG blue:newB alpha:1];
                self.statusBarBackgroundView.backgroundColor = backgroundColor;
                self.toolbarBackgroundView.backgroundColor = backgroundColor;
                
                if (isDark) {
                    [self tintButtonsWithColor:[UIColor whiteColor]];
                    self.titleLabel.textColor = [UIColor whiteColor];
                    self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
                }
                else {
                    [self tintButtonsWithColor:HEX(0x808D96FF)];
                    self.titleLabel.textColor = [UIColor darkTextColor];
                    self.preferredStatusBarStyle = UIStatusBarStyleDefault;
                }

                [self setNeedsStatusBarAppearanceUpdate];
            }];
        });
    }
}

- (void)tintButtonsWithColor:(UIColor *)color {
    self.actionButton.tintColor = color;
    self.backButton.tintColor = color;
    self.editButton.tintColor = color;
    self.addButton.tintColor = color;
    self.stopButton.tintColor = color;
    self.mobilizeButton.tintColor = color;
    self.markAsReadButton.tintColor = color;
}

- (BOOL)canMobilizeCurrentURL {
    return [self.mobilizerUtility canMobilizeURL:self.url];
}

- (void)showToolbarAnimated:(BOOL)animated {
    void (^ShowToolbarBlock)() = ^{
        self.toolbarConstraint.constant = kToolbarHeight;
        [self.view layoutIfNeeded];
    };

    if (animated) {
        if (self.webView.scrollView.contentOffset.y + CGRectGetHeight(self.webView.frame) > self.webView.scrollView.contentSize.height - kToolbarHeight) {
            [self.webView.scrollView setContentOffset:CGPointMake(0, self.webView.scrollView.contentSize.height - kToolbarHeight - CGRectGetHeight(self.webView.frame)) animated:NO];
        }

        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.5
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             ShowToolbarBlock();
                         }
                         completion:nil];
    }
    else {
        ShowToolbarBlock();
    }
}

- (void)hideToolbarAnimated:(BOOL)animated {
    void (^HideToolbarBlock)() = ^{
        self.toolbarConstraint.constant = 0;
        [self.view layoutIfNeeded];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.5
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             HideToolbarBlock();
                         }
                         completion:nil];
    }
    else {
        HideToolbarBlock();
    }
}

@end

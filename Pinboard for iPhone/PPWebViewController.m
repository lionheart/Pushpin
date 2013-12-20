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

#import "NSString+URLEncoding2.h"
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <UIView+LHSAdditions.h>
#import <FMDB/FMDatabase.h>
#import <PocketAPI/PocketAPI.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>

static NSInteger kToolbarHeight = 44;
static NSInteger kTitleHeight = 40;
static CGFloat timeInterval = 3;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

@synthesize shouldMobilize, urlString;
@synthesize longPressGestureRecognizer;
@synthesize selectedLink, selectedActionSheet;

- (void)viewDidLayoutSubviews {
    self.topLayoutConstraint.constant = [self.topLayoutGuide length];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.yOffsetToStartShowingTitleView = 0;
    self.prefersStatusBarHidden = YES;
    self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    self.stopped = NO;
    self.history = [NSMutableArray array];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    
    self.statusBarBackgroundView = [[UIView alloc] init];
    self.statusBarBackgroundView.userInteractionEnabled = YES;
    self.statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusBarBackgroundView.backgroundColor = HEX(0x0096FFFF);
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
    
    // Long press gesture for custom menu
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.longPressGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.longPressGestureRecognizer];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityIndicator startAnimating];
    self.activityIndicator.frame = CGRectMake(0, 0, 30, 30);
    self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    self.toolbar = [[UIView alloc] init];
    self.toolbar.backgroundColor = HEX(0xEBF2F6FF);
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *toolbarBackground = [[UIView alloc] init];
    toolbarBackground.backgroundColor = HEX(0xEBF2F6FF);
    toolbarBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:toolbarBackground];
    
    self.bottomActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.bottomActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomActivityIndicator.hidesWhenStopped = YES;
    [self.bottomActivityIndicator startAnimating];
    [self.toolbar addSubview:self.bottomActivityIndicator];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];

    self.backButtonLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [self.backButtonLongPressGestureRecognizer addTarget:self action:@selector(gestureDetected:)];
    [self.backButton addGestureRecognizer:self.backButtonLongPressGestureRecognizer];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:self.backButton];

    self.markAsReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.markAsReadButton setImage:[UIImage imageNamed:@"mark-as-read"] forState:UIControlStateNormal];
    [self.markAsReadButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    self.markAsReadButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.markAsReadButton.enabled = NO;
    [self.toolbar addSubview:self.markAsReadButton];
    
    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stopButton addTarget:self action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.stopButton.hidden = YES;
    [self.toolbar addSubview:self.stopButton];
    
    self.viewMobilizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.viewMobilizeButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
    [self.viewMobilizeButton setImage:[UIImage imageNamed:@"mobilize"] forState:UIControlStateNormal];
    [self.viewMobilizeButton setImage:[UIImage imageNamed:@"mobilize-active"] forState:UIControlStateHighlighted];
    self.viewMobilizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.viewMobilizeButton.hidden = YES;
    self.viewMobilizeButton.enabled = NO;
    [self.toolbar addSubview:self.viewMobilizeButton];
    
    self.viewRawButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.viewRawButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
    [self.viewRawButton setImage:[UIImage imageNamed:@"mobilized"] forState:UIControlStateNormal];
    [self.viewRawButton setImage:[UIImage imageNamed:@"mobilized-active"] forState:UIControlStateHighlighted];
    self.viewRawButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.viewRawButton.hidden = YES;
    self.viewRawButton.enabled = NO;
    [self.toolbar addSubview:self.viewRawButton];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.enabled = NO;
    [self.toolbar addSubview:self.actionButton];
    
    self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editButton setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
    [self.editButton addTarget:self action:@selector(showEditViewController) forControlEvents:UIControlEventTouchUpInside];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editButton.enabled = NO;
    [self.toolbar addSubview:self.editButton];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(showAddViewController) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.hidden = YES;
    self.addButton.enabled = NO;
    [self.toolbar addSubview:self.addButton];
    
    UIView *toolbarBorderView = [[UIView alloc] init];
    toolbarBorderView.backgroundColor = HEX(0xb2b2b2ff);
    toolbarBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar addSubview:toolbarBorderView];
    
    self.titleView = [[UIView alloc] init];
    self.titleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.titleView addGestureRecognizer:self.tapGestureRecognizer];
    [self.view addSubview:self.titleView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.5;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    [self.titleView addSubview:self.titleLabel];
    [self.titleView lhs_centerHorizontallyForView:self.titleLabel];
    [self.titleView lhs_centerVerticallyForView:self.titleLabel];
    [self.titleView lhs_addConstraints:@"H:|-15-[label]-15-|" views:@{@"label": self.titleLabel}];
    
    NSDictionary *toolbarViews = @{@"back": self.backButton,
                                   @"indicator": self.bottomActivityIndicator,
                                   @"read": self.markAsReadButton,
                                   @"raw": self.viewRawButton,
                                   @"mobilize": self.viewMobilizeButton,
                                   @"action": self.actionButton,
                                   @"edit": self.editButton,
                                   @"stop": self.stopButton,
                                   @"add": self.addButton,
                                   @"background": toolbarBackground,
                                   @"border": toolbarBorderView };

    [self.toolbar lhs_addConstraints:@"H:|[back][read(==back)][stop(==back)][edit(==back)][action(==back)]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"H:|[background]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[background(height)]" metrics:@{@"height": @(kToolbarHeight + 60)} views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[back]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[raw]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[mobilize]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[action]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[edit]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[stop]|" views:toolbarViews];
    [self.toolbar lhs_addConstraints:@"V:|[add]|" views:toolbarViews];
    
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.stopButton attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.bottomActivityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.viewRawButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.viewMobilizeButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.bottomActivityIndicator attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.viewRawButton attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.viewMobilizeButton attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.stopButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bottomActivityIndicator attribute:NSLayoutAttributeRight multiplier:1 constant:0]];

    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.addButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.toolbar addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.addButton attribute:NSLayoutAttributeRight multiplier:1 constant:0]];

    [self.view addSubview:self.toolbar];
    
    NSDictionary *views = @{@"toolbar": self.toolbar,
                            @"title": self.titleView,
                            @"background": self.statusBarBackgroundView,
                            @"webview": self.webView };

    // Setup auto-layout constraints
    [self.view lhs_addConstraints:@"H:|[background]|" views:views];
    [self.view lhs_addConstraints:@"H:|[toolbar]|" views:views];
    [self.view lhs_addConstraints:@"H:|[webview]|" views:views];
    [self.view lhs_addConstraints:@"H:|[title]|" views:views];
    
    NSDictionary *metrics = @{@"height": @(kToolbarHeight)};
    [self.view lhs_addConstraints:@"V:|[background][title][webview][toolbar(>=height)]" metrics:metrics views:views];
    
    self.toolbarConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.toolbar attribute:NSLayoutAttributeTop multiplier:1 constant:kToolbarHeight];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.toolbar attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:self.toolbarConstraint];
    
    self.titleHeightConstraint = [NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:kToolbarHeight];
    [self.view addConstraint:self.titleHeightConstraint];
    
    self.topLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.statusBarBackgroundView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:0];
    [self.view addConstraint:self.topLayoutConstraint];
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
    else if (recognizer == self.tapGestureRecognizer) {
        self.yOffsetToStartShowingTitleView = self.webView.scrollView.contentOffset.y;

        [UIView animateWithDuration:0.2
                         animations:^{
                             self.titleHeightConstraint.constant = kTitleHeight;
                             self.toolbarConstraint.constant = kToolbarHeight;
                             [self.view layoutIfNeeded];
                         }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
    // Determine if we should mobilize or not
    if (self.shouldMobilize && ![self isURLStringMobilized:self.urlString]) {
        NSString *mobilizedUrlString;

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

    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)enableOrDisableButtons {
    self.stopButton.hidden = YES;
    self.viewMobilizeButton.hidden = YES;
    self.viewRawButton.hidden = YES;

    if (self.numberOfRequestsInProgress > 0) {
        self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem;
        [self.bottomActivityIndicator startAnimating];
    }
    else {
        self.alreadyLoaded = YES;
        [self.bottomActivityIndicator stopAnimating];
        
        self.addButton.enabled = YES;
        self.editButton.enabled = YES;
        self.actionButton.enabled = YES;
        self.viewMobilizeButton.enabled = YES;
        self.viewRawButton.enabled = YES;

        NSString *theURLString = [self urlStringForDemobilizedURL:self.url];

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

                    if (self.isMobilized) {
                        self.viewRawButton.hidden = NO;
                    }
                    else {
                        self.viewMobilizeButton.hidden = NO;

                        if (![self canMobilizeCurrentURL]) {
                            self.viewMobilizeButton.enabled = NO;
                        }
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
    [browserActivity setUrlString:[self urlStringForDemobilizedURL:self.url]];
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
    NSInteger readLaterSetting = [[[AppDelegate sharedDelegate] readlater] integerValue];
    
    // Always include the native Reading List
    PPReadLaterActivity *nativeReadLaterActivity = [[PPReadLaterActivity alloc] initWithService:READLATER_NATIVE];
    nativeReadLaterActivity.delegate = self;
    [readLaterActivities addObject:nativeReadLaterActivity];

    // If they have a third-party read later service configured, add it too
    if (readLaterSetting > READLATER_NONE) {
        PPReadLaterActivity *readLaterActivity = [[PPReadLaterActivity alloc] initWithService:readLaterSetting];
        readLaterActivity.delegate = self;
        [readLaterActivities addObject:readLaterActivity];
    }
    
    NSString *title = NSLocalizedString(@"\r\nShared via Pinboard", nil);
    NSString *tempUrl = [self urlStringForDemobilizedURL:self.url];
    NSURL *url = [NSURL URLWithString:tempUrl];
    
    NSMutableArray *allActivities = [NSMutableArray arrayWithArray:readLaterActivities];
    [allActivities addObjectsFromArray:browserActivites];
    
    NSArray *activityItems = [NSArray arrayWithObjects:url, title, nil];
    self.activityView = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:allActivities];
    self.activityView.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypePostToVimeo, UIActivityTypeAddToReadingList];
    
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
    [self sendToReadLater:[[AppDelegate sharedDelegate] readlater]];
}

- (void)sendToReadLater:(NSNumber *)service {
    if (self.activityView) {
        [self.activityView dismissViewControllerAnimated:YES completion:nil];
    }

    NSString *tempUrl = [self urlStringForDemobilizedURL:self.url];
    if (service.integerValue == READLATER_INSTAPAPER) {
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
    else if (service.integerValue == READLATER_READABILITY) {
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
    else if (service.integerValue == READLATER_POCKET) {
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
    else if (service.integerValue == READLATER_NATIVE) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertAction = @"Open Pushpin";
        
        // Add to the native Reading List
        NSError *error;
        [[SSReadingList defaultReadingList] addReadingListItemWithURL:self.url title:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"] previewText:nil error:&error];
        if (error) {
            notification.alertBody = @"Error adding to Reading List";
            notification.userInfo = @{@"success": @NO, @"updated": @NO};
        } else {
            notification.alertBody = @"Added to Reading List";
            notification.userInfo = @{@"success": @YES, @"updated": @NO};
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Native Reading List"}];
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
    [self copyURL:self.url];
}

- (void)copyURL:(NSURL *)url {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self urlStringForDemobilizedURL:url]];
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
        @"url": [self urlStringForDemobilizedURL:self.url]
    };
    [self showAddViewController:post];
}

- (void)showAddViewController:(NSDictionary *)data {
    PPNavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:data update:@(NO) delegate:self callback:nil];
    
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *editUrlString = [self urlStringForDemobilizedURL:self.url];
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
    if (![webViewController isURLStringMobilized:url] && [webViewController canMobilizeURL:[NSURL URLWithString:url]]) {
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < self.yOffsetToStartShowingTitleView) {
        self.yOffsetToStartShowingTitleView = 0;
    }

    // This is the scrollView's content offset PLUS the amount that the title bar has been shrunk
    CGFloat effectiveOffset = scrollView.contentOffset.y + kTitleHeight - self.titleHeightConstraint.constant;
    
    // Scroll Distance from Y Threshold. Greater than zero -> increase title view size.
    CGFloat distanceFromYThreshold = effectiveOffset - self.yOffsetToStartShowingTitleView;

    // This value is negative if the scroll view is above the threshold to show the view.
    BOOL shouldUpdateViewConstants = distanceFromYThreshold >= 0;
    if (shouldUpdateViewConstants) {
        self.titleHeightConstraint.constant = MAX(22, kTitleHeight - distanceFromYThreshold);
        self.toolbarConstraint.constant = MAX(0, kToolbarHeight - distanceFromYThreshold);
        [self.view layoutIfNeeded];
    }
    
    BOOL titleViewIsExpanded = self.titleHeightConstraint.constant > 22;
    if (titleViewIsExpanded) {
        // If the title view isn't the minimum size, don't actually scroll the webview.
        // We do this by resetting the offset.
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, self.yOffsetToStartShowingTitleView);
    }
    else if (scrollView.contentOffset.y < 0) {
        // If the title view is minimized, and the user is scrolling up at the top of the view, we just need to give it a little push
        self.titleHeightConstraint.constant = MAX(22, MIN(kTitleHeight, self.titleHeightConstraint.constant - scrollView.contentOffset.y));
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
        [self.view layoutIfNeeded];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if (self.titleHeightConstraint.constant == kTitleHeight) {
        self.yOffsetToStartShowingTitleView = 0;
        return YES;
    }

    self.yOffsetToStartShowingTitleView = scrollView.contentOffset.y;
    
    // Show the title and toolbar if the user taps the toolbar and it's not already showing
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.toolbarConstraint.constant = kToolbarHeight;
                         self.titleHeightConstraint.constant = kTitleHeight;
                         [self.view layoutIfNeeded];
                     }];
    return NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.toolbarHideTimer invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.toolbarHideTimer invalidate];
    self.toolbarHideTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(hideToolbar) userInfo:nil repeats:NO];
//    [[NSRunLoop mainRunLoop] addTimer:self.toolbarHideTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.numberOfRequestsCompleted = 0;
    self.numberOfRequests = 0;
    
    self.markAsReadButton.enabled = NO;
    self.addButton.enabled = NO;
    self.editButton.enabled = NO;
    self.actionButton.enabled = NO;
    self.viewMobilizeButton.enabled = NO;
    self.viewRawButton.enabled = NO;

    switch (navigationType) {
        case UIWebViewNavigationTypeBackForward:
            // We've disabled forward in the UI, so it must be a pop of the stack.
            [self.history removeLastObject];
            break;

        default:
            break;
    }
    
    return YES;
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
    
    if (self.numberOfRequestsInProgress == 0) {
        self.toolbarHideTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(hideToolbar) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.toolbarHideTimer forMode:NSRunLoopCommonModes];
        
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
            BOOL isDark = ((newR * 255 * 299) + (newG * 255 * 587) + (newB * 255 * 114)) / 1000 < 125;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    self.statusBarBackgroundView.backgroundColor = [UIColor colorWithRed:R green:G blue:B alpha:alpha];
                    self.titleView.backgroundColor = [UIColor colorWithRed:R green:G blue:B alpha:alpha];
                    
                    self.prefersStatusBarHidden = NO;
                    if (isDark) {
                        self.titleLabel.textColor = [UIColor lightTextColor];
                        self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
                    }
                    else {
                        self.titleLabel.textColor = [UIColor darkTextColor];
                        self.preferredStatusBarStyle = UIStatusBarStyleDefault;
                    }

                    [self setNeedsStatusBarAppearanceUpdate];
                }];
            });
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.toolbarHideTimer invalidate];

    self.numberOfRequests++;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [self enableOrDisableButtons];
}

- (BOOL)canMobilizeCurrentURL {
    return [self canMobilizeURL:self.url];
}

- (BOOL)canMobilizeURL:(NSURL *)url {
    NSArray *hosts = @[@"twitter.com", @"mobile.twitter.com"];
    for (NSString *host in hosts) {
        if ([url.host isEqualToString:host]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Utils

- (void)hideToolbar {
    if ([UIApplication currentSize].height < self.webView.scrollView.contentSize.height) {
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionCalculationModeCubic
                                  animations:^{
                                      [UIView addKeyframeWithRelativeStartTime:0
                                                              relativeDuration:0.8
                                                                    animations:^{
                                                                        self.toolbarConstraint.constant = kToolbarHeight + 10;
                                                                        [self.view layoutIfNeeded];
                                                                    }];
                                      
                                      [UIView addKeyframeWithRelativeStartTime:0.8
                                                              relativeDuration:0.2
                                                                    animations:^{
                                                                        self.toolbarConstraint.constant = 0;
                                                                        [self.view layoutIfNeeded];
                                                                    }];
                                  }
                                  completion:nil];
    }
}

- (void)showToolbar {
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                     }];
}

@end

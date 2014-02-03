//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "NoteViewController.h"
#import "LoginViewController.h"
#import "SettingsViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PPNotification.h"
#import "FeedListViewController.h"
#import "AddBookmarkViewController.h"
#import "PPWebViewController.h"
#import "PPToolbar.h"
#import "PinboardFeedDataSource.h"
#import "PPMultipleEditViewController.h"
#import "PPNavigationController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "ScreenshotViewController.h"
#import "PPStatusBarNotification.h"
#import "PPMobilizerUtility.h"
#import "PPSplitViewController.h"
#import "PPStatusBar.h"
#import "DeliciousDataSource.h"

#import <LHDelicious/LHDelicious.h>
#import <ASPinboard/ASPinboard.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <Reachability/Reachability.h>
#import <HTMLParser/HTMLParser.h>
#import <PocketAPI/PocketAPI.h>
#import <TestFlightSDK/TestFlight.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>

@interface AppDelegate ()

@property (nonatomic, strong) UIAlertView *updateBookmarkAlertView;
@property (nonatomic, strong) UIAlertView *addBookmarkAlertView;
@property (nonatomic, strong) NSURLCache *urlCache;

@end

@implementation AppDelegate

@synthesize splitViewController = _splitViewController;
@synthesize readLater = _readLater;
@synthesize token = _token;
@synthesize browser = _browser;
@synthesize mobilizer = _mobilizer;
@synthesize onlyPromptToAddOnce = _onlyPromptToAddOnce;
@synthesize lastUpdated = _lastUpdated;
@synthesize privateByDefault = _privateByDefault;
@synthesize dimReadPosts = _dimReadPosts;
@synthesize markReadPosts = _markReadPosts;
@synthesize enableAutoCorrect = _enableAutoCorrect;
@synthesize enableAutoCapitalize = _enableAutoCapitalize;
@synthesize feedToken = _feedToken;
@synthesize readByDefault = _readByDefault;
@synthesize defaultFeed = _defaultFeed;
@synthesize openLinksInApp = _openLinksInApp;
@synthesize compressPosts = _compressPosts;
@synthesize openLinksWithMobilizer = _openLinksWithMobilizer;
@synthesize doubleTapToEdit = _doubleTapToEdit;

+ (NSString *)databasePath {
#ifdef DELICIOUS
    NSString *pathComponent = @"/delicious.db";
#endif
    
#ifdef PINBOARD
    NSString *pathComponent = @"/pinboard.db";
#endif

#if TARGET_IPHONE_SIMULATOR
    return [@"/tmp" stringByAppendingString:pathComponent];
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        return [paths[0] stringByAppendingPathComponent:pathComponent];
    }
    else {
        return pathComponent;
    }
#endif
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [application cancelAllLocalNotifications];
    if (application.applicationState == UIApplicationStateActive) {
        self.bookmarksUpdated = [notification.userInfo[@"updated"] boolValue];
        NSString *text = notification.alertBody;
        
        if ([notification.userInfo[@"success"] isEqual:@(YES)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PPStatusBar status] showWithText:text];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PPStatusBar status] showWithText:text];
            });
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    PPNavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark update:isUpdate callback:callback];

    if (self.navigationController.presentedViewController) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [self.navigationController presentViewController:addBookmarkViewController animated:NO completion:nil];
        }];
    }
    else {
        [self.navigationController presentViewController:addBookmarkViewController animated:NO completion:nil];
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }
    else if ([url.host isEqualToString:@"add"]) {
        didLaunchWithURL = YES;
        [self showAddBookmarkViewControllerWithBookmark:[self parseQueryParameters:url.query] update:@(NO) callback:nil];
    }
    else if ([url.host isEqualToString:@"feed"]) {
        NSDictionary *data = [self parseQueryParameters:url.query];
        NSMutableArray *components = [NSMutableArray array];
        if (data[@"user"]) {
            [components addObject:[NSString stringWithFormat:@"u:%@", data[@"user"]]];
        }
        
        if (data[@"tags"]) {
            for (NSString *tag in [data[@"tags"] componentsSeparatedByString:@","]) {
                if (![tag isEqualToString:@""]) {
                    [components addObject:[NSString stringWithFormat:@"t:%@", tag]];
                }
            }
        }

        GenericPostViewController *postViewController = [PinboardFeedDataSource postViewControllerWithComponents:components];
        postViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(closeModal:)];
        PPNavigationController *navController = [[PPNavigationController alloc] initWithRootViewController:postViewController];

        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self.navigationController presentViewController:navController animated:NO completion:nil];
            }];
        }
        else {
            [self.navigationController presentViewController:navController animated:NO completion:nil];
        }
    }
    else if ([url.host isEqualToString:@"x-callback-url"]) {
        didLaunchWithURL = YES;

        // Sync TextExpander snippets
        if ([url.path hasPrefix:@"/TextExpanderSettings"]) {
            SMTEDelegateController *teDelegetController = [[SMTEDelegateController alloc] init];
            BOOL cancel;
            NSError *error;
            BOOL response = [teDelegetController handleGetSnippetsURL:url
                                                                error:&error
                                                           cancelFlag:&cancel];

            NSString *message;
            if (error) {
                message = @"TextExpander snippet sync failed.";
            }
            else if (cancel) {
                message = @"TextExpander snippet sync cancelled.";
            }
            else {
                message = @"TextExpander snippets successfully updated.";
            }

            [[[UIAlertView alloc] initWithTitle:nil
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
            return response;
        }
        else if ([url.path isEqualToString:@"/add"]) {
            NSMutableDictionary *queryParameters = [self parseQueryParameters:url.query];
            [self showAddBookmarkViewControllerWithBookmark:queryParameters update:@(NO) callback:^{
                if (queryParameters[@"url"]) {
                    NSURL *url = [NSURL URLWithString:queryParameters[@"url"]];

                    if ([sourceApplication isEqualToString:@"com.google.chrome.ios"]) {
                        if ([url.scheme isEqualToString:@"http"]) {
                            url = [NSURL URLWithString:@"googlechrome://"];
                        }
                        else if ([url.scheme isEqualToString:@"https"]) {
                            url = [NSURL URLWithString:@"googlechromes://"];
                        }
                    }

                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
    }
    else if (url.host && ![url.host isEqualToString:@""]) {
        NSRange range = [url.absoluteString rangeOfString:@"pushpin"];
        NSString *urlString = [url.absoluteString stringByReplacingCharactersInRange:range withString:@"http"];
        PPWebViewController *webViewController;
        if (self.openLinksWithMobilizer) {
            webViewController = [PPWebViewController mobilizedWebViewControllerWithURL:urlString];
        }
        else {
            webViewController = [PPWebViewController webViewControllerWithURL:urlString];
        }

        webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(closeModal:)];
        PPNavigationController *navController = [[PPNavigationController alloc] initWithRootViewController:webViewController];
        
        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self.navigationController presentViewController:navController animated:NO completion:nil];
            }];
        }
        else {
            [self.navigationController presentViewController:navController animated:NO completion:nil];
        }
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.bookmarksNeedUpdate = YES;

    if (!didLaunchWithURL && self.token != nil) {
        [self promptUserToAddBookmark];
        didLaunchWithURL = NO;
    }
}

- (void)promptUserToAddBookmark {
    dispatch_async(dispatch_get_main_queue(), ^{
        // XXX EXC_BAD_ACCESS
        self.clipboardBookmarkURL = [UIPasteboard generalPasteboard].string;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!self.clipboardBookmarkURL || self.addBookmarkAlertView) {
                return;
            }
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.clipboardBookmarkURL]];
            [results next];
            BOOL alreadyExistsInBookmarks = [results intForColumnIndex:0] != 0;
            results = [db executeQuery:@"SELECT COUNT(*) FROM rejected_bookmark WHERE url=?" withArgumentsInArray:@[self.clipboardBookmarkURL]];
            [results next];
            BOOL alreadyRejected = [results intForColumnIndex:0] != 0;
            [db close];

            if (alreadyExistsInBookmarks) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Pushpin detected a link in your clipboard for an existing bookmark. Would you like to edit it?", nil), self.clipboardBookmarkURL];
                    self.updateBookmarkAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                              message:message
                                                                             delegate:self
                                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                    otherButtonTitles:NSLocalizedString(@"Edit", nil), nil];
                    [self.updateBookmarkAlertView show];
                });
            }
            else if (alreadyRejected && self.onlyPromptToAddOnce) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = @"Reset URL cache in advanced settings to add this bookmark.";
                    notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                });
            }
            else {
                NSURL *candidateURL = [NSURL URLWithString:self.clipboardBookmarkURL];
                if (candidateURL && candidateURL.scheme && candidateURL.host) {
                    [[AppDelegate sharedDelegate] retrievePageTitle:candidateURL
                                                           callback:^(NSString *title, NSString *description) {
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   self.clipboardBookmarkTitle = title;

                                                                   NSString *message = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"We've detected a URL in your clipboard. Would you like to bookmark it?", nil), self.clipboardBookmarkURL];
                                                                   self.addBookmarkAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                                                                          message:message
                                                                                                                         delegate:self
                                                                                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                                                                otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
                                                                   [self.addBookmarkAlertView show];
                                                               });
                                                               [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                                           }];
                    
                }
            }
        });
    });
}

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query {
    // Parse the individual parameters
    // parameters = @"hello=world&foo=bar";
    NSMutableDictionary *dictParameters = [[NSMutableDictionary alloc] initWithDictionary:@{@"url": @"", @"title": @"", @"description": @"", @"tags": @"", @"private": @(self.privateByDefault), @"unread": @(!self.readByDefault) }];
    NSArray *arrParameters = [query componentsSeparatedByString:@"&"];
    for (int i = 0; i < [arrParameters count]; i++) {
        NSArray *arrKeyValue = [[arrParameters objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([arrKeyValue count] >= 2) {
            NSMutableString *strKey = [NSMutableString stringWithCapacity:0];
            [strKey setString:[[[arrKeyValue objectAtIndex:0] lowercaseString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
            NSMutableString *strValue   = [NSMutableString stringWithCapacity:0];
            [strValue setString:[[[arrKeyValue objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
            if (strKey.length > 0) [dictParameters setObject:strValue forKey:strKey];
        }
    }
    return dictParameters;
}

- (void)openSettings {
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)customizeUIElements {
    //[self.window setTintColor:[UIColor whiteColor]];
    //[[UIView appearance] setTintColor:[UIColor whiteColor]];
    
    NSDictionary *normalAttributes = @{NSFontAttributeName: [PPTheme textLabelFont]};
    [[UIBarButtonItem appearance] setTitleTextAttributes:normalAttributes
                                                forState:UIControlStateNormal];
    
    // UIToolbar items
    UIColor *barButtonItemColor = [UIColor colorWithRed:40/255.0f green:141/255.0f blue:219/255.0f alpha:1.0f];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setTintColor:barButtonItemColor];
    
    [[UISwitch appearance] setOnTintColor:HEX(0x0096FFFF)];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0 green:0.5863 blue:1 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

- (PPSplitViewController *)splitViewController {
    if (!_splitViewController) {
        PPNavigationController *feedNavigationController = [[PPNavigationController alloc] initWithRootViewController:self.feedListViewController];

        _splitViewController = [[PPSplitViewController alloc] init];
        _splitViewController.viewControllers = @[feedNavigationController, self.navigationController];
        _splitViewController.delegate = self;
    }
    return _splitViewController;
}

- (FeedListViewController *)feedListViewController {
    if (!_feedListViewController) {
        _feedListViewController = [[FeedListViewController alloc] init];
    }
    return _feedListViewController;
}

- (PPNavigationController *)navigationController {
    if (!_navigationController) {
#ifdef DELICIOUS
        DeliciousDataSource *deliciousDataSource = [[DeliciousDataSource alloc] init];
        deliciousDataSource.limit = 100;
        deliciousDataSource.orderBy = @"created_at DESC";
        
        GenericPostViewController *deliciousViewController = [[GenericPostViewController alloc] init];
        deliciousViewController.postDataSource = deliciousDataSource;

        _navigationController = [[PPNavigationController alloc] init];
        
        if ([UIApplication isIPad]) {
            _navigationController.viewControllers = @[deliciousViewController];
        }
        else {
            _navigationController.viewControllers = @[self.feedListViewController, deliciousViewController];
        }
        
        [_navigationController popToViewController:deliciousViewController animated:NO];
#endif
        
#ifdef PINBOARD
        PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
        pinboardDataSource.limit = 100;
        pinboardDataSource.orderBy = @"created_at DESC";

        GenericPostViewController *pinboardViewController = [[GenericPostViewController alloc] init];
        
        _navigationController = [[PPNavigationController alloc] init];
        
        // Determine our default feed
        NSString *feedDetails;
        if ([[self.defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
            feedDetails = [self.defaultFeed substringFromIndex:9];
            
            PPPinboardPersonalFeedType feedType = [PPPersonalFeeds() indexOfObject:feedDetails];
            
            switch (feedType) {
                case PPPinboardPersonalFeedPrivate:
                    pinboardDataSource.isPrivate = kPushpinFilterTrue;
                    break;
                    
                case PPPinboardPersonalFeedPublic:
                    pinboardDataSource.isPrivate = kPushpinFilterFalse;
                    break;
                    
                case PPPinboardPersonalFeedUnread:
                    pinboardDataSource.unread = kPushpinFilterTrue;
                    break;
                    
                case PPPinboardPersonalFeedUntagged:
                    pinboardDataSource.untagged = YES;
                    break;
                    
                case PPPinboardPersonalFeedStarred:
                    pinboardDataSource.starred = kPushpinFilterTrue;
                    break;
                    
                default:
                    break;
            }

            pinboardViewController.postDataSource = pinboardDataSource;
        }
        else if ([[self.defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
            feedDetails = [self.defaultFeed substringFromIndex:10];
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] init];
            pinboardViewController.postDataSource = feedDataSource;
            
            PPPinboardCommunityFeedType feedType = [PPCommunityFeeds() indexOfObject:feedDetails];
            
            switch (feedType) {
                case PPPinboardCommunityFeedNetwork: {
                    NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                    NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                    feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", feedToken], [NSString stringWithFormat:@"u:%@", username], @"network"];
                    break;
                }
                    
                case PPPinboardCommunityFeedPopular:
                    feedDataSource.components = @[@"popular?count=100"];
                    break;
                    
                case PPPinboardCommunityFeedWikipedia:
                    feedDataSource.components = @[@"popular", @"wikipedia"];
                    break;
                    
                case PPPinboardCommunityFeedFandom:
                    feedDataSource.components = @[@"popular", @"fandom"];
                    break;
                    
                case PPPinboardCommunityFeedJapan:
                    feedDataSource.components = @[@"popular", @"japanese"];
                    break;
                    
                default:
                    break;
            }
        }
        else if ([[self.defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
            feedDetails = [self.defaultFeed substringFromIndex:6];
            NSArray *components = [feedDetails componentsSeparatedByString:@"+"];
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] initWithComponents:components];
            pinboardViewController.postDataSource = feedDataSource;
        }

        if ([UIApplication isIPad]) {
            _navigationController.viewControllers = @[pinboardViewController];
        }
        else {
            _navigationController.viewControllers = @[self.feedListViewController, pinboardViewController];
        }

        [_navigationController popToViewController:pinboardViewController animated:NO];
#endif
    }
    return _navigationController;
}

- (PPNavigationController *)loginViewController {
    if (!_loginViewController) {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        
        PPNavigationController *controller = [[PPNavigationController alloc] initWithRootViewController:loginViewController];
        controller.navigationBar.translucent = NO;
        
        _loginViewController = controller;
    }
    return _loginViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    application.applicationSupportsShakeToEdit = YES;
    [self becomeFirstResponder];
    self.bookmarksUpdated = NO;
    self.bookmarksUpdatedMessage = nil;
    self.addBookmarkAlertView = nil;
    self.updateBookmarkAlertView = nil;
    
    // 4 MB memory, 100 MB disk
    self.urlCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                  diskCapacity:100 * 1024 * 1024
                                                      diskPath:@"urlcache"];
    [NSURLCache setSharedURLCache:self.urlCache];

    [self migrateDatabase];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [self customizeUIElements];
    [TestFlight takeOff:PPTestFlightToken];
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:PPMixpanelToken];
    
    if ([UIApplication isIPad]) {
        [[PocketAPI sharedAPI] setConsumerKey:PPPocketIPadToken];
    }
    else {
        [[PocketAPI sharedAPI] setConsumerKey:PPPocketIPhoneToken];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{
        @"io.aurora.pinboard.OpenLinksInApp": @(YES),
        @"io.aurora.pinboard.PrivateByDefault": @(NO),
        @"io.aurora.pinboard.ReadByDefault": @(NO),
        @"io.aurora.pinboard.Browser": @(PPBrowserSafari),
        @"io.aurora.pinboard.CompressPosts": @(NO),
        @"io.aurora.pinboard.DimReadPosts": @(NO),
        @"io.aurora.pinboard.OpenLinksWithMobilizer": @(NO),
        @"io.aurora.pinboard.DoubleTapToEdit": @(NO),
        @"io.aurora.pinboard.FontName": @"HelveticaNeue-Medium",
        @"io.aurora.pinboard.BoldFontName": @"HelveticaNeue-Bold",
        
        // If a user decides not to add a bookmark when it's on the clipboard, don't ask again.
        @"io.aurora.pinboard.OnlyPromptToAddOnce": @(NO)
     }];

    Reachability *reach = [Reachability reachabilityForInternetConnection];
    self.connectionAvailable = [reach isReachable];
    reach.reachableBlock = ^(Reachability *reach) {
        self.connectionAvailable = YES;
    };

    reach.unreachableBlock = ^(Reachability *reach) {
        self.connectionAvailable = NO;
    };
    [reach startNotifier];
    
#ifdef DELICIOUS
    LHDelicious *delicious = [LHDelicious sharedInstance];
    [delicious setRequestCompletedCallback:^{
        [self setNetworkActivityIndicatorVisible:NO];
    }];

    [delicious setRequestStartedCallback:^{
        [self setNetworkActivityIndicatorVisible:NO];
    }];
#endif

#ifdef PINBOARD
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard setRequestCompletedCallback:^{
        [self setNetworkActivityIndicatorVisible:NO];
    }];
    [pinboard setRequestStartedCallback:^{
        [self setNetworkActivityIndicatorVisible:YES];
    }];
#endif

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    if (self.token) {
#ifdef PINBOARD
        [pinboard setToken:self.token];
#endif
        [mixpanel identify:self.username];
        [mixpanel.people set:@"$username" to:self.username];
        
        if ([UIApplication isIPad]) {
            [self.window setRootViewController:self.splitViewController];
        }
        else {
            [self.window setRootViewController:self.navigationController];
        }
    }
    else {
        [self.window setRootViewController:self.loginViewController];
    }

    [self.window makeKeyAndVisible];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    // Update iCloud so that the user gets credited for future updates.
    NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
    NSString *key = [NSString stringWithFormat:@"%@.DownloadedBeforeIAP", [[NSBundle mainBundle] bundleIdentifier]];
    if (store) {
        [store setBool:YES forKey:key];
        [store synchronize];
    }
    
    didLaunchWithURL = NO;
    return YES;
}

- (void)migrateDatabase {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    // http://stackoverflow.com/a/875422/39155
    [db executeUpdate:@"PRAGMA cache_size=100;"];

    // http://stackoverflow.com/a/875422/39155
    [db executeUpdate:@"PRAGMA syncronous=OFF;"];

    FMResultSet *s = [db executeQuery:@"PRAGMA user_version"];

#ifdef DELICIOUS
    if ([s next]) {
        int version = [s intForColumnIndex:0];
        [db beginTransaction];

        switch (version) {
            case 0:
                [db executeUpdate:
                 @"CREATE TABLE feeds("
                     "components TEXT UNIQUE,"
                     "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                 ");"];
                
                [db executeUpdate:
                 @"CREATE TABLE rejected_bookmark("
                     "url TEXT UNIQUE CHECK(length(url) < 2000),"
                     "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                 ");"];
                [db executeUpdate:@"CREATE INDEX rejected_bookmark_url_idx ON rejected_bookmark (url);"];

                [db executeUpdate:
                 @"CREATE TABLE bookmark("
                     "title TEXT,"
                     "description TEXT,"
                     "tags TEXT,"
                     "url TEXT,"
                     "count INTEGER,"
                     "private BOOL,"
                     "unread BOOL,"
                     "hash VARCHAR(32) UNIQUE,"
                     "meta VARCHAR(32),"
                     "created_at DATETIME"
                 ");" ];

                [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                [db executeUpdate:@"CREATE INDEX bookmark_starred_idx ON bookmark (starred);"];
                [db executeUpdate:@"CREATE INDEX bookmark_private_idx ON bookmark (private);"];
                [db executeUpdate:@"CREATE INDEX bookmark_unread_idx ON bookmark (unread);"];
                [db executeUpdate:@"CREATE INDEX bookmark_url_idx ON bookmark (url);"];
                [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];

                [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url, prefix='2,3,4,5,6');"];
                [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts4(id, name, prefix='2,3,4,5');"];

                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];

                // Tagging
                [db executeUpdate:
                 @"CREATE TABLE tag("
                     "name TEXT UNIQUE,"
                     "count INTEGER"
                 ");" ];

                [db executeUpdate:@"CREATE INDEX tag_name_idx ON tag (name);"];

                [db executeUpdate:
                 @"CREATE TABLE tagging("
                     "tag_name TEXT,"
                     "bookmark_hash TEXT"
                 ");" ];

                [db executeUpdate:@"CREATE INDEX tagging_tag_name_idx ON tagging (tag_name);"];
                [db executeUpdate:@"CREATE INDEX tagging_bookmark_hash_idx ON tagging (bookmark_hash);"];
                
                [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (name) VALUES(new.name); END;"];
                [db executeUpdate:@"CREATE TRIGGER tag_fts_delete_trigger AFTER DELETE ON tag BEGIN DELETE FROM tag_fts WHERE name=old.name; END;"];

                [db executeUpdate:@"PRAGMA user_version=1;"];
                
            default:
                break;
        }
        [db commit];
    }
#else
    if ([s next]) {
        int version = [s intForColumnIndex:0];
        [db beginTransaction];
        switch (version) {
            case 0:
                [db executeUpdate:
                 @"CREATE TABLE bookmark("
                     "id INTEGER PRIMARY KEY ASC,"
                     "title VARCHAR(255),"
                     "description TEXT,"
                     "tags TEXT,"
                     "url TEXT UNIQUE CHECK(length(url) < 2000),"
                     "count INTEGER,"
                     "private BOOL,"
                     "unread BOOL,"
                     "hash VARCHAR(32) UNIQUE,"
                     "meta VARCHAR(32),"
                     "created_at DATETIME"
                 ");" ];
                [db executeUpdate:
                 @"CREATE TABLE tag("
                     "id INTEGER PRIMARY KEY ASC,"
                     "name VARCHAR(255) UNIQUE,"
                     "count INTEGER"
                 ");" ];
                [db executeUpdate:
                 @"CREATE TABLE tagging("
                     "tag_id INTEGER,"
                     "bookmark_id INTEGER,"
                     "PRIMARY KEY (tag_id, bookmark_id),"
                     "FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE,"
                     "FOREIGN KEY (bookmark_id) REFERENCES bookmark (id) ON DELETE CASCADE"
                 ");" ];
                [db executeUpdate:
                 @"CREATE TABLE note("
                     "id INTEGER PRIMARY KEY ASC,"
                     "remote_id VARCHAR(20) UNIQUE,"
                     "hash VARCHAR(20) UNIQUE,"
                     "title VARCHAR(255),"
                     "text TEXT,"
                     "length INTEGER,"
                     "created_at DATETIME,"
                     "updated_at DATETIME"
                 ");" ];

                // Full text search
                [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(id, title, description, tags);"];
                [db executeUpdate:@"CREATE VIRTUAL TABLE note_fts USING fts4(id, title, text);"];
                [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts4(id, name);"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (id, title, description, tags) VALUES(new.id, new.title, new.description, new.tags); END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags WHERE id=new.id; END;"];
                [db executeUpdate:@"CREATE TRIGGER note_fts_insert_trigger AFTER INSERT ON note BEGIN INSERT INTO note_fts (id, title, text) VALUES(new.id, new.title, new.text); END;"];
                [db executeUpdate:@"CREATE TRIGGER note_fts_update_trigger AFTER UPDATE ON note BEGIN UPDATE note_fts SET title=new.title, description=new.text WHERE id=new.id; END;"];
                [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (id, name) VALUES(new.id, new.name); END;"];
                [db executeUpdate:@"CREATE TRIGGER tag_fts_update_trigger AFTER UPDATE ON tag BEGIN UPDATE tag_fts SET name=new.name WHERE id=new.id; END;"];

                [db executeUpdate:@"CREATE INDEX bookmark_title_idx ON bookmark (title);"];
                [db executeUpdate:@"CREATE INDEX note_title_idx ON note (title);"];

                // Has no effect here
                // [db executeUpdate:@"PRAGMA foreign_keys=1;"];

                [db executeUpdate:@"PRAGMA user_version=1;"];

            case 1:
                [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];
                [db executeUpdate:@"PRAGMA user_version=2;"];

            case 2:
                self.readLater = PPReadLaterNone;
                [db executeUpdate:@"CREATE TABLE rejected_bookmark(url TEXT UNIQUE CHECK(length(url) < 2000));"];
                [db executeUpdate:@"CREATE INDEX rejected_bookmark_url_idx ON rejected_bookmark (url);"];
                [db executeUpdate:@"CREATE INDEX tag_name_idx ON tag (name);"];
                [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];
                [db executeUpdate:@"PRAGMA user_version=3;"];
                
            case 3:
                [db executeUpdate:@"ALTER TABLE rejected_bookmark RENAME TO rejected_bookmark_old;"];
                [db executeUpdate:
                 @"CREATE TABLE rejected_bookmark("
                    "url TEXT UNIQUE CHECK(length(url) < 2000),"
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                 ");"];
                [db executeUpdate:@"INSERT INTO rejected_bookmark (url) SELECT url FROM rejected_bookmark_old;"];

                [db executeUpdate:@"ALTER TABLE bookmark ADD COLUMN starred BOOL DEFAULT 0;"];
                [db executeUpdate:@"CREATE INDEX bookmark_starred_idx ON bookmark (starred);"];
                [db executeUpdate:@"PRAGMA user_version=4;"];
                
            case 4:
                [db executeUpdate:
                 @"CREATE TABLE feeds("
                     "components TEXT UNIQUE,"
                     "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                 ");"];
                [db executeUpdate:@"PRAGMA user_version=5;"];
                
            case 5:
                [db closeOpenResultSets];
                [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                [db executeUpdate:@"DROP INDEX bookmark_hash_idx"];
                [db executeUpdate:@"PRAGMA user_version=6;"];

            case 6:
                [db closeOpenResultSets];
                [db executeUpdate:@"ALTER TABLE bookmark RENAME TO bookmark_old;"];
                [db executeUpdate:@"ALTER TABLE tagging RENAME TO tagging_old;"];
                [db executeUpdate:@"ALTER TABLE tag RENAME TO tag_old;"];

                [db executeUpdate:@"DROP INDEX bookmark_created_at_idx"];
                [db executeUpdate:@"DROP INDEX bookmark_starred_idx"];
                [db executeUpdate:@"DROP INDEX bookmark_title_idx"];
                [db executeUpdate:
                 @"CREATE TABLE bookmark("
                     "title TEXT,"
                     "description TEXT,"
                     "tags TEXT,"
                     "url TEXT,"
                     "count INTEGER,"
                     "private BOOL,"
                     "unread BOOL,"
                     "starred BOOL,"
                     "hash VARCHAR(32) UNIQUE,"
                     "meta VARCHAR(32),"
                     "created_at DATETIME"
                 ");" ];
                [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                [db executeUpdate:@"CREATE INDEX bookmark_starred_idx ON bookmark (starred);"];
                [db executeUpdate:@"CREATE INDEX bookmark_private_idx ON bookmark (private);"];
                [db executeUpdate:@"CREATE INDEX bookmark_unread_idx ON bookmark (unread);"];
                [db executeUpdate:@"CREATE INDEX bookmark_url_idx ON bookmark (url);"];
                
                // Tag
                [db executeUpdate:@"DROP TRIGGER tag_fts_insert_trigger;"];
                [db executeUpdate:@"DROP TRIGGER tag_fts_update_trigger;"];

                [db executeUpdate:
                 @"CREATE TABLE tag("
                     "name TEXT UNIQUE,"
                     "count INTEGER"
                 ");" ];

                [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (name) VALUES(new.name); END;"];
                [db executeUpdate:@"CREATE TRIGGER tag_fts_delete_trigger AFTER DELETE ON tag BEGIN DELETE FROM tag_fts WHERE name=old.name; END;"];
                [db executeUpdate:@"INSERT INTO tag (name, count) SELECT name, count FROM tag_old;"];
                
                // Tagging
                [db executeUpdate:
                 @"CREATE TABLE tagging("
                     "tag_name TEXT,"
                     "bookmark_hash TEXT"
                 ");" ];

                [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) SELECT tag_old.name, bookmark_old.hash FROM bookmark_old, tagging_old, tag_old WHERE tagging_old.bookmark_id=bookmark_old.id AND tagging_old.tag_id=tag_old.id"];
                [db executeUpdate:@"CREATE INDEX tagging_tag_name_idx ON tagging (tag_name);"];
                [db executeUpdate:@"CREATE INDEX tagging_bookmark_hash_idx ON tagging (bookmark_hash);"];

                // FTS Updates
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_insert_trigger;"];
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_update_trigger;"];
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_delete_trigger;"];
                [db executeUpdate:@"DROP TABLE bookmark_fts;"];

                [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url);"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];

                [db commit];
                [db beginTransaction];
                // Repopulate bookmarks
                [db executeUpdate:@"INSERT INTO bookmark (title, description, tags, url, count, private, unread, starred, hash, meta, created_at) SELECT title, description, tags, url, count, private, unread, starred, hash, meta, created_at FROM bookmark_old;"];

                [db executeUpdate:@"DROP TABLE tagging_old;"];
                [db executeUpdate:@"DROP TABLE tag_old;"];
                [db executeUpdate:@"DROP TABLE bookmark_old;"];
                [db executeUpdate:@"PRAGMA user_version=7;"];

            case 7:
                [db closeOpenResultSets];
                
                [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];

                // FTS Updates
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_insert_trigger;"];
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_update_trigger;"];
                [db executeUpdate:@"DROP TRIGGER bookmark_fts_delete_trigger;"];
                [db executeUpdate:@"DROP TABLE bookmark_fts;"];

                [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url, prefix='2,3,4,5,6');"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];

                // Repopulate bookmarks
                [db executeUpdate:@"INSERT INTO bookmark_fts (hash, title, description, tags, url) SELECT hash, title, description, tags, url FROM bookmark;"];
                [db executeUpdate:@"PRAGMA user_version=8;"];

            default:
                break;
        }
        [db commit];
    }
#endif
    
    [db close];
}

+ (AppDelegate *)sharedDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Properties

- (void)setLastUpdated:(NSDate *)lastUpdated {
    _lastUpdated = lastUpdated;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastUpdated forKey:@"io.aurora.pinboard.LastUpdated"];
    [defaults synchronize];
}

- (NSDate *)lastUpdated {
    if (!_lastUpdated) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _lastUpdated = [defaults objectForKey:@"io.aurora.pinboard.LastUpdated"];
    }
    return _lastUpdated;
}

- (void)setPrivateByDefault:(BOOL)privateByDefault {
    _privateByDefault = privateByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(privateByDefault) forKey:@"io.aurora.pinboard.PrivateByDefault"];
    [defaults synchronize];
}

- (BOOL)privateByDefault {
    if (!_privateByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _privateByDefault = [[defaults objectForKey:@"io.aurora.pinboard.PrivateByDefault"] boolValue];
    }
    return _privateByDefault;
}

- (BOOL)openLinksInApp {
    if (!_openLinksInApp) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksInApp = [[defaults objectForKey:@"io.aurora.pinboard.OpenLinksInApp"] boolValue];
    }
    return _openLinksInApp;
}

- (void)setOpenLinksInApp:(BOOL)openLinksInApp {
    _openLinksInApp = openLinksInApp;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(openLinksInApp) forKey:@"io.aurora.pinboard.OpenLinksInApp"];
    [defaults synchronize];
}

- (void)setDoubleTapToEdit:(BOOL)doubleTapToEdit {
    _doubleTapToEdit = doubleTapToEdit;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(doubleTapToEdit) forKey:@"io.aurora.pinboard.DoubleTapToEdit"];
    [defaults synchronize];
}

- (BOOL)doubleTapToEdit {
    if (!_doubleTapToEdit) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _doubleTapToEdit = [[defaults objectForKey:@"io.aurora.pinboard.DoubleTapToEdit"] boolValue];
    }
    return _doubleTapToEdit;
}

- (void)setReadByDefault:(BOOL)readByDefault {
    _readByDefault = readByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(readByDefault) forKey:@"io.aurora.pinboard.ReadByDefault"];
    [defaults synchronize];
}

- (BOOL)readByDefault {
    if (!_readByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _readByDefault = [[defaults objectForKey:@"io.aurora.pinboard.ReadByDefault"] boolValue];
    }
    return _readByDefault;
}

- (void)setDefaultFeed:(NSString *)defaultFeed {
    _defaultFeed = defaultFeed;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_defaultFeed forKey:@"io.aurora.pinboard.DefaultFeed"];
}

- (NSString *)defaultFeed {
    if (!_defaultFeed) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _defaultFeed = [defaults objectForKey:@"io.aurora.pinboard.DefaultFeed"];
        if (!_defaultFeed) {
            _defaultFeed = @"personal:all";
        }
    }
    
    return _defaultFeed;
}

- (NSString *)defaultFeedDescription {
    // Build a descriptive string for the default feed
    NSString *feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Personal", nil), @"All"];
    if (self.defaultFeed) {
        if ([[self.defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
            feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Personal", nil), [[self.defaultFeed substringFromIndex:9] capitalizedString]];
        }
        else if ([[self.defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
            NSString *communityDescription = [self.defaultFeed substringFromIndex:10];
            if ([communityDescription isEqualToString:@"japanese"]) {
                communityDescription = @"日本語";
            }
            feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Community", nil), [communityDescription capitalizedString]];
        }
        else if ([[self.defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
            feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Saved Feed", nil), [self.defaultFeed substringFromIndex:6]];
        }
    }
    return feedDescription;
}

- (BOOL)compressPosts {
    if (!_compressPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _compressPosts = [[defaults objectForKey:@"io.aurora.pinboard.CompressPosts"] boolValue];
    }
    return _compressPosts;
}

- (void)setCompressPosts:(BOOL)compressPosts {
    _compressPosts = compressPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(compressPosts) forKey:@"io.aurora.pinboard.CompressPosts"];
    [defaults synchronize];
}

- (BOOL)openLinksWithMobilizer {
    if (!_openLinksWithMobilizer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksWithMobilizer = [[defaults objectForKey:@"io.aurora.pinboard.OpenLinksWithMobilizer"] boolValue];
    }
    return _openLinksWithMobilizer;
}

- (void)setOpenLinksWithMobilizer:(BOOL)openLinksWithMobilizer {
    _openLinksWithMobilizer = openLinksWithMobilizer;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(openLinksWithMobilizer) forKey:@"io.aurora.pinboard.OpenLinksWithMobilizer"];
    [defaults synchronize];
}

- (BOOL)dimReadPosts {
    if (!_dimReadPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _dimReadPosts = [[defaults objectForKey:@"io.aurora.pinboard.DimReadPosts"] boolValue];
    }
    return _dimReadPosts;
}

- (void)setDimReadPosts:(BOOL)dimReadPosts {
    _dimReadPosts = dimReadPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(dimReadPosts) forKey:@"io.aurora.pinboard.DimReadPosts"];
    [defaults synchronize];
}

- (BOOL)markReadPosts {
    if (!_markReadPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _markReadPosts = [[defaults objectForKey:@"io.aurora.pinboard.MarkReadPosts"] boolValue];
    }
    return _markReadPosts;
}

- (void)setMarkReadPosts:(BOOL)markReadPosts {
    _markReadPosts = markReadPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(markReadPosts) forKey:@"io.aurora.pinboard.MarkReadPosts"];
    [defaults synchronize];
}

- (BOOL)onlyPromptToAddOnce {
    if (!_onlyPromptToAddOnce) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _onlyPromptToAddOnce = [[defaults objectForKey:@"io.aurora.pinboard.OnlyPromptToAddOnce"] boolValue];
    }
    return _onlyPromptToAddOnce;
}

- (void)setOnlyPromptToAddOnce:(BOOL)onlyPromptToAddOnce {
    _onlyPromptToAddOnce = onlyPromptToAddOnce;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(onlyPromptToAddOnce) forKey:@"io.aurora.pinboard.OnlyPromptToAddOnce"];
    [defaults synchronize];
}

- (BOOL)enableAutoCorrect {
    if (!_enableAutoCorrect) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _enableAutoCorrect = [[defaults objectForKey:@"io.aurora.pinboard.EnableAutoCorrect"] boolValue];
    }
    return _enableAutoCorrect;
}

- (void)setEnableAutoCorrect:(BOOL)enableAutoCorrect {
    _enableAutoCorrect = enableAutoCorrect;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enableAutoCorrect) forKey:@"io.aurora.pinboard.EnableAutoCorrect"];
    [defaults synchronize];
}

- (BOOL)enableAutoCapitalize {
    if (!_enableAutoCapitalize) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _enableAutoCapitalize = [[defaults objectForKey:@"io.aurora.pinboard.EnableAutoCapitalize"] boolValue];
    }
    return _enableAutoCapitalize;
}

- (void)setEnableAutoCapitalize:(BOOL)enableAutoCapitalize {
    _enableAutoCapitalize = enableAutoCapitalize;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enableAutoCapitalize) forKey:@"io.aurora.pinboard.EnableAutoCapitalize"];
    [defaults synchronize];
}

- (void)setBrowser:(PPBrowserType)browser {
    _browser = browser;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(browser) forKey:@"io.aurora.pinboard.Browser"];
    [defaults synchronize];
}

- (PPBrowserType)browser {
    if (!_browser) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.Browser"];
        
        if (result) {
            _browser = [result integerValue];
            
            if (_browser == PPBrowserWebview) {
                _browser = PPBrowserSafari;
            }
        }
        else {
            _browser = PPBrowserSafari;
        }
    }
    return _browser;
}

- (void)setFeedToken:(NSString *)feedToken {
    _feedToken = feedToken;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:feedToken forKey:@"io.aurora.pinboard.FeedToken"];
    [defaults synchronize];
}

- (NSString *)feedToken {
    if (!_feedToken) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _feedToken = [defaults objectForKey:@"io.aurora.pinboard.FeedToken"];
    }
    return _feedToken;
}

- (void)setReadLater:(PPReadLaterType)readLater{
    _readLater = readLater;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(readLater) forKey:@"io.aurora.pinboard.ReadLater"];
    [defaults synchronize];
}

- (PPReadLaterType)readLater {
    if (!_readLater) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.ReadLater"];
        
        if (result) {
            _readLater = [result integerValue];
        }
        else {
            _readLater = PPReadLaterNone;
        }
    }
    return _readLater;
}

- (void)setMobilizer:(PPMobilizerType)mobilizer {
    _mobilizer = mobilizer;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(mobilizer) forKey:@"io.aurora.pinboard.Mobilizer"];
    [defaults synchronize];
}

- (PPMobilizerType)mobilizer {
    if (!_mobilizer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.Mobilizer"];
        
        if (result) {
            _mobilizer = [result integerValue];
        }
        else {
            _mobilizer = PPMobilizerInstapaper;
        }
    }
    return _mobilizer;
}

- (void)setToken:(NSString *)token {
    _token = token;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"io.aurora.pinboard.Token"];
    [defaults synchronize];
}

- (NSString *)token {
    if (!_token) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _token = [defaults objectForKey:@"io.aurora.pinboard.Token"];
    }
    return _token;
}

- (NSString *)username {
#ifdef DELICIOUS
    return _username;
#else
    return [[[self token] componentsSeparatedByString:@":"] objectAtIndex:0];
#endif
}

#pragma mark - Helpers

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSInteger NumberOfCallsToSetVisible = 0;
    if (setVisible) {
        NumberOfCallsToSetVisible++;
    }
    else {
        NumberOfCallsToSetVisible--;
    }
    
    // Display the indicator as long as our static counter is > 0.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
    });
}

- (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [self setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self setNetworkActivityIndicatorVisible:NO];
                               
                               NSString *description = @"";
                               NSString *title = @"";
                               if (!error) {
                                   HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];

                                   if (!error) {
                                       NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

                                       HTMLNode *root = [parser head];
                                       HTMLNode *titleTag = [root findChildTag:@"title"];
                                       NSArray *metaTags = [root findChildTags:@"meta"];
                                       for (HTMLNode *tag in metaTags) {
                                           if ([[tag getAttributeNamed:@"name"] isEqualToString:@"description"]) {
                                               description = [[tag getAttributeNamed:@"content"] stringByTrimmingCharactersInSet:whitespace];
                                               break;
                                           }
                                       }
                                       
                                       if (titleTag && titleTag.contents) {
                                           title = [titleTag.contents stringByTrimmingCharactersInSet:whitespace];
                                       }
                                   }
                               }

                               callback(title, description);
                           }];
}

- (void)closeModal:(UIViewController *)sender success:(void (^)())success {
    [self.navigationController dismissViewControllerAnimated:YES completion:success];
}

- (void)closeModal:(UIViewController *)sender {
    [self closeModal:sender success:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.addBookmarkAlertView) {
        self.addBookmarkAlertView = nil;

        if (buttonIndex == 1) {
            PPNavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"url": self.clipboardBookmarkURL, @"title": self.clipboardBookmarkTitle} update:@(NO) callback:nil];
            
            if ([UIApplication isIPad]) {
                addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            }

            [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
            [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                [db close];
            });
        }
    }
    else if (alertView == self.updateBookmarkAlertView) {
        self.updateBookmarkAlertView = nil;

        if (buttonIndex == 1) {
            PPNavigationController *addBookmarkViewController = [AddBookmarkViewController updateBookmarkViewControllerWithURLString:self.clipboardBookmarkURL callback:nil];
            
            if ([UIApplication isIPad]) {
                addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
            [[Mixpanel sharedInstance] track:@"Decided to edit bookmark from clipboard"];
        }
    }
}

- (NSString *)password {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
    return [keychain objectForKey:(__bridge id)kSecValueData];
}

- (void)setPassword:(NSString *)password {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
    [keychain setObject:self.username forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:password forKey:(__bridge id)kSecValueData];
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc {
    barButtonItem.image = [UIImage imageNamed:@"navigation-list"];
    self.navigationController.splitViewControllerBarButtonItem = barButtonItem;
    
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationController.topViewController.navigationItem.leftBarButtonItem = barButtonItem;
    }
}

- (void)splitViewController:(UISplitViewController *)svc
          popoverController:(UIPopoverController *)pc
  willPresentViewController:(UIViewController *)aViewController {
    self.feedListViewController.popover = pc;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    self.feedListViewController.popover = nil;
    self.navigationController.topViewController.navigationItem.leftBarButtonItem = nil;
}

@end

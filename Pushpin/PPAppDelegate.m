//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@import QuartzCore;

#import "PPAppDelegate.h"
#import "PPLoginViewController.h"
#import "PPSettingsViewController.h"
#import "PPGenericPostViewController.h"
#import "PPPinboardDataSource.h"
#import "PPNotification.h"
#import "PPFeedListViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPWebViewController.h"
#import "PPToolbar.h"
#import "PPPinboardFeedDataSource.h"
#import "PPMultipleEditViewController.h"
#import "PPNavigationController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "ScreenshotViewController.h"
#import "PPStatusBarNotification.h"
#import "PPMobilizerUtility.h"
#import "PPSplitViewController.h"
#import "PPStatusBar.h"
#import "PPDeliciousDataSource.h"
#import "PPSettings.h"

#import <LHSDelicious/LHSDelicious.h>
#import <ASPinboard/ASPinboard.h>
#import <FMDB/FMDatabase.h>
#import <Reachability/Reachability.h>
#import <PocketAPI/PocketAPI.h>
#import <TestFlightSDK/TestFlight.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <OpenInChrome/OpenInChromeController.h>
#import <LHSCategoryCollection/UIViewController+LHSAdditions.h>
#import <Crashlytics/Crashlytics.h>
#import "MFMailComposeViewController+Theme.h"
#import <LHSDiigo/LHSDiigoClient.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>

@interface PPAppDelegate ()

@property (nonatomic, strong) PPNavigationController *feedListNavigationController;
@property (nonatomic, strong) UIAlertView *updateBookmarkAlertView;
@property (nonatomic, strong) UIAlertView *addBookmarkAlertView;
@property (nonatomic, strong) NSURLCache *urlCache;
@property (nonatomic, strong) UIViewController *presentingController;

@end

@implementation PPAppDelegate

@synthesize splitViewController = _splitViewController;

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

+ (FMDatabaseQueue *)databaseQueue {
    static dispatch_once_t onceToken;
    static FMDatabaseQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [FMDatabaseQueue databaseQueueWithPath:[self databasePath]];
    });
    return queue;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [application cancelAllLocalNotifications];

    if (application.applicationState == UIApplicationStateActive) {
        UIViewController *controller = [UIViewController lhs_topViewController];
        if ([NSStringFromClass([controller class]) isEqualToString:@"_UIModalItemsPresentingViewController"]) {
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
            [application scheduleLocalNotification:notification];
        }
        else {
            self.bookmarksUpdated = [notification.userInfo[@"updated"] boolValue];
            NSString *text = notification.alertBody;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PPStatusBar status] showWithText:text];
            });
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark
                                                                                                                    update:isUpdate
                                                                                                                  callback:callback];

    if ([UIApplication isIPad]) {
        addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

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
    if ([@"/TextExpanderSettings" isEqualToString:url.path]) {
        NSError *error;
        BOOL cancel;

        if (![self.textExpander handleGetSnippetsURL:url error:&error cancelFlag:&cancel]) {
            // User cancelled request.
        }
        else {
            if (cancel) {
                // User cancelled get snippets
                return NO;
            }
        }
    }
    else if ([url.host isEqualToString:@"add"]) {
        didLaunchWithURL = YES;
        [self showAddBookmarkViewControllerWithBookmark:[self parseQueryParameters:url.query]
                                                 update:@(NO)
                                               callback:^{
                                                   NSDictionary *data = [self parseQueryParameters:url.query];
                                                   if (data[@"x-success"]) {
                                                       NSURL *url = [NSURL URLWithString:[data[@"x-success"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                                       [application openURL:url];
                                                   }
                                               }];
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

        PPGenericPostViewController *postViewController = [PPPinboardFeedDataSource postViewControllerWithComponents:components];
        postViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                                               style:UIBarButtonItemStyleDone
                                                                                              target:self
                                                                                              action:@selector(closeModal:)];
        PPNavigationController *navController = [[PPNavigationController alloc] initWithRootViewController:postViewController];

        void (^PresentView)() = ^{
            if ([UIApplication isIPad]) {
                UINavigationController *navigationController = [PPAppDelegate sharedDelegate].navigationController;
                if (navigationController.viewControllers.count == 1) {
                    UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
                    if (showPopoverBarButtonItem) {
                        postViewController.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
                    }
                }

                [navigationController setViewControllers:@[postViewController] animated:YES];

                if ([postViewController respondsToSelector:@selector(postDataSource)]) {
                    if ([[postViewController postDataSource] respondsToSelector:@selector(barTintColor)]) {
                        [self.feedListNavigationController.navigationBar setBarTintColor:[postViewController.postDataSource barTintColor]];
                    }
                }

                UIPopoverController *popover = [PPAppDelegate sharedDelegate].feedListViewController.popover;
                if (popover) {
                    [popover dismissPopoverAnimated:YES];
                }
            }
            else {
                [self.navigationController presentViewController:navController animated:NO completion:nil];
            }
        };

        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                PresentView();
            }];
        }
        else {
            PresentView();
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
                        OpenInChromeController *openInChromeController = [OpenInChromeController sharedInstance];
                        [openInChromeController openInChrome:url];
                    }
                    else {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }];
        }
    }
    else if (url.host && ![url.host isEqualToString:@""]) {
        NSRange range = [url.absoluteString rangeOfString:@"pushpin"];
        NSString *urlString = [url.absoluteString stringByReplacingCharactersInRange:range withString:@"http"];
        PPWebViewController *webViewController = [PPWebViewController webViewControllerWithURL:urlString];
        webViewController.shouldMobilize = [PPSettings sharedSettings].openLinksWithMobilizer;
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
    PPSettings *settings = [PPSettings sharedSettings];
#ifdef DELICIOUS
    BOOL isAuthenticated = settings.username != nil && settings.password != nil;
#endif
    
#ifdef PINBOARD
    BOOL isAuthenticated = settings.token != nil;
#endif

    if (!didLaunchWithURL && isAuthenticated) {
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
            __block BOOL alreadyExistsInBookmarks;
            __block BOOL alreadyRejected;

            [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                [results next];
                alreadyExistsInBookmarks = [results intForColumnIndex:0] != 0;
                [results close];

                results = [db executeQuery:@"SELECT COUNT(*) FROM rejected_bookmark WHERE url=?" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                [results next];
                alreadyRejected = [results intForColumnIndex:0] != 0;
                [results close];
            }];

            if (alreadyRejected && [PPSettings sharedSettings].onlyPromptToAddOnce) {
                if ([PPSettings sharedSettings].alwaysShowClipboardNotification) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UILocalNotification *notification = [[UILocalNotification alloc] init];
                        notification.alertBody = @"Reset the list of stored URLs in advanced settings to add or edit this bookmark.";
                        notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

                    });
                }
            }
            else if (alreadyExistsInBookmarks) {
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
            else {
                NSURL *candidateURL = [NSURL URLWithString:self.clipboardBookmarkURL];
                if (candidateURL && candidateURL.scheme && candidateURL.host) {
                    [PPUtilities retrievePageTitle:candidateURL
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
    PPSettings *settings = [PPSettings sharedSettings];
    NSMutableDictionary *params = [@{@"url": @"",
                                     @"title": @"",
                                     @"description": @"",
                                     @"tags": @"",
                                     @"private": @(settings.privateByDefault),
                                     @"unread": @(!settings.readByDefault) } mutableCopy];

    NSArray *arrParameters = [query componentsSeparatedByString:@"&"];
    for (NSInteger i=0; i<[arrParameters count]; i++) {
        NSArray *arrKeyValue = [arrParameters[i] componentsSeparatedByString:@"="];

        if ([arrKeyValue count] >= 2) {
            NSMutableString *strKey = [NSMutableString string];
            [strKey setString:[[arrKeyValue[0] lowercaseString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];

            NSMutableString *strValue   = [NSMutableString string];
            [strValue setString:[[arrKeyValue[1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];

            if (strKey.length > 0) {
                params[strKey] = strValue;
            }
        }
    }
    return params;
}

- (void)openSettings {
    PPSettingsViewController *settingsViewController = [[PPSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (PPSplitViewController *)splitViewController {
    if (!_splitViewController) {
        _splitViewController = [[PPSplitViewController alloc] init];
        _splitViewController.viewControllers = @[self.feedListNavigationController, self.navigationController];
        _splitViewController.delegate = self;
        _splitViewController.presentsWithGesture = NO;
    }
    return _splitViewController;
}

- (PPNavigationController *)feedListNavigationController {
    if (!_feedListNavigationController) {
        _feedListNavigationController = [[PPNavigationController alloc] initWithRootViewController:self.feedListViewController];
    }
    return _feedListNavigationController;
}

- (PPFeedListViewController *)feedListViewController {
    if (!_feedListViewController) {
        _feedListViewController = [[PPFeedListViewController alloc] init];
    }
    return _feedListViewController;
}

- (PPNavigationController *)navigationController {
    PPSettings *settings = [PPSettings sharedSettings];

    if (!_navigationController) {
#ifdef DELICIOUS
        PPDeliciousDataSource *deliciousDataSource = [[PPDeliciousDataSource alloc] init];
        deliciousDataSource.limit = 100;
        deliciousDataSource.orderBy = @"created_at DESC";

        PPGenericPostViewController *deliciousViewController = [[PPGenericPostViewController alloc] init];
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
        PPPinboardDataSource *pinboardDataSource = [[PPPinboardDataSource alloc] init];
        pinboardDataSource.limit = 100;
        pinboardDataSource.orderBy = @"created_at DESC";

        PPGenericPostViewController *pinboardViewController = [[PPGenericPostViewController alloc] init];
        
        _navigationController = [[PPNavigationController alloc] init];
        
        // Determine our default feed
        NSString *feedDetails;
        if ([[settings.defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
            feedDetails = [settings.defaultFeed substringFromIndex:9];
            
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
                    pinboardDataSource.untagged = kPushpinFilterTrue;
                    break;
                    
                case PPPinboardPersonalFeedStarred:
                    pinboardDataSource.starred = kPushpinFilterTrue;
                    break;
                    
                default:
                    break;
            }

            pinboardViewController.postDataSource = pinboardDataSource;
        }
        else if ([[[PPSettings sharedSettings].defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
            feedDetails = [settings.defaultFeed substringFromIndex:10];
            PPPinboardFeedDataSource *feedDataSource = [[PPPinboardFeedDataSource alloc] init];
            pinboardViewController.postDataSource = feedDataSource;
            
            PPPinboardCommunityFeedType feedType = [PPCommunityFeeds() indexOfObject:feedDetails];
            
            switch (feedType) {
                case PPPinboardCommunityFeedNetwork:
                    feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", settings.feedToken], [NSString stringWithFormat:@"u:%@", settings.username], @"network"];
                    break;

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
                    
                case PPPinboardCommunityFeedRecent:
                    feedDataSource.components = @[@"recent"];
                    break;
                    
                default:
                    break;
            }
        }
        else if ([[settings.defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
            feedDetails = [settings.defaultFeed substringFromIndex:6];
            NSArray *components = [feedDetails componentsSeparatedByString:@"+"];
            PPPinboardFeedDataSource *feedDataSource = [[PPPinboardFeedDataSource alloc] initWithComponents:components];
            pinboardViewController.postDataSource = feedDataSource;
        }

        if ([UIApplication isIPad]) {
            _navigationController.viewControllers = @[pinboardViewController];

            if ([pinboardViewController respondsToSelector:@selector(postDataSource)]) {
                if ([pinboardViewController.postDataSource respondsToSelector:@selector(barTintColor)]) {
                    [self.feedListNavigationController.navigationBar setBarTintColor:[pinboardViewController.postDataSource barTintColor]];
                }
            }
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
        PPLoginViewController *loginViewController = [[PPLoginViewController alloc] init];
        
        PPNavigationController *controller = [[PPNavigationController alloc] initWithRootViewController:loginViewController];
        controller.navigationBar.translucent = NO;
        
        _loginViewController = controller;
    }
    return _loginViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    application.applicationSupportsShakeToEdit = YES;

    [Crashlytics startWithAPIKey:@"ed1bff5018819b0c5dbb8dbb35edac18a8b1af02"];

    [self becomeFirstResponder];
    self.bookmarksUpdated = NO;
    self.bookmarksUpdatedMessage = nil;
    self.addBookmarkAlertView = nil;
    self.updateBookmarkAlertView = nil;
    self.textExpander = [[SMTEDelegateController alloc] init];
    
    // 4 MB memory, 100 MB disk
    self.urlCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                  diskCapacity:100 * 1024 * 1024
                                                      diskPath:@"urlcache"];
    [NSURLCache setSharedURLCache:self.urlCache];

    [self migrateDatabase];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [PPTheme customizeUIElements];

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
        @"io.aurora.pinboard.BrowseFontName": @"AvenirNext-Regular",
        @"io.aurora.pinboard.FontName": @"AvenirNext-Regular",
        @"io.aurora.pinboard.BoldFontName": @"AvenirNext-Medium",
        
        // If a user decides not to add a bookmark when it's on the clipboard, don't ask again.
        @"io.aurora.pinboard.OnlyPromptToAddOnce": @(YES),
        @"io.aurora.pinboard.AlwaysShowClipboardNotification": @(YES),
        @"io.aurora.pinboard.HiddenFeedNames": @[],
        @"io.aurora.pinboard.FontAdjustment": @(PPFontAdjustmentMedium),
#ifdef PINBOARD
        @"io.aurora.pinboard.PersonalFeedOrder": @[
                @(PPPinboardPersonalFeedAll),
                @(PPPinboardPersonalFeedPrivate),
                @(PPPinboardPersonalFeedPublic),
                @(PPPinboardPersonalFeedUnread),
                @(PPPinboardPersonalFeedUntagged),
                @(PPPinboardPersonalFeedStarred),
            ],
        @"io.aurora.pinboard.CommunityFeedOrder": @[
                @(PPPinboardCommunityFeedNetwork),
                @(PPPinboardCommunityFeedPopular),
                @(PPPinboardCommunityFeedWikipedia),
                @(PPPinboardCommunityFeedFandom),
                @(PPPinboardCommunityFeedJapan),
                @(PPPinboardCommunityFeedRecent),
            ],
#endif
        
#ifdef DELICIOUS
        @"io.aurora.pinboard.PersonalFeedOrder": @[
                @(PPDeliciousPersonalFeedAll),
                @(PPDeliciousPersonalFeedPrivate),
                @(PPDeliciousPersonalFeedPublic),
                @(PPDeliciousPersonalFeedUnread),
                @(PPDeliciousPersonalFeedUntagged),
            ],
#endif
     }];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.Pushpin"];
    [sharedDefaults setObject:[[PPSettings sharedSettings] token] forKey:@"token"];
    
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];

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
    LHSDelicious *delicious = [LHSDelicious sharedInstance];
    [delicious setRequestCompletedCallback:^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
    }];

    [delicious setRequestStartedCallback:^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    }];
#endif

#ifdef PINBOARD
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard setRequestCompletedCallback:^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
    }];
    [pinboard setRequestStartedCallback:^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    }];
#endif

    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    PPSettings *settings = [PPSettings sharedSettings];
    if (settings.isAuthenticated) {
#ifdef PINBOARD
        pinboard.token = settings.token;
#endif
        
#ifdef DELICIOUS
        delicious.username = settings.username;
        delicious.password = settings.password;
#endif
        [mixpanel identify:settings.username];
        [mixpanel.people set:@"$username" to:settings.username];
        
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

    /*
    NSArray *fontFamilies = [UIFont familyNames];
    for (int i = 0; i < [fontFamilies count]; i++)
    {
        NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamily];
        NSLog (@"%@: %@", fontFamily, fontNames);
    }
     */

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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create the database if it does not yet exist.
        FMDatabase *db = [FMDatabase databaseWithPath:[PPAppDelegate databasePath]];
        [db open];
        [db close];
        
        [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
            // http://stackoverflow.com/a/875422/39155
            [db executeUpdate:@"PRAGMA cache_size=100;"];
            
            // http://stackoverflow.com/a/875422/39155
            [db executeUpdate:@"PRAGMA syncronous=OFF;"];
            
            FMResultSet *s = [db executeQuery:@"PRAGMA user_version"];
            BOOL success = [s next];
            if (success) {
                int version = [s intForColumnIndex:0];
                [s close];
                
                [db beginTransaction];
                
                switch (version) {
#ifdef DELICIOUS
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
#endif
                        
#ifdef PINBOARD
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
                        [[PPSettings sharedSettings] setReadLater:PPReadLaterNone];
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
                        
                    case 8:
                        [db executeUpdate:@"DELETE FROM tagging WHERE tag_name='';"];
                        [db executeUpdate:@"PRAGMA user_version=9;"];
                        
                    case 9: {
                        NSArray *communityFeedOrder = [PPSettings sharedSettings].communityFeedOrder;
                        [[PPSettings sharedSettings] setCommunityFeedOrder:[communityFeedOrder arrayByAddingObject:@(PPPinboardCommunityFeedRecent)]];
                        [db executeUpdate:@"PRAGMA user_version=10;"];
                    }

                    default:
                        break;
#endif
                }
                
                [db commit];
            }
            else {
                [s close];
            }
        }];
    });
}

+ (PPAppDelegate *)sharedDelegate {
    return (PPAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Helpers

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
            PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"url": self.clipboardBookmarkURL, @"title": self.clipboardBookmarkTitle} update:@(NO) callback:nil];
            
            if ([UIApplication isIPad]) {
                addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            }

            [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
            [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
                    [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                }];
            });
        }
    }
    else if (alertView == self.updateBookmarkAlertView) {
        self.updateBookmarkAlertView = nil;

        if (buttonIndex == 1) {
            PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController updateBookmarkViewControllerWithURLString:self.clipboardBookmarkURL callback:nil];
            
            if ([UIApplication isIPad]) {
                addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
            [[Mixpanel sharedInstance] track:@"Decided to edit bookmark from clipboard"];
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
                    [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                }];
            });
        }
    }
}

- (void)logout {
#ifdef DELICIOUS
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"DeliciousCredentials" accessGroup:nil];
#endif
    
#ifdef PINBOARD
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
#endif

    [self resetDatabase];

    // Reset all values in settings
#warning Need to decide which settings are reset and which ones aren't.

    PPSettings *settings = [PPSettings sharedSettings];
    settings.hiddenFeedNames = @[];

#ifdef DELICIOUS
    settings.personalFeedOrder = @[
                               @(PPDeliciousPersonalFeedAll),
                               @(PPDeliciousPersonalFeedPrivate),
                               @(PPDeliciousPersonalFeedPublic),
                               @(PPDeliciousPersonalFeedUnread),
                               @(PPDeliciousPersonalFeedUntagged),
                           ];
#endif

#ifdef PINBOARD
    settings.personalFeedOrder = @[
                               @(PPPinboardPersonalFeedAll),
                               @(PPPinboardPersonalFeedPrivate),
                               @(PPPinboardPersonalFeedPublic),
                               @(PPPinboardPersonalFeedUnread),
                               @(PPPinboardPersonalFeedUntagged),
                               @(PPPinboardPersonalFeedStarred),
                           ];

    settings.communityFeedOrder = @[
                                @(PPPinboardCommunityFeedNetwork),
                                @(PPPinboardCommunityFeedPopular),
                                @(PPPinboardCommunityFeedWikipedia),
                                @(PPPinboardCommunityFeedFandom),
                                @(PPPinboardCommunityFeedJapan),
                                @(PPPinboardCommunityFeedRecent),
                            ];
    
    settings.hiddenFeedNames = @[];
#endif
    
    [keychain resetKeychainItem];
    settings.token = nil;
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

#pragma mark - MFMailComposeViewControllerDelegate

#ifdef APPSTORE
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self.presentingController dismissViewControllerAnimated:YES completion:nil];
}
#endif

- (void)deleteDatabaseFile {
    NSError *error;

    // Remove the database.
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL fileExists = [manager fileExistsAtPath:[PPAppDelegate databasePath]];
    
    if (fileExists){
        BOOL success = [manager removeItemAtPath:[PPAppDelegate databasePath] error:&error];
    }
}

- (void)resetDatabase {
    [[PPAppDelegate databaseQueue] inDatabase:^(FMDatabase *db) {
        db.logsErrors = YES;
        [db executeUpdate:@"DROP TABLE feeds"];
        [db executeUpdate:@"DROP TABLE rejected_bookmark"];
        [db executeUpdate:@"DROP TABLE bookmark"];
        [db executeUpdate:@"DROP TABLE tag"];
        [db executeUpdate:@"DROP TABLE tagging"];
        [db executeUpdate:@"DROP TABLE bookmark_fts"];
        [db executeUpdate:@"DROP TABLE tag_fts"];

#ifdef PINBOARD
        [db executeUpdate:@"DROP TABLE note"];
#endif

        [db executeUpdate:@"PRAGMA user_version=0;"];
    }];
}

@end

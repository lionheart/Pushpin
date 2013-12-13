//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ASPinboard/ASPinboard.h>
#import "AppDelegate.h"
#import "NoteViewController.h"
#import "LoginViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Reachability.h"
#import "PocketAPI.h"
#import "HTMLParser.h"
#import "SettingsViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PPNotification.h"
#import "FeedListViewController.h"
#import "AddBookmarkViewController.h"
#import "PPWebViewController.h"
#import "PPToolbar.h"
#import "PPCoreGraphics.h"
#import "PinboardFeedDataSource.h"
#import "PPMultipleEditViewController.h"
#import "PPNavigationController.h"

#import "UIApplication+Additions.h"
#import "TestFlight.h"

@implementation AppDelegate

@synthesize window;
@synthesize readlater = _readlater;
@synthesize token = _token;
@synthesize browser = _browser;
@synthesize mobilizer = _mobilizer;
@synthesize lastUpdated = _lastUpdated;
@synthesize privateByDefault = _privateByDefault;
@synthesize dimReadPosts = _dimReadPosts;
@synthesize markReadPosts = _markReadPosts;
@synthesize enableAutoCorrect = _enableAutoCorrect;
@synthesize enableAutoCapitalize = _enableAutoCapitalize;
@synthesize feedToken = _feedToken;
@synthesize connectionAvailable;
@synthesize dateFormatter;
@synthesize bookmarksUpdated;
@synthesize bookmarksUpdatedMessage;
@synthesize bookmarksLoading;
@synthesize readByDefault = _readByDefault;
@synthesize defaultFeed = _defaultFeed;
@synthesize openLinksInApp = _openLinksInApp;
@synthesize compressPosts = _compressPosts;
@synthesize openLinksWithMobilizer = _openLinksWithMobilizer;
@synthesize doubleTapToEdit = _doubleTapToEdit;

+ (NSString *)databasePath {
#if TARGET_IPHONE_SIMULATOR
    return @"/tmp/pinboard.db";
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        return [paths[0] stringByAppendingPathComponent:@"/pinboard.db"];
    }
    else {
        return @"/pinboard.db";
    }
#endif
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [application cancelAllLocalNotifications];
    if (application.applicationState == UIApplicationStateActive) {
        self.bookmarksUpdated = notification.userInfo[@"updated"];

        if ([notification.userInfo[@"success"] isEqual:@YES]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PPNotification sharedInstance] showInView:self.navigationController.view withMessage:notification.alertBody];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PPNotification sharedInstance] showInView:self.navigationController.view withMessage:notification.alertBody];
            });
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback {
    PPNavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark update:isUpdate delegate:delegate callback:callback];
    if (self.navigationController.presentedViewController) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [self.navigationController presentViewController:addBookmarkViewController animated:NO completion:nil];
        }];
    }
    else {
        [self.navigationController presentViewController:addBookmarkViewController animated:NO completion:nil];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }
    else if ([url.host isEqualToString:@"add"]) {
        didLaunchWithURL = YES;
        [self showAddBookmarkViewControllerWithBookmark:[self parseQueryParameters:url.query] update:@NO delegate:self callback:nil];
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
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:postViewController];

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
        if ([url.path isEqualToString:@"/add"]) {
            NSMutableDictionary *queryParameters = [self parseQueryParameters:url.query];
            [self showAddBookmarkViewControllerWithBookmark:queryParameters update:@NO delegate:self callback:^{
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
    else {
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
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
        
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
            if (!self.clipboardBookmarkURL || self.addBookmarkAlertViewIsVisible) {
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
            if (alreadyExistsInBookmarks) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = [NSString stringWithFormat:@"Not prompting to add as %@ is already in your bookmarks.", self.clipboardBookmarkURL];
                    notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                });
            }
            else if (alreadyRejected) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = @"\"Purge cache\" in settings if you'd like to add the URL on your clipboard.";
                    notification.userInfo = @{@"success": @YES, @"updated": @(NO)};
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                });
            }
            else {
                NSURL *candidateURL = [NSURL URLWithString:self.clipboardBookmarkURL];
                if (candidateURL && candidateURL.scheme && candidateURL.host) {
                    [[AppDelegate sharedDelegate] retrievePageTitle:candidateURL
                                                           callback:^(NSString *title, NSString *description) {
                                                               self.clipboardBookmarkTitle = title;
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [self.addBookmarkFromClipboardAlertView show];
                                                               });
                                                               
                                                               self.addBookmarkAlertViewIsVisible = YES;
                                                               [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                                           }];
                    
                }
            }
            [db close];
        });
    });
}

- (UIAlertView *)addBookmarkFromClipboardAlertView {
    static dispatch_once_t onceToken;
    static UIAlertView *_addBookmarkFromClipboardAlertView;
    dispatch_once(&onceToken, ^{
        _addBookmarkFromClipboardAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Bookmark?", nil) message:NSLocalizedString(@"We've detected a URL in your clipboard. Would you like to bookmark it?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Nope", nil) otherButtonTitles:NSLocalizedString(@"Sure", nil), nil];
    });
    return _addBookmarkFromClipboardAlertView;
}

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query {
    // Parse the individual parameters
    // parameters = @"hello=world&foo=bar";
    NSMutableDictionary *dictParameters = [[NSMutableDictionary alloc] initWithDictionary:@{@"url": @"", @"title": @"", @"description": @"", @"tags": @"", @"private": [self privateByDefault], @"unread": @(![[self readByDefault] boolValue]) }];
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
    settingsViewController.title = NSLocalizedString(@"Settings", nil);
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)customizeUIElements {
    //[self.window setTintColor:[UIColor whiteColor]];
    //[[UIView appearance] setTintColor:[UIColor whiteColor]];
    
    // UIToolbar items
    UIColor *barButtonItemColor = [UIColor colorWithRed:40/255.0f green:141/255.0f blue:219/255.0f alpha:1.0f];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setTintColor:barButtonItemColor];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0 green:0.5863 blue:1 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

- (UINavigationController *)navigationController {
    if (!_navigationController) {
        PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
        pinboardDataSource.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @(100), @"offset": @(0)}];
        
        FeedListViewController *feedListViewController = [[FeedListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        GenericPostViewController *pinboardViewController = [[GenericPostViewController alloc] init];
        
        _navigationController = [[PPNavigationController alloc] initWithRootViewController:feedListViewController];
        
        UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        titleButton.frame = CGRectMake(0, 0, 200, 24);
        titleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        titleButton.titleLabel.textColor = [UIColor whiteColor];
        titleButton.backgroundColor = [UIColor clearColor];
        titleButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        titleButton.adjustsImageWhenHighlighted = NO;
        pinboardViewController.navigationItem.titleView = titleButton;
        
        // Determine our default feed
        NSString *feedDetails;
        if ([[self.defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
            feedDetails = [self.defaultFeed substringFromIndex:9];
            if ([feedDetails isEqualToString:@"all"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                [titleButton setTitle:NSLocalizedString(@"All Bookmarks", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-all"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0x0096ffff)];
            } else if ([feedDetails isEqualToString:@"private"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(YES), @"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"Private Bookmarks", nil);
                [titleButton setTitle:NSLocalizedString(@"Private Bookmarks", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-private"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xffae46ff)];
            } else if ([feedDetails isEqualToString:@"public"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(NO), @"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"Public", nil);
                [titleButton setTitle:NSLocalizedString(@"Public", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-public"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0x7bb839ff)];
            } else if ([feedDetails isEqualToString:@"unread"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"unread": @(YES), @"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"Unread", nil);
                [titleButton setTitle:NSLocalizedString(@"Unread", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-unread"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xef6034ff)];
            } else if ([feedDetails isEqualToString:@"untagged"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"tagged": @(NO), @"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"Untagged", nil);
                [titleButton setTitle:NSLocalizedString(@"Untagged", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-untagged"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xacb3bbff)];
            } else if ([feedDetails isEqualToString:@"starred"]) {
                pinboardDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"starred": @(YES), @"limit": @(100), @"offset": @(0)}];
                pinboardViewController.title = NSLocalizedString(@"Starred", nil);
                [titleButton setTitle:NSLocalizedString(@"Starred", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-starred"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0x8361f4ff)];
            }
            
            pinboardViewController.postDataSource = pinboardDataSource;
        } else if ([[self.defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
            feedDetails = [self.defaultFeed substringFromIndex:10];
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] init];
            pinboardViewController.postDataSource = feedDataSource;
            
            if ([feedDetails isEqualToString:@"network"]) {
                NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", feedToken], [NSString stringWithFormat:@"u:%@", username], @"network"];
                pinboardViewController.title = NSLocalizedString(@"Network", nil);
                [titleButton setTitle:NSLocalizedString(@"Network", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-network"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0x30a1c1ff)];
            } else if ([feedDetails isEqualToString:@"popular"]) {
                feedDataSource.components = @[@"popular?count=100"];
                pinboardViewController.title = NSLocalizedString(@"Popular", nil);
                [titleButton setTitle:NSLocalizedString(@"Popular", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-popular"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xff9409ff)];
            } else if ([feedDetails isEqualToString:@"wikipedia"]) {
                feedDataSource.components = @[@"popular", @"wikipedia"];
                pinboardViewController.title = @"Wikipedia";
                [titleButton setTitle:@"Wikipedia" forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-wikipedia"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0x2ca881ff)];
            } else if ([feedDetails isEqualToString:@"fandom"]) {
                feedDataSource.components = @[@"popular", @"fandom"];
                pinboardViewController.title = NSLocalizedString(@"Fandom", nil);
                [titleButton setTitle:NSLocalizedString(@"Fandom", nil) forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-fandom"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xe062d6ff)];
            } else if ([feedDetails isEqualToString:@"japanese"]) {
                feedDataSource.components = @[@"popular", @"japanese"];
                pinboardViewController.title = @"日本語";
                [titleButton setTitle:@"日本語" forState:UIControlStateNormal];
                [titleButton setImage:[UIImage imageNamed:@"navigation-japanese"] forState:UIControlStateNormal];
                [self.navigationController.navigationBar setBarTintColor:HEX(0xff5353ff)];
            }
        } else if ([[self.defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
            feedDetails = [self.defaultFeed substringFromIndex:6];
            NSArray *components = [feedDetails componentsSeparatedByString:@"+"];
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] initWithComponents:components];
            pinboardViewController.postDataSource = feedDataSource;
            pinboardViewController.title = feedDetails;
        }
        
        feedListViewController.title = NSLocalizedString(@"Browse", nil);
        //_navigationController.navigationBar.translucent = NO;
        _navigationController.viewControllers = @[feedListViewController, pinboardViewController];
        [_navigationController popToViewController:pinboardViewController animated:NO];
    }
    return _navigationController;
}

- (UINavigationController *)loginViewController {
    if (!_loginViewController) {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        
        UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        controller.navigationBar.translucent = NO;
        
        _loginViewController = controller;
    }
    return _loginViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    application.applicationSupportsShakeToEdit = YES;
    [self becomeFirstResponder];
    self.bookmarksUpdated = @(NO);
    self.bookmarksUpdatedMessage = nil;
    self.addBookmarkAlertViewIsVisible = NO;

    [self migrateDatabase];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [self customizeUIElements];

    [TestFlight takeOff:@"575d650a-43d5-4e99-a3bb-2b7bbae29a6c"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"045e859e70632363c4809784b13c5e98"];
    [[PocketAPI sharedAPI] setConsumerKey:@"11122-03068da9a8951bec2dcc93f3"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{
        @"io.aurora.pinboard.OpenLinksInApp": @(YES),
        @"io.aurora.pinboard.PrivateByDefault": @(NO),
        @"io.aurora.pinboard.ReadByDefault": @(NO),
        @"io.aurora.pinboard.Browser": @(BROWSER_SAFARI),
        @"io.aurora.pinboard.CompressPosts": @(NO),
        @"io.aurora.pinboard.DimReadPosts": @(NO),
        @"io.aurora.pinboard.OpenLinksWithMobilizer": @(NO),
        @"io.aurora.pinboard.DoubleTapToEdit": @(NO),
     }];

    Reachability* reach = [Reachability reachabilityWithHostname:@"google.com"];
    self.connectionAvailable = @([reach isReachable]);
    reach.reachableBlock = ^(Reachability*reach) {
        self.connectionAvailable = @(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionStatusDidChangeNotification" object:nil];
    };

    reach.unreachableBlock = ^(Reachability*reach) {
        self.connectionAvailable = @(NO);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionStatusDidChangeNotification" object:nil];
    };
    [reach startNotifier];
    
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard setRequestCompletedCallback:^{
        [self setNetworkActivityIndicatorVisible:NO];
    }];
    [pinboard setRequestStartedCallback:^{
        [self setNetworkActivityIndicatorVisible:YES];
    }];

    if (self.token) {
        [pinboard setToken:self.token];
        [mixpanel identify:self.username];
        [mixpanel.people set:@"$username" to:self.username];
        [self.window setRootViewController:self.navigationController];
    }
    else {
        [self.window setRootViewController:self.loginViewController];
    }

     /*
    PPMultipleEditViewController *mevc = [[PPMultipleEditViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.window setRootViewController:mevc];
     */    
    [self.window makeKeyAndVisible];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

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
                [self setReadlater:@(READLATER_NONE)];
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
                db.logsErrors = YES;
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

            default:
                break;
        }
        [db commit];
    }
    
    [db close];
}

+ (AppDelegate *)sharedDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

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

- (void)setPrivateByDefault:(NSNumber *)privateByDefault {
    _privateByDefault = privateByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:privateByDefault forKey:@"io.aurora.pinboard.PrivateByDefault"];
    [defaults synchronize];
}

- (NSNumber *)privateByDefault {
    if (!_privateByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _privateByDefault = [defaults objectForKey:@"io.aurora.pinboard.PrivateByDefault"];
    }
    return _privateByDefault;
}

- (NSNumber *)openLinksInApp {
    if (!_openLinksInApp) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksInApp = [defaults objectForKey:@"io.aurora.pinboard.OpenLinksInApp"];
    }
    return _openLinksInApp;
}

- (void)setOpenLinksInApp:(NSNumber *)openLinksInApp {
    _openLinksInApp = openLinksInApp;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:openLinksInApp forKey:@"io.aurora.pinboard.OpenLinksInApp"];
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

- (void)setReadByDefault:(NSNumber *)readByDefault {
    _readByDefault = readByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:readByDefault forKey:@"io.aurora.pinboard.ReadByDefault"];
    [defaults synchronize];
}

- (NSNumber *)readByDefault {
    if (!_readByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _readByDefault = [defaults objectForKey:@"io.aurora.pinboard.ReadByDefault"];
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
    }
    return _defaultFeed;
}

- (NSString *)defaultFeedDescription {
    // Build a descriptive string for the default feed
    NSString *feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Personal", nil), @"All"];
    if (self.defaultFeed) {
        if ([[self.defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
            feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Personal", nil), [[self.defaultFeed substringFromIndex:9] capitalizedString]];
        } else if ([[self.defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
            NSString *communityDescription = [self.defaultFeed substringFromIndex:10];
            if ([communityDescription isEqualToString:@"japanese"]) {
                communityDescription = @"日本語";
            }
            feedDescription = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Community", nil), [communityDescription capitalizedString]];
        } else if ([[self.defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
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

- (void)setBrowser:(NSNumber *)browser {
    _browser = browser;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:browser forKey:@"io.aurora.pinboard.Browser"];
    [defaults synchronize];
}

- (NSNumber *)browser {
    if (!_browser) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _browser = [defaults objectForKey:@"io.aurora.pinboard.Browser"];
        
        if ([_browser isEqual:@(BROWSER_WEBVIEW)]) {
            _browser = @(BROWSER_SAFARI);
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

- (void)setReadlater:(NSNumber *)readlater {
    _readlater = readlater;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:readlater forKey:@"io.aurora.pinboard.ReadLater"];
    [defaults synchronize];
}

- (NSNumber *)readlater {
    if (!_readlater) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _readlater = [defaults objectForKey:@"io.aurora.pinboard.ReadLater"];
    }
    return _readlater;
}

- (void)setMobilizer:(NSNumber *)mobilizer {
    _mobilizer = mobilizer;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:mobilizer forKey:@"io.aurora.pinboard.Mobilizer"];
    [defaults synchronize];
}

- (NSNumber *)mobilizer {
    if (!_mobilizer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _mobilizer = [defaults objectForKey:@"io.aurora.pinboard.Mobilizer"];

        if (!_mobilizer) {
            _mobilizer = @(MOBILIZER_INSTAPAPER);
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
    return [[[self token] componentsSeparatedByString:@":"] objectAtIndex:0];
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
                               
                               if (!error) {
                                   HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];
                                   NSString *description = @"";

                                   if (!error) {
                                       HTMLNode *root = [parser head];
                                       HTMLNode *titleTag = [root findChildTag:@"title"];
                                       NSArray *metaTags = [root findChildTags:@"meta"];
                                       for (HTMLNode *tag in metaTags) {
                                           if ([[tag getAttributeNamed:@"name"] isEqualToString:@"description"]) {
                                               description = [[tag getAttributeNamed:@"content"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                               break;
                                           }
                                       }
                                       
                                       if (titleTag && titleTag.contents) {
                                           callback([titleTag.contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], description);
                                       }
                                       else {
                                           callback(@"", description);
                                       }
                                   }
                               }
                               else {
                                   callback(@"", @"");
                               }
                           }];
}

- (void)closeModal:(UIViewController *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.addBookmarkFromClipboardAlertView) {
        self.addBookmarkAlertViewIsVisible = NO;
        if (buttonIndex == 1) {
            PPNavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"url": self.clipboardBookmarkURL, @"title": self.clipboardBookmarkTitle} update:@(NO) delegate:self callback:nil];
            
            if ([UIApplication isIPad]) {
                addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            }

            [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
            [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
        }
        else {
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
            [db close];
        }
    }
}

@end

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
#import "PPCachingURLProtocol.h"
#import "PPURLCache.h"

#import "NSString+URLEncoding2.h"
#import <LHSDelicious/LHSDelicious.h>
#import <ASPinboard/ASPinboard.h>
#import <Reachability/Reachability.h>
#import <PocketAPI/PocketAPI.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <OpenInChrome/OpenInChromeController.h>
#import <LHSCategoryCollection/UIViewController+LHSAdditions.h>
#import <Crashlytics/Crashlytics.h>
#import "MFMailComposeViewController+Theme.h"
#import <LHSDiigo/LHSDiigoClient.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>

@interface PPAppDelegate ()

@property (nonatomic, strong) PPNavigationController *feedListNavigationController;
@property (nonatomic, strong) UIViewController *presentingController;
@property (nonatomic) BOOL addOrEditPromptVisible;

@end

@implementation PPAppDelegate

@synthesize splitViewController = _splitViewController;

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
    void (^PresentView)(UIViewController *vc, UINavigationController *navController) = ^(UIViewController *vc, UINavigationController *navController) {
        if ([UIApplication isIPad]) {
            UINavigationController *navigationController = [PPAppDelegate sharedDelegate].navigationController;
            if (navigationController.viewControllers.count == 1) {
                UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
                if (showPopoverBarButtonItem) {
                    vc.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
                }
            }
            
            [navigationController setViewControllers:@[vc] animated:YES];
            
            if ([vc respondsToSelector:@selector(postDataSource)]) {
                if ([[(PPGenericPostViewController *)vc postDataSource] respondsToSelector:@selector(barTintColor)]) {
                    [self.feedListNavigationController.navigationBar setBarTintColor:[[(PPGenericPostViewController *)vc postDataSource] barTintColor]];
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
    else if ([url.host isEqualToString:@"search"]) {
        NSDictionary *data = [self parseQueryParameters:url.query];
        PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
        PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
        dataSource.limit = 100;
        if (data[@"q"]) {
            dataSource.searchQuery = data[@"q"];
        }
        else if (data[@"name"]) {
            __block NSDictionary *search;
            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *searchResults = [db executeQuery:@"SELECT * FROM searches WHERE name=?" withArgumentsInArray:@[data[@"name"]]];
                while ([searchResults next]) {
                    NSString *name = [searchResults stringForColumn:@"name"];
                    NSString *query = [searchResults stringForColumn:@"query"];
                    kPushpinFilterType private = [searchResults intForColumn:@"private"];
                    kPushpinFilterType unread = [searchResults intForColumn:@"unread"];
                    kPushpinFilterType starred = [searchResults intForColumn:@"starred"];
                    kPushpinFilterType tagged = [searchResults intForColumn:@"tagged"];
                    
                    search = @{@"name": name,
                               @"query": query,
                               @"private": @(private),
                               @"unread": @(unread),
                               @"starred": @(starred),
                               @"tagged": @(tagged) };
                }
            }];

            NSString *searchQuery = search[@"query"];
            if (searchQuery && ![searchQuery isEqualToString:@""]) {
                dataSource.searchQuery = search[@"query"];
            }
            
            dataSource.unread = [search[@"unread"] integerValue];
            dataSource.isPrivate = [search[@"private"] integerValue];
            dataSource.starred = [search[@"starred"] integerValue];
            
            kPushpinFilterType tagged = [search[@"tagged"] integerValue];
            switch (tagged) {
                case kPushpinFilterTrue:
                    dataSource.untagged = kPushpinFilterFalse;
                    break;
                    
                case kPushpinFilterFalse:
                    dataSource.untagged = kPushpinFilterTrue;
                    break;
                    
                case kPushpinFilterNone:
                    dataSource.untagged = kPushpinFilterNone;
                    break;
            }
        }
        
        postViewController.postDataSource = dataSource;
        postViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                                               style:UIBarButtonItemStyleDone
                                                                                              target:self
                                                                                              action:@selector(closeModal:)];
        PPNavigationController *navController = [[PPNavigationController alloc] initWithRootViewController:postViewController];

        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                PresentView(postViewController, navController);
            }];
        }
        else {
            PresentView(postViewController, navController);
        }
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

        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                PresentView(postViewController, navController);
            }];
        }
        else {
            PresentView(postViewController, navController);
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

            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                           message:message];

            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
            
            [[UIViewController lhs_topViewController] presentViewController:alert animated:YES completion:nil];
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Copy over the database file to the shared container URL
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
    NSURL *newDatabaseURL = [containerURL URLByAppendingPathComponent:@"shared.db"];
    NSURL *databaseURL = [NSURL fileURLWithPath:[PPUtilities databasePath]];
    NSError *error;

    [[NSFileManager defaultManager] removeItemAtURL:newDatabaseURL error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:databaseURL
                                            toURL:newDatabaseURL
                                            error:&error];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Copy over the database file to the shared container URL
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
    NSURL *newDatabaseURL = [containerURL URLByAppendingPathComponent:@"shared.db"];
    NSURL *databaseURL = [NSURL fileURLWithPath:[PPUtilities databasePath]];
    NSError *error;

    [[NSFileManager defaultManager] removeItemAtURL:newDatabaseURL error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:databaseURL
                                            toURL:newDatabaseURL
                                            error:&error];

    PPSettings *settings = [PPSettings sharedSettings];
    if (settings.isAuthenticated) {
        if (!didLaunchWithURL && !self.hideURLPrompt && !settings.turnOffBookmarkPrompt) {
            [self promptUserToAddBookmark];
            didLaunchWithURL = NO;
        }

        if (settings.offlineReadingEnabled) {
            [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        }
        else {
            [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        }
    }
}

- (void)promptUserToAddBookmark {
    dispatch_async(dispatch_get_main_queue(), ^{
        // XXX EXC_BAD_ACCESS
        self.clipboardBookmarkURL = [UIPasteboard generalPasteboard].string;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!self.clipboardBookmarkURL || self.addOrEditPromptVisible) {
                return;
            }
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            __block BOOL alreadyExistsInBookmarks;
            __block BOOL alreadyRejected;

            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
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
                    
                    UIAlertController *alertController = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                           message:message];
                    
                    [alertController lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action) {
                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                                                                [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                                                            }];
                                                        });
                                                    }];
                    
                    [alertController lhs_addActionWithTitle:NSLocalizedString(@"Edit", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController updateBookmarkViewControllerWithURLString:self.clipboardBookmarkURL callback:nil];
                                                        
                                                        if ([UIApplication isIPad]) {
                                                            addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                                                        }
                                                        
                                                        [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
                                                        [[Mixpanel sharedInstance] track:@"Decided to edit bookmark from clipboard"];
                                                    }];

                    [[UIViewController lhs_topViewController] presentViewController:alertController animated:YES completion:nil];
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
                                                  
                                                  UIAlertController *alertController = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                                                         message:message];
                                                  
                                                  [alertController lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                    style:UIAlertActionStyleCancel
                                                                                  handler:^(UIAlertAction *action) {
                                                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                                          [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                                                                                              [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.clipboardBookmarkURL]];
                                                                                          }];
                                                                                      });
                                                                                      
                                                                                      self.addOrEditPromptVisible = NO;
                                                                                  }];
                                                  
                                                  [alertController lhs_addActionWithTitle:NSLocalizedString(@"Add", nil)
                                                                                    style:UIAlertActionStyleDefault
                                                                                  handler:^(UIAlertAction *action) {
                                                                                      PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"url": self.clipboardBookmarkURL, @"title": self.clipboardBookmarkTitle} update:@(NO) callback:nil];
                                                                                      
                                                                                      if ([UIApplication isIPad]) {
                                                                                          addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                                                                                      }
                                                                                      
                                                                                      [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
                                                                                      [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
                                                                                      
                                                                                      self.addOrEditPromptVisible = NO;
                                                                                  }];

                                                  [[UIViewController lhs_topViewController] presentViewController:alertController animated:YES completion:^{
                                                      self.addOrEditPromptVisible = YES;
                                                  }];
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
        if ([settings.defaultFeed hasPrefix:@"personal-"]) {
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
        else if ([[PPSettings sharedSettings].defaultFeed hasPrefix:@"community-"]) {
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
        else if ([settings.defaultFeed hasPrefix:@"saved-"]) {
            feedDetails = [settings.defaultFeed substringFromIndex:6];
            NSArray *components = [feedDetails componentsSeparatedByString:@"+"];
            PPPinboardFeedDataSource *feedDataSource = [[PPPinboardFeedDataSource alloc] initWithComponents:components];
            pinboardViewController.postDataSource = feedDataSource;
        }
        else if ([settings.defaultFeed hasPrefix:@"search-"]) {
            feedDetails = [settings.defaultFeed substringFromIndex:7];

            __block NSDictionary *search;
            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *result = [db executeQuery:@"SELECT * FROM searches WHERE name=?" withArgumentsInArray:@[feedDetails]];
                while ([result next]) {
                    NSString *name = [result stringForColumn:@"name"];
                    NSString *query = [result stringForColumn:@"query"];
                    kPushpinFilterType private = [result intForColumn:@"private"];
                    kPushpinFilterType unread = [result intForColumn:@"unread"];
                    kPushpinFilterType starred = [result intForColumn:@"starred"];
                    kPushpinFilterType tagged = [result intForColumn:@"tagged"];
                    
                    search = @{@"name": name,
                               @"query": query,
                               @"private": @(private),
                               @"unread": @(unread),
                               @"starred": @(starred),
                               @"tagged": @(tagged) };
                }
            }];
            
            PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
            dataSource.limit = 100;
            NSString *searchQuery = search[@"query"];
            if (searchQuery && ![searchQuery isEqualToString:@""]) {
                dataSource.searchQuery = search[@"query"];
            }
            
            dataSource.unread = [search[@"unread"] integerValue];
            dataSource.isPrivate = [search[@"private"] integerValue];
            dataSource.starred = [search[@"starred"] integerValue];
            
            kPushpinFilterType tagged = [search[@"tagged"] integerValue];
            switch (tagged) {
                case kPushpinFilterTrue:
                    dataSource.untagged = kPushpinFilterFalse;
                    break;
                    
                case kPushpinFilterFalse:
                    dataSource.untagged = kPushpinFilterTrue;
                    break;
                    
                case kPushpinFilterNone:
                    dataSource.untagged = kPushpinFilterNone;
                    break;
            }

            pinboardViewController.postDataSource = dataSource;
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
    PPSettings *settings = [PPSettings sharedSettings];

    [Crashlytics startWithAPIKey:@"ed1bff5018819b0c5dbb8dbb35edac18a8b1af02"];

    [self becomeFirstResponder];
    self.bookmarksUpdated = NO;
    self.hideURLPrompt = NO;
    self.bookmarksUpdatedMessage = nil;
    self.addOrEditPromptVisible = NO;
    self.textExpander = [[SMTEDelegateController alloc] init];

    [PPUtilities migrateDatabase];

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
        @"io.aurora.pinboard.HidePrivateLock": @(NO),
        @"io.aurora.pinboard.DimReadPosts": @(NO),
        @"io.aurora.pinboard.OpenLinksWithMobilizer": @(NO),
        @"io.aurora.pinboard.DoubleTapToEdit": @(NO),
        @"io.aurora.pinboard.BrowseFontName": @"AvenirNext-Regular",
        @"io.aurora.pinboard.FontName": @"AvenirNext-Regular",
        @"io.aurora.pinboard.BoldFontName": @"AvenirNext-Medium",
        
        // If a user decides not to add a bookmark when it's on the clipboard, don't ask again.
        @"io.aurora.pinboard.OnlyPromptToAddOnce": @(YES),
        @"io.aurora.pinboard.TurnOffBookmarkPrompt": @(NO),
        @"io.aurora.pinboard.AlwaysShowClipboardNotification": @(YES),
        @"io.aurora.pinboard.HiddenFeedNames": @[],
        @"io.aurora.pinboard.FontAdjustment": @(PPFontAdjustmentMedium),
        @"io.aurora.pinboard.OfflineUsageLimit": @(100 * 1000 * 1000),
        @"io.aurora.pinboard.OfflineFetchCriteria": @(PPOfflineFetchCriteriaUnread),
        @"io.aurora.pinboard.UseCellularDataForOffline": @(NO),
        @"io.aurora.pinboard.OfflineReadingEnabled": @(NO),
        @"io.aurora.pinboard.DownloadFullWebpageForOffline": @(NO),
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

    [PPURLCache migrateDatabase];
    self.urlCache = [[PPURLCache alloc] initWithMemoryCapacity:0
                                                  diskCapacity:[PPSettings sharedSettings].offlineUsageLimit
                                                      diskPath:@"urlcache"];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:[[PPSettings sharedSettings] token] forKey:@"token"];
    
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];

    [NSURLProtocol registerClass:[PPCachingURLProtocol class]];

    Reachability *reach = [Reachability reachabilityForInternetConnection];
    self.connectionAvailable = [reach isReachable];
    reach.reachableBlock = ^(Reachability *reach) {
        self.connectionAvailable = YES;
#if !FORCE_OFFLINE
//        [NSURLProtocol unregisterClass:[PPCachingURLProtocol class]];
#endif
    };

    reach.unreachableBlock = ^(Reachability *reach) {
        self.connectionAvailable = NO;
#if !FORCE_OFFLINE
//        [NSURLProtocol registerClass:[PPCachingURLProtocol class]];
#endif
    };
    [reach startNotifier];
    
#if FORCE_OFFLINE
    [NSURLProtocol registerClass:[PPCachingURLProtocol class]];
#endif
    
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

- (void)logout {
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    [self.urlCache removeAllCachedResponses];

#ifdef DELICIOUS
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"DeliciousCredentials" accessGroup:nil];
#endif
    
#ifdef PINBOARD
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
#endif

    [PPUtilities resetDatabase];

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

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    PPURLCache *cache = self.urlCache;
    [cache initiateBackgroundDownloadsWithCompletion:^(NSInteger count) {
        if (count > 0) {
            completionHandler(UIBackgroundFetchResultNewData);
        }
        else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    } progress:nil];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    self.urlCache.backgroundURLSessionCompletionHandlers[identifier] = completionHandler;
    completionHandler();
}

@end

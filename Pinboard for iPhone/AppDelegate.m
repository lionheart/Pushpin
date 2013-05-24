//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ASPinboard/ASPinboard.h>
#import "AppDelegate.h"
#import "NoteViewController.h"
#import "LoginViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Reachability.h"
#import "TestFlight.h"
#import "PocketAPI.h"
#import "HTMLParser.h"
#import "SettingsViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PPNotification.h"
#import "FeedListViewController.h"
#import "AddBookmarkViewController.h"
#import "PPWebViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize readlater = _readlater;
@synthesize token = _token;
@synthesize browser = _browser;
@synthesize mobilizer = _mobilizer;
@synthesize lastUpdated = _lastUpdated;
@synthesize privateByDefault = _privateByDefault;
@synthesize feedToken = _feedToken;
@synthesize connectionAvailable;
@synthesize dateFormatter;
@synthesize bookmarksUpdated;
@synthesize bookmarksUpdatedMessage;
@synthesize bookmarksLoading;
@synthesize readByDefault = _readByDefault;
@synthesize openLinksInApp = _openLinksInApp;

+ (NSString *)databasePath {
#if TARGET_IPHONE_SIMULATOR
    return @"/tmp/pinboard.db";
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:@"/pinboard.db"];
#endif
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [application cancelAllLocalNotifications];
    if (application.applicationState == UIApplicationStateActive && !self.bookmarksUpdated.boolValue) {
        self.bookmarksUpdated = notification.userInfo[@"updated"];

        if ([notification.userInfo[@"success"] isEqual:@YES]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[PPNotification sharedInstance] showInView:self.navigationController.view withMessage:notification.alertBody];
                });
            });
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[PPNotification sharedInstance] showInView:self.navigationController.view withMessage:notification.alertBody];
                });
            });
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback {
    UINavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark update:isUpdate delegate:delegate callback:callback];
    [self.navigationController presentViewController:addBookmarkViewController animated:YES completion:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }
    else if ([url.host isEqualToString:@"add"]) {
        didLaunchWithURL = YES;
        [self showAddBookmarkViewControllerWithBookmark:[self parseQueryParameters:url.query] update:@NO delegate:self callback:nil];
    }
    else if ([url.host isEqualToString:@"x-callback-url"]) {
        didLaunchWithURL = YES;
        if ([url.path isEqualToString:@"/add"]) {
            NSMutableDictionary *queryParameters = [self parseQueryParameters:url.query];
            [self showAddBookmarkViewControllerWithBookmark:queryParameters update:@NO delegate:nil callback:^{
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
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (!didLaunchWithURL && self.token != nil) {
        [self promptUserToAddBookmark];
        didLaunchWithURL = NO;
    }
}

- (void)promptUserToAddBookmark {
    self.clipboardBookmarkURL = [UIPasteboard generalPasteboard].string;
    if (!self.clipboardBookmarkURL) {
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
    if (!alreadyExistsInBookmarks && !alreadyRejected) {
        NSURL *candidateURL = [NSURL URLWithString:self.clipboardBookmarkURL];
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            [[AppDelegate sharedDelegate] retrievePageTitle:candidateURL
                                                   callback:^(NSString *title, NSString *description) {
                                                       self.clipboardBookmarkTitle = title;
                                                       [self.addBookmarkFromClipboardAlertView show];
                                                       [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                                   }];
            
        }
    }
    [db close];
}

- (WCAlertView *)addBookmarkFromClipboardAlertView {
    if (!_addBookmarkFromClipboardAlertView) {
        _addBookmarkFromClipboardAlertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"URL in Clipboard Title", nil) message:NSLocalizedString(@"URL in Clipboard Message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Lighthearted No", nil) otherButtonTitles:NSLocalizedString(@"Lighthearted Yes", nil), nil];
    }
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
            [strValue setString:[[[arrKeyValue objectAtIndex:1]  stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
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
    // Customize UINavigationBar
    CGRect rect = CGRectMake(0, 0, 320, 44);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] =	{
        0.996, 0.996, 0.996, 1.0,
        0.804, 0.827, 0.875, 1.0
    };
    CGFloat lineColorComponents[8] = {
        0.996, 0.996, 0.996, 1,
        0.882, 0.898, 0.925, 1
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
    CGGradientRef lineGradient = CGGradientCreateWithColorComponents(myColorspace, lineColorComponents, locations, num_locations);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(0, 44);
    
    CGFloat radius = 4;
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x + radius, rect.origin.y, radius);
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y + radius, radius);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    // Add bottom stroke
    CGContextSetRGBStrokeColor(context, 0.161, 0.176, 0.318, 1);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextStrokePath(context);

    UIImage *background = UIGraphicsGetImageFromCurrentImageContext();

    [[UINavigationBar appearance] setBackgroundColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBackgroundImage:background forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                     UITextAttributeFont: [UIFont fontWithName:@"Avenir-Heavy" size:20],
                                UITextAttributeTextColor: HEX(0x4C586Aff),
                          UITextAttributeTextShadowColor: [UIColor whiteColor] }];

    // Customize Tool Bar
    CGContextSetRGBStrokeColor(context, 0.161, 0.176, 0.318, 1);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextStrokePath(context);
    UIImage *toolbarBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [[UIToolbar appearance] setBackgroundImage:toolbarBackground forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    // Customize Status Bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    // Customize UIBarButtonItem
    UIImage *backButtonBackground = [UIImage imageNamed:@"navigation-back-button"];
    UIImage *selectedBackButtonImage = [UIImage imageNamed:@"navigation-back-button-selected"];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(backButtonBackground.size.width, 44), NO, 0);
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, backButtonBackground.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, backButtonBackground.size.width, 44), backButtonBackground.CGImage);

    UIImage *newBackground = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(selectedBackButtonImage.size.width, selectedBackButtonImage.size.height), NO, 0);
    context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0.0, selectedBackButtonImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, selectedBackButtonImage.size.width, selectedBackButtonImage.size.height), selectedBackButtonImage.CGImage);

    UIImage *selectedBackground = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];

    UIGraphicsEndImageContext();

    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:newBackground forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:selectedBackground forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-100, -100) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTintColor:HEX(0xEAECF1FF)];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                UITextAttributeTextColor: HEX(0x4A5768FF),
                          UITextAttributeTextShadowColor: HEX(0xFFFFFF00),
                                     UITextAttributeFont: [UIFont fontWithName:@"Avenir-Heavy" size:13]
     }
                                                forState:UIControlStateNormal];
    
    [WCAlertView setDefaultCustomiaztonBlock:^(WCAlertView *alertView) {
        alertView.cornerRadius = 8;
        alertView.outerFrameShadowBlur = 0;
        alertView.labelTextColor = [UIColor whiteColor];
        alertView.labelShadowColor = [UIColor clearColor];
        
        alertView.buttonFont = [UIFont fontWithName:@"Avenir-Heavy" size:18.f];
        alertView.titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:18.f];
        alertView.messageFont = [UIFont fontWithName:@"Avenir-Medium" size:16.f];
        
        UIColor *topGradient = [UIColor colorWithRed:0.212 green:0.227 blue:0.275 alpha:1];
        UIColor *middleGradient = [UIColor colorWithRed:0.173 green:0.184 blue:0.224 alpha:1];
        UIColor *bottomGradient = [UIColor colorWithRed:0.114 green:0.125 blue:0.161 alpha:1];
        alertView.gradientColors = @[topGradient, middleGradient, bottomGradient];
        alertView.outerFrameColor = [UIColor whiteColor];
        alertView.innerFrameShadowColor = [UIColor clearColor];
        alertView.innerFrameStrokeColor = [UIColor clearColor];
        alertView.outerFrameLineWidth = 1;
        
        alertView.buttonTextColor = [UIColor whiteColor];
        alertView.buttonShadowColor = [UIColor blackColor];
        alertView.buttonShadowOffset = CGSizeMake(1, 1);
    }];
}

- (UINavigationController *)navigationController {
    if (!_navigationController) {
        PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
        pinboardDataSource.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @(100), @"offset": @(0)}];
        
        GenericPostViewController *pinboardViewController = [[GenericPostViewController alloc] init];
        pinboardViewController.postDataSource = pinboardDataSource;
        pinboardViewController.title = NSLocalizedString(@"All Bookmarks", nil);
        
        FeedListViewController *feedListViewController = [[FeedListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        feedListViewController.title = @"Browse";
        _navigationController = [[UINavigationController alloc] initWithRootViewController:feedListViewController];
        _navigationController.viewControllers = @[feedListViewController, pinboardViewController];
        [_navigationController popToViewController:pinboardViewController animated:NO];
    }
    return _navigationController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [self migrateDatabase];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [self customizeUIElements];

    [TestFlight takeOff:@"a4d1862d-30d8-4984-9e33-dba8872d2538"];
#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"045e859e70632363c4809784b13c5e98"];
    [[PocketAPI sharedAPI] setConsumerKey:@"11122-03068da9a8951bec2dcc93f3"];

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

    if ([self token]) {
        [pinboard setToken:[self token]];
        [mixpanel identify:self.username];
        [mixpanel.people set:@"$username" to:self.username];
        [self.window setRootViewController:self.navigationController];
    }
    else {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        [self.window setRootViewController:loginViewController];
    }
    
    [self.window makeKeyAndVisible];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    self.bookmarksUpdated = @(NO);
    self.bookmarksUpdatedMessage = nil;

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
        
        if (!_privateByDefault) {
            _privateByDefault = @(NO);
        }
    }
    return _privateByDefault;
}

- (NSNumber *)openLinksInApp {
    if (!_openLinksInApp) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksInApp = [defaults objectForKey:@"io.aurora.pinboard.OpenLinksInApp"];
        if (!_openLinksInApp) {
            _openLinksInApp = @(YES);
        }
    }
    return _openLinksInApp;
}

- (void)setOpenLinksInApp:(NSNumber *)openLinksInApp {
    _openLinksInApp = openLinksInApp;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:openLinksInApp forKey:@"io.aurora.pinboard.OpenLinksInApp"];
    [defaults synchronize];
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

        if (!_readByDefault) {
            _readByDefault = @(NO);
        }
    }
    return _readByDefault;
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
        
        if (!_browser || [_browser isEqual:@(BROWSER_WEBVIEW)]) {
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
            _mobilizer = @(MOBILIZER_GOOGLE);
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
    
    // The assertion helps to find programmer errors in activity indicator management.
    // Since a negative NumberOfCallsToSetVisible is not a fatal error,
    // it should probably be removed from production code.
//    NSAssert(NumberOfCallsToSetVisible >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    
    // Display the indicator as long as our static counter is > 0.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
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
                                               description = [tag getAttributeNamed:@"content"];
                                               break;
                                           }
                                       }
                                       
                                       if (titleTag != nil) {
                                           callback(titleTag.contents, description);
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
        if (buttonIndex == 1) {
            UINavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"url": self.clipboardBookmarkURL, @"title": self.clipboardBookmarkTitle} update:@(NO) delegate:self callback:nil];
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

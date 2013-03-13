//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ASPinboard/ASPinboard.h>
#import "AppDelegate.h"
#import "BookmarkViewController.h"
#import "HomeViewController.h"
#import "NoteViewController.h"
#import "LoginViewController.h"
#import "PrimaryNavigationViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Reachability.h"
#import "TestFlight.h"
#import "PocketAPI.h"
#import "ZAActivityBar.h"
#import "HTMLParser.h"
#import "SettingsViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"

@implementation AppDelegate

@synthesize window;
@synthesize readlater = _readlater;
@synthesize token = _token;
@synthesize browser = _browser;
@synthesize lastUpdated = _lastUpdated;
@synthesize privateByDefault = _privateByDefault;
@synthesize feedToken = _feedToken;
@synthesize connectionAvailable;
@synthesize dateFormatter;
@synthesize bookmarksUpdated;
@synthesize bookmarksUpdatedMessage;
@synthesize dbQueue;
@synthesize bookmarksLoading;
@synthesize readByDefault = _readByDefault;
@synthesize navigationViewController;

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
                    [ZAActivityBar showSuccessWithStatus:notification.alertBody];
                });
            });
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ZAActivityBar showErrorWithStatus:notification.alertBody];
                });
            });
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    [self.navigationViewController showAddBookmarkViewControllerWithBookmark:bookmark update:isUpdate callback:callback];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }
    else if ([url.host isEqualToString:@"add"]) {
        didLaunchWithURL = YES;
        [self showAddBookmarkViewControllerWithBookmark:[self parseQueryParameters:url.query] update:@(NO) callback:nil];
    }
    else if ([url.host isEqualToString:@"x-callback-url"]) {
        didLaunchWithURL = YES;
        if ([url.path isEqualToString:@"/add"]) {
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
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (!didLaunchWithURL && self.token != nil) {
        [self.navigationViewController promptUserToAddBookmark];
        didLaunchWithURL = NO;
    }
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
    [self.navigationViewController pushViewController:settingsViewController animated:YES];
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

    CGContextSetRGBStrokeColor(context, 0.161, 0.176, 0.318, 1);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextStrokePath(context);

    UIImage *background = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    [[UINavigationBar appearance] setBackgroundColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBackgroundImage:background forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                     UITextAttributeFont: [UIFont fontWithName:@"Avenir-Heavy" size:20],
                                UITextAttributeTextColor: HEX(0x4C586Aff),
                          UITextAttributeTextShadowColor: [UIColor whiteColor] }];

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

    CGContextSetLineWidth(context, 1);
    CGContextSetRGBStrokeColor(context, 0.69, 0.69, 0.741, 1);
    CGContextMoveToPoint(context, backButtonBackground.size.width - 1.5, 0);
    CGContextAddLineToPoint(context, backButtonBackground.size.width - 1.5, backButtonBackground.size.height);
    CGContextStrokePath(context);

    UIImage *newBackground = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, backButtonBackground.size.width, 0, 0) resizingMode:UIImageResizingModeStretch];
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(selectedBackButtonImage.size.width, selectedBackButtonImage.size.height), NO, 0);
    context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0.0, selectedBackButtonImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, selectedBackButtonImage.size.width, selectedBackButtonImage.size.height), selectedBackButtonImage.CGImage);
    
    CGContextSetLineWidth(context, 1);
    CGContextSetRGBStrokeColor(context, 0.69, 0.69, 0.741, 1);
    CGContextMoveToPoint(context, selectedBackButtonImage.size.width - 1.5, 0);
    CGContextAddLineToPoint(context, selectedBackButtonImage.size.width - 1.5, selectedBackButtonImage.size.height);
    CGContextStrokePath(context);
    UIImage *selectedBackground = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, selectedBackButtonImage.size.width, 0, 0)];

    UIGraphicsEndImageContext();

    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:newBackground forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:selectedBackground forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-100, -100) forBarMetrics:UIBarMetricsDefault];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [self customizeUIElements];

    [TestFlight takeOff:@"a4d1862d-30d8-4984-9e33-dba8872d2538"];
#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"045e859e70632363c4809784b13c5e98"];
    [[PocketAPI sharedAPI] setConsumerKey:@"11122-03068da9a8951bec2dcc93f3"];

    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
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
        [mixpanel.people identify:self.username];
        [mixpanel.people set:@"$username" to:self.username];

        PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
        pinboardDataSource.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @(100), @"offset": @(0)}];

        GenericPostViewController *pinboardViewController = [[GenericPostViewController alloc] init];
        pinboardViewController.postDataSource = pinboardDataSource;
        pinboardViewController.title = @"Bookmarks";
        
        HomeViewController *homeViewController = [[HomeViewController alloc] init];
        homeViewController.title = @"Browse";
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:homeViewController];
        navigationController.viewControllers = @[homeViewController, pinboardViewController];
        [navigationController popToViewController:pinboardViewController animated:NO];

        [self.window setRootViewController:navigationController];
        
        /*

        BookmarkViewController *allBookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:nil];
        allBookmarkViewController.title = NSLocalizedString(@"All Bookmarks", nil);

        HomeViewController *homeViewController = [[HomeViewController alloc] init];
        homeViewController.title = NSLocalizedString(@"Browse Tab Bar Title", nil);
        homeViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cog-white"] style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];

        self.navigationViewController = [[PrimaryNavigationViewController alloc] initWithRootViewController:homeViewController];

        [self.navigationViewController setViewControllers:@[homeViewController, allBookmarkViewController]];
        [self.navigationViewController popToViewController:allBookmarkViewController animated:NO];
        [self.window setRootViewController:self.navigationViewController];
        [self resumeRefreshTimer];
         */
    }
    else {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        [self.window setRootViewController:loginViewController];
        [self pauseRefreshTimer];
    }

    secondsLeft = 10;
    self.refreshTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
    
    [self.window makeKeyAndVisible];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    self.bookmarksUpdated = @(NO);
    self.bookmarksUpdatedMessage = nil;
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[AppDelegate databasePath]];

    [self migrateDatabase];
    
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
    [db executeUpdate:@"PRAGMA cache_size = 100;"];

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
                     "PRIMARY KEY(tag_id, bookmark_id),"
                     "FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,"
                     "FOREIGN KEY (bookmark_id) REFERENCES bookmarks(id) ON DELETE CASCADE"
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

                [db executeUpdate:@"PRAGMA foreign_keys=1;"];

                // http://stackoverflow.com/a/875422/39155
                [db executeUpdate:@"PRAGMA syncronous=1;"];
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
        
        if (!_browser) {
            _browser = @(BROWSER_WEBVIEW);
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

- (void)updateNotes {
    if (!self.connectionAvailable.boolValue) {
        // TODO
        return;
    }
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard notesWithSuccess:^(NSArray *notes) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_current_queue(), ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                [db beginTransaction];
                
                for (id note in notes) {
                    NSDictionary *params = @{
                                             @"remote_id": note[@"id"],
                                             @"title": note[@"title"],
                                             @"length": note[@"length"],
                                             @"hash": note[@"hash"],
                                             @"text": note[@"text"],
                                             @"created_at": [self.dateFormatter dateFromString:note[@"created_on"]],
                                             @"updated_at": [self.dateFormatter dateFromString:note[@"updated_on"]]
                                             };
                    
                    [db executeUpdate:@"INSERT INTO note (title, length, hash, text, created_at, updated_at) VALUES (:title, :length, :hash, :text, :created_at, :updated_at);" withParameterDictionary:params];
                }
                
                [db commit];
                [db close];
            });
        });
    }];
}

- (void)forceUpdateBookmarks:(id<BookmarkUpdateProgressDelegate>)updateDelegate {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (self.lastUpdated != nil) {
        self.bookmarksLoading = YES;
    }
    
    void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *elements) {
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db beginTransaction];

        db.logsErrors = NO;
        [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];

        FMResultSet *results;

        results = [db executeQuery:@"SELECT * FROM tag"];
        NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];

        while ([results next]) {
            [tags setObject:@([results intForColumn:@"id"]) forKey:[results stringForColumn:@"name"]];
        }
        results = [db executeQuery:@"SELECT meta, hash FROM bookmark ORDER BY created_at DESC"];

        NSMutableDictionary *metas = [[NSMutableDictionary alloc] init];
        NSMutableArray *oldBookmarkHashes = [[NSMutableArray alloc] init];
        while ([results next]) {
            [oldBookmarkHashes addObject:[results stringForColumn:@"hash"]];
            [metas setObject:[results stringForColumn:@"meta"] forKey:[results stringForColumn:@"hash"]];
        }
        NSMutableArray *bookmarksToDelete = [[NSMutableArray alloc] init];

        NSString *bookmarkMeta;
        NSNumber *tagIdNumber;
        BOOL updated_or_created = NO;
        NSUInteger count = 0;
        NSUInteger skipCount = 0;
        NSUInteger newBookmarkCount = 0;
        NSUInteger total = elements.count;
        NSDictionary *params;

        [mixpanel.people set:@"Bookmarks" to:@(total)];

        for (NSDictionary *element in elements) {
            updated_or_created = NO;
            count++;
            
            if (updateDelegate) {
                [updateDelegate bookmarkUpdateEvent:@(count) total:@(total)];
            }
            
            bookmarkMeta = metas[element[@"hash"]];
            if (bookmarkMeta) {
                while (skipCount < oldBookmarkHashes.count && ![oldBookmarkHashes[skipCount] isEqualToString:element[@"hash"]]) {
                    [bookmarksToDelete addObject:oldBookmarkHashes[skipCount]];
                    skipCount++;
                }
                skipCount++;
                
                if (![bookmarkMeta isEqualToString:element[@"meta"]]) {
                    updated_or_created = YES;
                    params = @{
                               @"url": element[@"href"],
                               @"title": element[@"description"],
                               @"description": element[@"extended"],
                               @"meta": element[@"meta"],
                               @"hash": element[@"hash"],
                               @"tags": element[@"tags"],
                               @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                               @"private": @([element[@"shared"] isEqualToString:@"no"])
                               };
                    
                    [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta WHERE hash=:hash" withParameterDictionary:params];
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_id IN (SELECT id FROM bookmark WHERE hash=?)" withArgumentsInArray:@[element[@"hash"]]];
                }
            }
            else {
                newBookmarkCount++;
                updated_or_created = YES;
                params = @{
                           @"url": element[@"href"],
                           @"title": element[@"description"],
                           @"description": element[@"extended"],
                           @"meta": element[@"meta"],
                           @"hash": element[@"hash"],
                           @"tags": element[@"tags"],
                           @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                           @"private": @([element[@"shared"] isEqualToString:@"no"]),
                           @"created_at": [self.dateFormatter dateFromString:element[@"time"]]
                           };
                
                [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
            }
            
            if ([element[@"tags"] length] == 0) {
                continue;
            }
            
            if (updated_or_created) {
                for (id tagName in [element[@"tags"] componentsSeparatedByString:@" "]) {
                    tagIdNumber = [tags objectForKey:tagName];
                    if (!tagIdNumber) {
                        [db executeUpdate:@"INSERT INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                        
                        results = [db executeQuery:@"SELECT last_insert_rowid();"];
                        [results next];
                        tagIdNumber = @([results intForColumnIndex:0]);
                        [tags setObject:tagIdNumber forKey:tagName];
                    }
                    
                    [db executeUpdate:@"INSERT OR IGNORE INTO tagging (tag_id, bookmark_id) SELECT ?, bookmark.id FROM bookmark WHERE bookmark.hash=?" withArgumentsInArray:@[tagIdNumber, element[@"hash"]]];
                }
            }
        }
        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];

        for (NSString *bookmarkHash in bookmarksToDelete) {
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[bookmarkHash]];
        }

        [db commit];

        [self resumeRefreshTimer];
        [self setLastUpdated:[NSDate date]];

        if (newBookmarkCount > 0) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (newBookmarkCount == 1) {
                notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"1 bookmark was added.", nil)];
            }
            else {
                notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%d bookmarks were added.", nil), newBookmarkCount];
            }
            notification.alertAction = @"Open Pushpin";
            notification.userInfo = @{@"success": @YES, @"updated": @YES};
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
        self.bookmarksLoading = NO;
    };

    void (^BookmarksFailureBlock)(NSError *) = ^(NSError *error) {
        [self resumeRefreshTimer];
        self.bookmarksLoading = NO;
    };

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard bookmarksWithSuccess:BookmarksSuccessBlock
                           failure:BookmarksFailureBlock];
}

#warning Deprecated
- (void)updateBookmarks {
    [self updateBookmarksWithDelegate:nil];
}

- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate {
    if (!self.connectionAvailable.boolValue) {
        #warning FIX
        return;
    }

    if (![self token]) {
        return;
    }
    
    [self pauseRefreshTimer];
    void (^SuccessBlock)(NSDate *) = ^(NSDate *updateTime) {
        if (self.lastUpdated == nil || [self.lastUpdated compare:updateTime] == NSOrderedAscending || [[NSDate date] timeIntervalSinceReferenceDate] - [self.lastUpdated timeIntervalSinceReferenceDate] > 300) {
            [self forceUpdateBookmarks:updateDelegate];
        }
        else {
            [self resumeRefreshTimer];
        }
    };

    void (^FailureBlock)(NSError *) = ^(NSError *error) {
        [self resumeRefreshTimer];
    };

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard lastUpdateWithSuccess:SuccessBlock failure:FailureBlock];
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

#pragma mark - Timer

- (void)resumeRefreshTimer {
    timerPaused = NO;
}

- (void)pauseRefreshTimer {
    timerPaused = YES;
}

- (void)executeTimer {
    if (!timerPaused) {
        if (secondsLeft == 0) {
            secondsLeft = 10;
            [self updateBookmarks];
        }
        else {
            secondsLeft--;
        }
    }
}

@end

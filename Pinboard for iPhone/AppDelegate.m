//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "BookmarkViewController.h"
#import "HomeViewController.h"
#import "NoteViewController.h"
#import "LoginViewController.h"
#import "TabBarViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Reachability.h"
#import "TestFlight.h"
#import "PocketAPI.h"
#import "ZAActivityBar.h"
#import "HTMLParser.h"

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
@synthesize bookmarkViewControllerActive;

+ (NSString *)databasePath {
#if TARGET_IPHONE_SIMULATOR
    return @"/tmp/pinboard.db";
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:@"/pinboard.db"];
#endif
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    [self.tabBarViewController showAddBookmarkViewControllerWithBookmark:bookmark update:isUpdate callback:callback];
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
                            url = [NSURL URLWithString:[queryParameters[@"url"] stringByReplacingCharactersInRange:[queryParameters[@"url"] rangeOfString:url.scheme] withString:@"googlechrome"]];
                        }
                        else if ([url.scheme isEqualToString:@"https"]) {
                            url = [NSURL URLWithString:[queryParameters[@"url"] stringByReplacingCharactersInRange:[queryParameters[@"url"] rangeOfString:url.scheme] withString:@"googlechromes"]];
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
    if (!didLaunchWithURL) {
        [self.tabBarViewController promptUserToAddBookmark];
        didLaunchWithURL = NO;
    }
}

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query {
    // Parse the individual parameters
    // parameters = @"hello=world&foo=bar";
    NSMutableDictionary *dictParameters = [[NSMutableDictionary alloc] initWithDictionary:@{@"url": @"", @"title": @"", @"description": @"", @"tags": @"", @"private": [self privateByDefault], @"unread": @(YES) }];
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    [TestFlight takeOff:@"a4d1862d-30d8-4984-9e33-dba8872d2538"];
#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"045e859e70632363c4809784b13c5e98"];
    [[PocketAPI sharedAPI] setConsumerKey:@"11122-03068da9a8951bec2dcc93f3"];
    
    secondsLeft = 10;
    if ([self token]) {
        [mixpanel identify:self.username];
        [mixpanel.people identify:self.username];
        [mixpanel.people set:@"$username" to:self.username];
        self.tabBarViewController = [[TabBarViewController alloc] init];
        [self.window setRootViewController:self.tabBarViewController];
        [self resumeRefreshTimer];
    }
    else {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        [self.window setRootViewController:loginViewController];
        [self pauseRefreshTimer];
    }
    self.refreshTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];

    [self.window makeKeyAndVisible];
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableBlock = ^(Reachability*reach) {
        self.connectionAvailable = @(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionStatusDidChangeNotification" object:nil];
    };

    reach.unreachableBlock = ^(Reachability*reach) {
        self.connectionAvailable = @(NO);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionStatusDidChangeNotification" object:nil];
    };
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    self.bookmarksUpdated = @(NO);
    self.bookmarksUpdatedMessage = nil;
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[AppDelegate databasePath]];
    self.bookmarkViewControllerActive = YES;

    [reach startNotifier];
    [self migrateDatabase];
    
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
    NSString *endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/notes/list?auth_token=%@", [self token]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    [self setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self setNetworkActivityIndicatorVisible:NO];
                               dispatch_async(dispatch_get_current_queue(), ^{
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   [db beginTransaction];

                                   NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

                                   for (id element in elements) {
                                       NSDictionary *params = @{
                                           @"remote_id": element[@"id"],
                                           @"title": element[@"title"],
                                           @"length": element[@"length"],
                                           @"hash": element[@"hash"],
                                           @"text": element[@"text"],
                                           @"created_at": [self.dateFormatter dateFromString:element[@"created_on"]],
                                           @"updated_at": [self.dateFormatter dateFromString:element[@"updated_on"]]
                                       };
                                       
                                       [db executeUpdate:@"INSERT INTO note (title, length, hash, text, created_at, updated_at) VALUES (:title, :length, :hash, :text, :created_at, :updated_at);" withParameterDictionary:params];
                                   }
                                   
                                   [db commit];
                                   [db close];
                               });
                           }];
}

- (void)forceUpdateBookmarks:(id<BookmarkUpdateProgressDelegate>)updateDelegate {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (self.lastUpdated != nil) {
        self.bookmarksLoading = YES;

        if (self.bookmarkViewControllerActive) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ZAActivityBar showWithStatus:NSLocalizedString(@"Updating bookmarks", nil)];
            });
        }
    }

    NSString *endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/all?format=json&auth_token=%@", [self token]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

    [self setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self setNetworkActivityIndicatorVisible:NO];

                               if (error.code != NSURLErrorUserCancelledAuthentication && data != nil) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                       [db open];
                                       [db beginTransaction];

                                       db.logsErrors = NO;
                                       [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];

                                       NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                       FMResultSet *results;
                                       
                                       results = [db executeQuery:@"SELECT * FROM tag"];
                                       NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
                                       while ([results next]) {
                                           [tags setObject:@([results intForColumn:@"id"]) forKey:[results stringForColumn:@"name"]];
                                       }

                                       results = [db executeQuery:@"SELECT id, hash, meta FROM bookmark"];
                                       NSMutableDictionary *bookmarks = [[NSMutableDictionary alloc] init];
                                       NSMutableDictionary *bookmarkIds = [[NSMutableDictionary alloc] init];
                                       NSMutableArray *oldBookmarkHashes = [[NSMutableArray alloc] init];
                                       while ([results next]) {
                                           [oldBookmarkHashes addObject:[results stringForColumn:@"hash"]];
                                           [bookmarks setObject:[results stringForColumn:@"meta"] forKey:[results stringForColumn:@"hash"]];
                                           [bookmarkIds setObject:[results stringForColumn:@"id"] forKey:[results stringForColumn:@"hash"]];
                                       }
                                       
                                       NSMutableArray *newBookmarkHashes = [[NSMutableArray alloc] init];

                                       NSString *bookmarkMeta;
                                       NSNumber *tagIdNumber;
                                       NSNumber *currentBookmarkId;
                                       int tag_id;
                                       NSUInteger count = 0;
                                       NSUInteger total = elements.count;
                                       
                                       [mixpanel.people set:@"Bookmarks" to:@(total)];
                                       for (NSDictionary *element in elements) {
                                           [newBookmarkHashes addObject:element[@"hash"]];
                                           [oldBookmarkHashes removeObject:element[@"hash"]];
                                           
                                           count++;
                                           
                                           if (updateDelegate) {
                                               [updateDelegate bookmarkUpdateEvent:@(count) total:@(total)];
                                           }
                                           NSDictionary *params;
                                           
                                           bookmarkMeta = bookmarks[element[@"hash"]];
                                           if (bookmarkMeta) {
                                               currentBookmarkId = bookmarkIds[element[@"hash"]];
                                               if (![bookmarkMeta isEqualToString:element[@"meta"]]) {
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
                                                   [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_id=?" withArgumentsInArray:@[currentBookmarkId]];
                                               }
                                           }
                                           else {
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
                                               
                                               results = [db executeQuery:@"SELECT last_insert_rowid();"];
                                               [results next];
                                               currentBookmarkId = @([results intForColumnIndex:0]);
                                               [bookmarkIds setObject:currentBookmarkId forKey:element[@"hash"]];
                                               bookmarkMeta = element[@"meta"];
                                           }
                                           [bookmarks setObject:bookmarkMeta forKey:element[@"hash"]];
                                           
                                           if ([element[@"tags"] length] == 0) {
                                               continue;
                                           }
                                           
                                           for (id tagName in [element[@"tags"] componentsSeparatedByString:@" "]) {
                                               tagIdNumber = [tags objectForKey:tagName];
                                               if (!tagIdNumber) {
                                                   [db executeUpdate:@"INSERT INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];

                                                   results = [db executeQuery:@"SELECT last_insert_rowid();"];
                                                   [results next];
                                                   tagIdNumber = @([results intForColumnIndex:0]);
                                                   [tags setObject:tagIdNumber forKey:tagName];
                                               }
                                               
                                               tag_id = [tagIdNumber intValue];
                                               [db executeUpdateWithFormat:@"INSERT OR IGNORE INTO tagging (tag_id, bookmark_id) VALUES (%d, %d)", tag_id, currentBookmarkId.integerValue];
                                           }
                                       }
                                       
                                       [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];
                                       
                                       for (NSString *bookmarkHash in oldBookmarkHashes) {
                                           [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[bookmarkHash]];
                                       }

                                       [db commit];

                                       self.bookmarksUpdated = @(YES);
                                       [self resumeRefreshTimer];
                                       [self setLastUpdated:[NSDate date]];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           self.bookmarksLoading = NO;
                                           [ZAActivityBar dismiss];
                                       });
                                   });
                               }
                               else {
                                   [self resumeRefreshTimer];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       self.bookmarksLoading = NO;
                                       [ZAActivityBar dismiss];
                                   });
                               }
                           }];
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

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/update?auth_token=%@&format=json", [self token]]]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   NSDate *updateTime = [self.dateFormatter dateFromString:payload[@"update_time"]];

                                   if (self.lastUpdated == nil || [self.lastUpdated compare:updateTime] == NSOrderedAscending || [[NSDate date] timeIntervalSinceReferenceDate] - [self.lastUpdated timeIntervalSinceReferenceDate] > 300) {
                                       [self forceUpdateBookmarks:updateDelegate];
                                   }
                                   else {
                                       [self resumeRefreshTimer];
                                   }
                               }
                               else {
                                   [self resumeRefreshTimer];
                               }
                           }];
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
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
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
                           }];
}

- (void)updateFeedToken:(void (^)())callback {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/secret?auth_token=%@&format=json", [[AppDelegate sharedDelegate] token]]]];
    [self setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self setNetworkActivityIndicatorVisible:NO];
                               if (!error) {
                                   NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   [self setFeedToken:payload[@"result"]];
                                   callback();
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

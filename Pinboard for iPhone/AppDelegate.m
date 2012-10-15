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
#import "Pinboard.h"
#import "NoteViewController.h"
#import "ASManagedObject.h"
#import "LoginViewController.h"
#import "Bookmark.h"
#import "Tag.h"
#import "Note.h"
#import "TabBarViewController.h"
#import "FMDatabase.h"

@implementation AppDelegate

@synthesize window;
@synthesize token = _token;
@synthesize lastUpdated = _lastUpdated;

+ (NSString *)databasePath {
#ifdef TARGET_IPHONE_SIMULATOR
    return @"/tmp/pinboard.db";
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:@"/pinboard.db"];
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    if ([self token]) {
        TabBarViewController *tabBarViewController = [[TabBarViewController alloc] init];
        [self.window setRootViewController:tabBarViewController];
    }
    else {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        [self.window setRootViewController:loginViewController];
    }

    [self.window makeKeyAndVisible];

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    // http://stackoverflow.com/a/875422/39155
    [db executeUpdate:@"PRAGMA cache_size = 100;"];

    FMResultSet *s = [db executeQuery:@"PRAGMA user_version"];

    if ([s next]) {
        int version = [s intForColumnIndex:0];
        NSLog(@"%d", version);
        [db beginTransaction];
        switch (version) {
            case 0:
                [db executeUpdate:
                 @"CREATE TABLE bookmark("
                    "id INTEGER PRIMARY KEY ASC,"
                    "title VARCHAR(255),"
                    "description TEXT,"
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
                [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts3(id, title, description);"];
                [db executeUpdate:@"CREATE VIRTUAL TABLE note_fts USING fts3(id, title, text);"];
                [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts3(id, name);"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (id, title, description) VALUES(new.id, new.title, new.description); END;"];
                [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description WHERE id=new.id; END;"];
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
            default:
                break;
        }
        BOOL success = [db commit];
        NSLog(@"%d", success);
    }
    
    s = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type='table'"];
    while ([s next]) {
        NSLog(@"%@", [s stringForColumn:@"name"]);
    }
    
    [db close];
    
    [self updateBookmarks];
    return YES;
}

- (void)updateBookmarks {
    [self updateBookmarksWithDelegate:nil];
}

+ (AppDelegate *)sharedDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)setLastUpdated:(NSDate *)lastUpdated {
    _lastUpdated = lastUpdated;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastUpdated forKey:@"com.aurora.pinboard.LastUpdated"];
    [defaults synchronize];
}

- (NSDate *)lastUpdated {
    if (!_lastUpdated) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _lastUpdated = [defaults objectForKey:@"com.aurora.pinboard.LastUpdated"];
    }
    return _lastUpdated;
}

- (void)setToken:(NSString *)token {
    _token = token;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"com.aurora.pinboard.Token"];
    [defaults synchronize];
}

- (NSString *)token {
    if (!_token) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _token = [defaults objectForKey:@"com.aurora.pinboard.Token"];
    }
    return _token;
}

- (void)deleteBookmarks {
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:context]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSError *error = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *item in items) {
        [context deleteObject:item];
    }
    NSError *saveError = nil;
    [context save:&saveError];
}

- (void)updateNotes {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/notes/list?auth_token=%@", [self token]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               dispatch_async(dispatch_get_current_queue(), ^{
                                   NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   [db beginTransaction];


                                   for (id element in elements) {
                                       NSDictionary *params = @{
                                           @"remote_id": element[@"id"],
                                           @"title": element[@"title"],
                                           @"length": element[@"length"],
                                           @"hash": element[@"hash"],
                                           @"text": element[@"text"],
                                           @"created_at": [dateFormatter dateFromString:element[@"created_on"]],
                                           @"updated_at": [dateFormatter dateFromString:element[@"updated_on"]]
                                       };
                                       
                                       [db executeUpdate:@"INSERT INTO note (title, length, hash, text, created_at, updated_at) VALUES (:title, :length, :hash, :text, :created_at, :updated_at);" withParameterDictionary:params];
                                   }
                                   [db commit];
                                   [db close];
                               });
                           }];
}

- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSString *endpoint;
    if ([self lastUpdated]) {
        endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/all?fromdt=%@&format=json&auth_token=%@", [dateFormatter stringFromDate:[self lastUpdated]], [self token]];

    }
    else {
        endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/all?format=json&auth_token=%@", [self token]];
    }
    
    NSLog(@"%@", endpoint);

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error.code == NSURLErrorUserCancelledAuthentication) {

                               }
                               else {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                       FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                       [db open];
                                       
                                       FMResultSet *results;
                                       
                                       results = [db executeQuery:@"SELECT * FROM tag"];
                                       NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
                                       while ([results next]) {
                                           [tags setObject:@([results intForColumn:@"id"]) forKey:[results stringForColumn:@"name"]];
                                       }
                                       
                                       results = [db executeQuery:@"SELECT id, hash FROM bookmark"];
                                       NSMutableDictionary *bookmarks = [[NSMutableDictionary alloc] init];
                                       while ([results next]) {
                                           [bookmarks setObject:@([results intForColumn:@"id"]) forKey:[results stringForColumn:@"hash"]];
                                       }

                                       [db beginTransaction];

                                       NSNumber *bookmarkIdNumber;
                                       NSNumber *tagIdNumber;
                                       int bookmark_id;
                                       int tag_id;
                                       NSUInteger count = 0;
                                       NSUInteger total = elements.count;

                                       for (NSDictionary *element in elements) {
                                           count++;
                                           
                                           if (updateDelegate) {
                                               [updateDelegate bookmarkUpdateEvent:@(count) total:@(total)];
                                           }
                                           NSDictionary *params = @{
                                               @"url": element[@"href"],
                                               @"title": element[@"description"],
                                               @"description": element[@"extended"],
                                               @"meta": element[@"meta"],
                                               @"hash": element[@"hash"],
                                               @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                                               @"private": @([element[@"shared"] isEqualToString:@"no"]),
                                               @"created_at": [dateFormatter dateFromString:element[@"time"]]
                                           };
                                           
                                           bookmarkIdNumber = [bookmarks objectForKey:element[@"hash"]];
                                           if (!bookmarkIdNumber) {
                                               [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :meta, :created_at);" withParameterDictionary:params];
                                               
                                               results = [db executeQuery:@"SELECT last_insert_rowid();"];
                                               [results next];
                                               bookmarkIdNumber = @([results intForColumnIndex:0]);
                                               [bookmarks setObject:bookmarkIdNumber forKey:element[@"hash"]];
                                           }
                                           
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
                                               
                                               bookmark_id = [bookmarkIdNumber intValue];
                                               tag_id = [tagIdNumber intValue];
                                               [db executeUpdateWithFormat:@"INSERT OR IGNORE INTO tagging (tag_id, bookmark_id) VALUES (%d, %d)", tag_id, bookmark_id];
                                           }
                                       }
                                       BOOL success = [db commit];

                                       results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark"];
                                       [results next];
                                       NSLog(@"%d", [results intForColumnIndex:0]);
                                       [db close];

                                       [self setLastUpdated:[NSDate date]];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"BookmarksLoaded" object:nil];
                                   });
                               }
                           }];
}


@end

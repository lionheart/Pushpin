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

@implementation AppDelegate

@synthesize window;
@synthesize token = _token;
@synthesize lastUpdated = _lastUpdated;


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
    return YES;

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
    return nil;
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
                               NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                               NSManagedObjectContext *context = [ASManagedObject sharedContext];
                               Note *note;
                               
                               for (id element in elements) {
                                   note = (Note *)[NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:context];
                                   note.title = element[@"title"];
                                   note.length = element[@"length"];
                                   note.pinboard_hash = element[@"hash"];
                                   note.text = element[@"text"];
                                   note.id = element[@"id"];
                                   note.created_at = [dateFormatter dateFromString:element[@"created_on"]];
                                   note.updated_at = [dateFormatter dateFromString:element[@"updated_on"]];
                               }
                               [context save:&error];
                           }];
}

- (void)updateBookmarks {
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
                                   NSArray *elements = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   Bookmark *bookmark;
                                   Tag *tag;
                                   NSError *error = nil;
                                   NSFetchRequest *tagFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
                                   NSFetchRequest *bookmarkFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
                                   NSArray *fetchRequestResponse = nil;

                                   NSManagedObjectContext *context = [ASManagedObject sharedContext];

                                   for (id element in elements) {
                                       [bookmarkFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"pinboard_hash = %@", element[@"hash"]]];
                                       fetchRequestResponse = [context executeFetchRequest:bookmarkFetchRequest error:&error];

                                       if (fetchRequestResponse.count == 0) {
                                           bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
                                           bookmark.pinboard_hash = element[@"hash"];
                                       }
                                       else {
                                           bookmark = fetchRequestResponse[0];
                                       }

                                       bookmark.url = element[@"href"];
                                       bookmark.title = element[@"description"];
                                       bookmark.extended = element[@"extended"];
                                       bookmark.meta = element[@"meta"];
                                       bookmark.read = @([element[@"toread"] isEqualToString:@"no"]);
                                       bookmark.shared = @([element[@"shared"] isEqualToString:@"yes"]);
                                       bookmark.created_on = [dateFormatter dateFromString:element[@"time"]];

                                       for (id tagName in [element[@"tags"] componentsSeparatedByString:@" "]) {
                                           if ([tagName isEqualToString:@""]) {
                                               continue;
                                           }

                                           [tagFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", tagName]];
                                           fetchRequestResponse = [context executeFetchRequest:tagFetchRequest error:&error];

                                           if (fetchRequestResponse.count == 0) {
                                               tag = (Tag *)[NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
                                               tag.name = tagName;
                                           }
                                           else {
                                               tag = fetchRequestResponse[0];
                                           }
                                           [tag addBookmarksObject:bookmark];
                                       }
                                   }
                                   [context save:&error];
                                   
                                   if (!error) {
                                       [self setLastUpdated:[NSDate date]];
                                   }
                               }
                           }];
}


@end

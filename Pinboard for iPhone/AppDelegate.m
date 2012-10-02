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

                                   NSManagedObjectContext *context = [ASManagedObject sharedContext];

                                   for (id element in elements) {
                                       bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
                                       bookmark.url = [element objectForKey:@"href"];
                                       bookmark.title = [element objectForKey:@"description"];
                                       bookmark.extended = [element objectForKey:@"extended"];
                                       bookmark.meta = [element objectForKey:@"meta"];
                                       bookmark.pinboard_hash = [element objectForKey:@"hash"];
                                       bookmark.read = [NSNumber numberWithBool:([[element objectForKey:@"toread"] isEqualToString:@"no"])];
                                       bookmark.shared = [NSNumber numberWithBool:([[element objectForKey:@"shared"] isEqualToString:@"yes"])];
                                       bookmark.created_on = [dateFormatter dateFromString:[element objectForKey:@"time"]];

                                       for (id tagName in [[element objectForKey:@"tags"] componentsSeparatedByString:@" "]) {
                                           if ([tagName isEqualToString:@""]) {
                                               continue;
                                           }

                                           NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
                                           [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", tagName]];
                                           NSArray *fetchRequestResponse = [context executeFetchRequest:fetchRequest error:&error];

                                           if (fetchRequestResponse.count == 0) {
                                               tag = (Tag *)[NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
                                               tag.name = tagName;
                                           }
                                           else {
                                               tag = [fetchRequestResponse objectAtIndex:0];
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
    return;
}

- (void)processBookmarks {
    /*
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    [self.strings removeAllObjects];
    [self.heights removeAllObjects];
    
    for (int i=0; i<[self.bookmarks count]; i++) {
        Bookmark *bookmark = [self.bookmarks objectAtIndex:i];
        
        CGFloat height = 10.0f;
        height += ceilf([bookmark.title sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        height += ceilf([bookmark.extended sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        [self.heights addObject:[NSNumber numberWithFloat:height]];
        
        NSString *content;
        if (![bookmark.extended isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@\n%@", bookmark.title, bookmark.extended];
        }
        else {
            content = [NSString stringWithFormat:@"%@", bookmark.title];
        }
        
        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
        
        [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark.title]];
        [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark.extended]];
        [attributedString setTextColor:HEX(0x555555ff)];
        
        if (bookmark.read.boolValue) {
            [attributedString setTextColor:HEX(0x2255aaff) range:[content rangeOfString:bookmark.title]];
        }
        else {
            [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark.title]];
        }
        [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
        [self.strings addObject:attributedString];
    }
    
    [self.tableView reloadData];
     */
}


@end

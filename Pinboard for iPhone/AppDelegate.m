//
//  AppDelegate.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "PinboardClient.h"
#import "BookmarkViewController.h"
#import "HomeViewController.h"
#import "Pinboard.h"
#import "NoteViewController.h"
#import "ASManagedObject.h"

@implementation AppDelegate

@synthesize window;
@synthesize username = _username;
@synthesize password = _password;

- (void)setUsername:(NSString *)username {
    _username = username;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:username forKey:@"PinboardUsername"];
    [defaults synchronize];
}

- (void)setPassword:(NSString *)password {
    _password = password;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:password forKey:@"PinboardPassword"];
    [defaults synchronize];
}

- (NSString *)username {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"PinboardUsername"];
    if (_username != nil) {
        return _username;
    }

}

- (NSString *)password {
    if (_password != nil) {
        return _password;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"PinboardPassword"];
}

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response {
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque
                          animated:NO];

    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithEndpoint:@"posts/recent" predicate:nil parameters:nil];
    bookmarkViewController.title = @"All Bookmarks";
    
    HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    homeViewController.title = @"Browse";

    UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
    [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, bookmarkViewController, nil]];
    [postViewContainer popToViewController:bookmarkViewController animated:NO];

    postViewContainer.tabBarItem.title = @"Browse";
    postViewContainer.tabBarItem.image = [UIImage imageNamed:@"71-compass"];
    [postViewContainer.tabBarItem setBadgeValue:@"2"];
    
    UIViewController *vc1 = [[UIViewController alloc] init];
    vc1.tabBarItem.title = @"Settings";
    vc1.tabBarItem.image = [UIImage imageNamed:@"106-sliders"];
    
    UIViewController *vc2 = [[UIViewController alloc] init];
    vc2.tabBarItem.title = @"Add";
    vc2.tabBarItem.image = [UIImage imageNamed:@"10-medical"];
    
    UIViewController *vc3 = [[UIViewController alloc] init];
    vc3.tabBarItem.title = @"Tags";
    vc3.tabBarItem.image = [UIImage imageNamed:@"15-tags"];
    
    NoteViewController *noteViewController = [[NoteViewController alloc] initWithStyle:UITableViewStylePlain];
    noteViewController.tabBarItem.title = @"Notes";
    noteViewController.tabBarItem.image = [UIImage imageNamed:@"104-index-cards"];

    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:postViewContainer, noteViewController, vc2, vc3, vc1, nil]];

    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
    return YES;

}

+ (AppDelegate *)sharedDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end

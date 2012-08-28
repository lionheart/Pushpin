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

    self.username = @"dlo";
    self.password = @"papa c6h12o5a 0P";

    /*
    Pinboard *pinboard = [Pinboard pinboardWithEndpoint:@"posts/recent?count=10" delegate:self];
    [pinboard parse];
     */
    
    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithStyle:UITableViewStylePlain url:@"" parameters:nil];
    bookmarkViewController.title = @"All Bookmarks";
    
    HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    homeViewController.title = @"Browse";

    UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
    [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, bookmarkViewController, nil]];
    [postViewContainer popToViewController:bookmarkViewController animated:NO];

    postViewContainer.tabBarItem.title = @"Browse";
    postViewContainer.tabBarItem.image = [UIImage imageNamed:@"15-tags"];
    [postViewContainer.tabBarItem setBadgeValue:@"2"];
    
    UIViewController *vc1 = [[UIViewController alloc] init];
    vc1.tabBarItem.title = @"Settings";
    vc1.tabBarItem.image = [UIImage imageNamed:@"106-sliders"];
    
    UIViewController *vc2 = [[UIViewController alloc] init];
    vc2.tabBarItem.title = @"Add";
    vc2.tabBarItem.image = [UIImage imageNamed:@"10-medical"];
    
    UIViewController *vc3 = [[UIViewController alloc] init];
    vc3.tabBarItem.title = @"Community";
    vc3.tabBarItem.image = [UIImage imageNamed:@"112-group"];
    
    UIViewController *vc4 = [[UIViewController alloc] init];
    vc4.tabBarItem.title = @"Notes";
    vc4.tabBarItem.image = [UIImage imageNamed:@"104-index-cards"];

    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:postViewContainer, vc4, vc2, vc3, vc1, nil]];

    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
    return YES;

}

@end

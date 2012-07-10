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
    
    id navigationBarAppearance = [UINavigationBar appearance];
    
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque
                          animated:NO];

    self.username = @"dlo";
    self.password = @"papa c6h12o5a 0P";
    
    Pinboard *pinboard = [Pinboard pinboardWithEndpoint:@"posts/recent?count=10" delegate:self];
    [pinboard parse];

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:10], @"results", @"json", @"format", nil];

    BookmarkViewController *postViewController = [[BookmarkViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                   url:@"v1/posts/all"
                                                                            parameters:parameters];
    HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    homeViewController.title = @"Pinboard";
    UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:postViewController];

    [self.window setRootViewController:postViewContainer];
    [self.window makeKeyAndVisible];
    return YES;

}

@end

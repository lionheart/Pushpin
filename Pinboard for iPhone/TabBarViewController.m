//
//  TabBarViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/30/12.
//
//

#import "TabBarViewController.h"
#import "BookmarkViewController.h"
#import "HomeViewController.h"
#import "NoteViewController.h"
#import "TagViewController.h"

@interface TabBarViewController ()

@end

@implementation TabBarViewController

- (id)init {
    self = [super init];
    if (self) {
        BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:nil];
        bookmarkViewController.title = @"All Bookmarks";
        
        HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        homeViewController.title = @"Browse";
        
        UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
        [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, bookmarkViewController, nil]];
        [postViewContainer popToViewController:bookmarkViewController animated:NO];
        
        postViewContainer.tabBarItem.title = @"Browse";
        postViewContainer.tabBarItem.image = [UIImage imageNamed:@"71-compass"];
        // [postViewContainer.tabBarItem setBadgeValue:@"2"];
        
        UIViewController *vc1 = [[UIViewController alloc] init];
        vc1.tabBarItem.title = @"Settings";
        vc1.tabBarItem.image = [UIImage imageNamed:@"106-sliders"];
        
        UIViewController *vc2 = [[UIViewController alloc] init];
        vc2.tabBarItem.title = @"Add";
        vc2.tabBarItem.image = [UIImage imageNamed:@"10-medical"];
        
        TagViewController *tagViewController = [[TagViewController alloc] init];
        UINavigationController *tagViewNavigationController = [[UINavigationController alloc] initWithRootViewController:tagViewController];
        tagViewController.title = @"Tags";
        tagViewController.tabBarItem.image = [UIImage imageNamed:@"15-tags"];
        
        NoteViewController *noteViewController = [[NoteViewController alloc] initWithStyle:UITableViewStylePlain];
        noteViewController.tabBarItem.title = @"Notes";
        noteViewController.tabBarItem.image = [UIImage imageNamed:@"104-index-cards"];

        [self setViewControllers:[NSArray arrayWithObjects:postViewContainer, noteViewController, vc2, tagViewNavigationController, vc1, nil]];
    }
    return self;
}

@end

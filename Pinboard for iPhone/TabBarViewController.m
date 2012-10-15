//
//  TabBarViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/30/12.
//
//

#import "TabBarViewController.h"
#import "HomeViewController.h"
#import "NoteViewController.h"
#import "TagViewController.h"
#import "BookmarkViewController.h"
#import "SettingsViewController.h"
#import "AddBookmarkViewController.h"

@interface TabBarViewController ()

@end

@implementation TabBarViewController

- (id)init {
    self = [super init];
    if (self) {
        BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark LIMIT :limit OFFSET :offset" parameters:nil];
        bookmarkViewController.title = @"All Bookmarks";
        
        HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        homeViewController.title = @"Browse";
        
        UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
        [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, bookmarkViewController, nil]];
        [postViewContainer popToViewController:bookmarkViewController animated:NO];
        
        postViewContainer.tabBarItem.title = @"Browse";
        postViewContainer.tabBarItem.image = [UIImage imageNamed:@"71-compass"];
        // [postViewContainer.tabBarItem setBadgeValue:@"2"];
        
        SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
        UINavigationController *settingsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        settingsViewController.title = @"Settings";
        settingsViewController.tabBarItem.image = [UIImage imageNamed:@"106-sliders"];
        
        AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
        UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];
        addBookmarkViewController.title = @"Add";
        addBookmarkViewController.tabBarItem.image = [UIImage imageNamed:@"10-medical"];
        
        TagViewController *tagViewController = [[TagViewController alloc] init];
        UINavigationController *tagViewNavigationController = [[UINavigationController alloc] initWithRootViewController:tagViewController];
        tagViewController.title = @"Tags";
        tagViewController.tabBarItem.image = [UIImage imageNamed:@"15-tags"];
        
        NoteViewController *noteViewController = [[NoteViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *noteViewNavigationController = [[UINavigationController alloc] initWithRootViewController:noteViewController];
        noteViewController.title = @"Notes";
        noteViewController.tabBarItem.image = [UIImage imageNamed:@"104-index-cards"];

        [self setViewControllers:[NSArray arrayWithObjects:postViewContainer, noteViewNavigationController, addBookmarkViewNavigationController, tagViewNavigationController, settingsViewNavigationController, nil]];
        
        self.delegate = self;
    }
    return self;
}

- (void)closeModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        id visibleViewController = [(UINavigationController *)viewController visibleViewController];
        if ([visibleViewController isKindOfClass:[AddBookmarkViewController class]]) {
            AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
            UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

            addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
            addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
            addBookmarkViewController.title = @"Add Bookmark";
            addBookmarkViewController.modalDelegate = self;
            [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
            return false;
        }
    }
    return true;
}

@end

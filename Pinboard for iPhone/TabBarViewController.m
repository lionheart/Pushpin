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
#import "HTMLParser.h"

@interface TabBarViewController ()

@end

@implementation TabBarViewController

@synthesize webView = _webView;
@synthesize bookmarkTitle;
@synthesize bookmarkURL;
@synthesize allBookmarkViewController;

- (id)init {
    self = [super init];
    if (self) {
        secondsLeft = 0;
        timerPaused = NO;

        self.allBookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:nil];
        self.allBookmarkViewController.title = NSLocalizedString(@"All Bookmarks", nil);
        
        HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        homeViewController.title = NSLocalizedString(@"Browse Tab Bar Title", nil);
        
        UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
        [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, self.allBookmarkViewController, nil]];
        [postViewContainer popToViewController:self.allBookmarkViewController animated:NO];
        
        postViewContainer.tabBarItem.title = NSLocalizedString(@"Browse Tab Bar Title", nil);
        postViewContainer.tabBarItem.image = [UIImage imageNamed:@"71-compass"];
        // [postViewContainer.tabBarItem setBadgeValue:@"2"];
        
        SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
        UINavigationController *settingsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        settingsViewController.title = NSLocalizedString(@"Settings Tab Bar Title", nil);
        settingsViewController.tabBarItem.image = [UIImage imageNamed:@"106-sliders"];
        
        AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
        UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];
        addBookmarkViewController.title = NSLocalizedString(@"Add Tab Bar Title", nil);
        addBookmarkViewController.tabBarItem.image = [UIImage imageNamed:@"10-medical"];
        
        TagViewController *tagViewController = [[TagViewController alloc] init];
        UINavigationController *tagViewNavigationController = [[UINavigationController alloc] initWithRootViewController:tagViewController];
        tagViewController.title = NSLocalizedString(@"Tags Tab Bar Title", nil);
        tagViewController.tabBarItem.image = [UIImage imageNamed:@"15-tags"];

        NoteViewController *noteViewController = [[NoteViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *noteViewNavigationController = [[UINavigationController alloc] initWithRootViewController:noteViewController];
        noteViewController.title = NSLocalizedString(@"Notes Tab Bar Title", nil);
        noteViewController.tabBarItem.image = [UIImage imageNamed:@"104-index-cards"];

        [self setViewControllers:[NSArray arrayWithObjects:postViewContainer, noteViewNavigationController, addBookmarkViewNavigationController, tagViewNavigationController, settingsViewNavigationController, nil]];

        self.delegate = self;
    }
    return self;
}

- (void)closeModal:(UIViewController *)sender {
    sender = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)promptUserToAddBookmark {
    self.bookmarkURL = [UIPasteboard generalPasteboard].string;
    if (!self.bookmarkURL) {
        return;
    }

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.bookmarkURL]];
    [results next];
    if ([results intForColumnIndex:0] == 0) {
        NSURL *candidateURL = [NSURL URLWithString:self.bookmarkURL];
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            [[AppDelegate sharedDelegate] retrievePageTitle:candidateURL
                                                   callback:^(NSString *title, NSString *description) {
                                                       self.bookmarkTitle = title;

                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"URL in Clipboard Title", nil) message:NSLocalizedString(@"URL in Clipboard Message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Lighthearted No", nil) otherButtonTitles:NSLocalizedString(@"Lighthearted Yes", nil), nil];
                                                       [alert show];
                                                       [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                                   }];
            
        }
    }
    [db close];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _sessionChecked = false;
    if (buttonIndex == 1) {
        [self showAddBookmarkViewControllerWithBookmark:@{@"url": self.bookmarkURL, @"title": self.bookmarkTitle} update:@(NO) callback:nil];
        [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"Content length: %qd", [httpResponse expectedContentLength]);
        _sessionChecked = true;
        
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:self.bookmarkURL]];
        [self.webView loadRequest:req];
    }
    else {
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    }
    [connection cancel];
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update Navigation Bar", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark Page Title", nil);
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    else {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark Page Title", nil);
    }
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];

    addBookmarkViewController.modalDelegate = self;
    
    if (bookmark[@"title"]) {
        addBookmarkViewController.titleTextField.text = bookmark[@"title"];
    }
    
    if (bookmark[@"url"]) {
        addBookmarkViewController.urlTextField.text = bookmark[@"url"];
        addBookmarkViewController.urlTextField.enabled = NO;
    }

    if (bookmark[@"tags"]) {
        addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    }
    
    if (bookmark[@"description"]) {
        addBookmarkViewController.descriptionTextField.text = bookmark[@"description"];
    }
    
    if (callback) {
        addBookmarkViewController.callback = callback;
    }

    addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    addBookmarkViewController.markAsRead = @(!([bookmark[@"unread"] boolValue]));

    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewController {
    [self showAddBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^{}];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        id visibleViewController = [(UINavigationController *)viewController visibleViewController];
        if ([visibleViewController isKindOfClass:[AddBookmarkViewController class]]) {
            [self showAddBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:nil];
            return false;
        }
    }
    return true;
}

@end

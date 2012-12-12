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

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(promptUserToAddBookmark)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(pauseRefreshTimer)
                                   name:@"BookmarksLoading"
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(resumeRefreshTimer)
                                   name:@"BookmarksLoaded"
                                 object:nil];

        self.bookmarkRefreshTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.bookmarkRefreshTimer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

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
            [[AppDelegate sharedDelegate] updateBookmarks];
        }
        else {
            secondsLeft--;
        }
    }
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
            // Grab the page title
            NSURLRequest *request = [NSURLRequest requestWithURL:candidateURL];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

                                       if (!error) {
                                           HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];

                                           if (!error) {
                                               HTMLNode *root = [parser head];
                                               HTMLNode *titleTag = [root findChildTag:@"title"];
                                               if (titleTag != nil) {
                                                   self.bookmarkTitle = titleTag.contents;
                                               }

                                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"URL in Clipboard Title", nil) message:NSLocalizedString(@"URL in Clipboard Message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Lighthearted No", nil) otherButtonTitles:NSLocalizedString(@"Lighthearted Yes", nil), nil];
                                               [alert show];
                                               [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                           }
                                       }
                                   }];
            
        }
    }
    [db close];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _sessionChecked = false;
    if (buttonIndex == 1) {
        [self showAddBookmarkViewControllerWithBookmark:@{@"url": self.bookmarkURL, @"title": self.bookmarkTitle} andDelegate:self.allBookmarkViewController];
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    [connection cancel];
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate {
    [self showAddBookmarkViewControllerWithBookmark:bookmark andDelegate:delegate update:@(NO)];
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate update:(NSNumber *)isUpdate {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update Navigation Bar", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark Page Title", nil);
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

    if (isUpdate != nil && isUpdate) {
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    
    if (bookmark[@"tags"]) {
        addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    }
    
    if (bookmark[@"description"]) {
        addBookmarkViewController.descriptionTextField.text = bookmark[@"description"];
    }

    addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    addBookmarkViewController.markAsRead = @(!([bookmark[@"unread"] boolValue]));
    
    if (delegate != nil) {
        addBookmarkViewController.bookmarkUpdateDelegate = delegate;
    }
    else {
        addBookmarkViewController.bookmarkUpdateDelegate = self.allBookmarkViewController;
    }

    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewController {
    [self showAddBookmarkViewControllerWithBookmark:@{} andDelegate:nil];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        id visibleViewController = [(UINavigationController *)viewController visibleViewController];
        if ([visibleViewController isKindOfClass:[AddBookmarkViewController class]]) {
            [self showAddBookmarkViewControllerWithBookmark:@{} andDelegate:nil];
            return false;
        }
    }
    return true;
}

@end

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

@synthesize webView = _webView;
@synthesize bookmarkTitle;
@synthesize bookmarkURL;

- (id)init {
    self = [super init];
    if (self) {
        BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:nil];
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
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(promptUserToAddBookmark)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];

        [notificationCenter addObserver:bookmarkViewController
                               selector:@selector(processBookmarks)
                                   name:@"BookmarksLoaded"
                                 object:nil];
        
        self.bookmarkRefreshTimer = [NSTimer timerWithTimeInterval:10 target:[AppDelegate sharedDelegate] selector:@selector(updateBookmarks) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.bookmarkRefreshTimer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)closeModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)promptUserToAddBookmark {
    self.bookmarkURL = [UIPasteboard generalPasteboard].string;
    if (!self.bookmarkURL) {
        return;
    }

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.bookmarkURL]];
    [results next];
    if ([results intForColumnIndex:0] == 0) {
        NSURL *candidateURL = [NSURL URLWithString:self.bookmarkURL];
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Bookmark?" message:@"We've detected a URL in your clipboard. Would you like to bookmark it?" delegate:self cancelButtonTitle:@"Nope" otherButtonTitles:@"Sure", nil];
            [alert show];
        }
    }
    [db close];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _sessionChecked = false;
    if (buttonIndex == 1) {
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
        self.webView.frame = CGRectMake(0, 0, 1, 1);
        self.webView.hidden = YES;
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.bookmarkURL]]];
        [self.view addSubview:self.webView];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"%qd", [httpResponse expectedContentLength]);
        _sessionChecked = true;
        
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:self.bookmarkURL]];
        [self.webView loadRequest:req];
    }
    else {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    [connection cancel];
}

- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = @"Add Bookmark";
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = title;
    addBookmarkViewController.urlTextField.text = url;
    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewController {
    [self showAddBookmarkViewControllerWithURL:nil andTitle:nil];
    _sessionChecked = false;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        id visibleViewController = [(UINavigationController *)viewController visibleViewController];
        if ([visibleViewController isKindOfClass:[AddBookmarkViewController class]]) {
            [self showAddBookmarkViewController];
            return false;
        }
    }
    return true;
}

#pragma mark - Webview Delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *url = [UIPasteboard generalPasteboard].string;
//    [[UIPasteboard generalPasteboard] setString:@""];
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [webView stringByEvaluatingJavaScriptFromString:@"window.alert=null;"];
    [self showAddBookmarkViewControllerWithURL:url andTitle:title];
    [webView removeFromSuperview];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (_sessionChecked) {
        _sessionChecked = false;
        return YES;
    }
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    [conn start];
    return NO;
}

@end

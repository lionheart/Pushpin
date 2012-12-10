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

- (id)init {
    self = [super init];
    if (self) {
        secondsLeft = 0;
        timerPaused = NO;

        BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:nil];
        bookmarkViewController.title = NSLocalizedString(@"All Bookmarks", nil);
        
        HomeViewController *homeViewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        homeViewController.title = NSLocalizedString(@"Browse Tab Bar Title", nil);
        
        UINavigationController *postViewContainer = [[UINavigationController alloc] initWithRootViewController:homeViewController];
        [postViewContainer setViewControllers:[NSArray arrayWithObjects:homeViewController, bookmarkViewController, nil]];
        [postViewContainer popToViewController:bookmarkViewController animated:NO];
        
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
        
        if ([[AppDelegate sharedDelegate] token]) {
            self.bookmarkRefreshTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.bookmarkRefreshTimer forMode:NSDefaultRunLoopMode];
        }
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

- (void)closeModal {
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
        [self showAddBookmarkViewControllerWithURL:self.bookmarkURL andTitle:self.bookmarkTitle];
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

- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark Page Title", nil);
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = title;
    addBookmarkViewController.urlTextField.text = url;
    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title andTags:(NSString *)someTags {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];
    
    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark Page Title", nil);
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = title;
    addBookmarkViewController.urlTextField.text = url;
    addBookmarkViewController.tagTextField.text = someTags;
    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title andTags:(NSString *)someTags andDescription:(NSString *)aDescription {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];
    
    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark Page Title", nil);
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = title;
    addBookmarkViewController.urlTextField.text = url;
    addBookmarkViewController.tagTextField.text = someTags;
    addBookmarkViewController.descriptionTextField.text = aDescription;
    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle andTags:(NSString *)someTags andDescription:(NSString *)aDescription andPrivate:(NSNumber *)isPrivate andRead:(NSNumber *)isRead {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark Page Title", nil);
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = aTitle;
    addBookmarkViewController.urlTextField.text = aURL;
    addBookmarkViewController.urlTextField.enabled = NO;
    addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    addBookmarkViewController.tagTextField.text = someTags;
    addBookmarkViewController.descriptionTextField.text = aDescription;
    addBookmarkViewController.setAsPrivate = isPrivate;
    addBookmarkViewController.markAsRead = isRead;

    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(close)];
    addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark Page Title", nil);
    addBookmarkViewController.modalDelegate = self;
    addBookmarkViewController.titleTextField.text = bookmark[@"title"];
    addBookmarkViewController.urlTextField.text = bookmark[@"url"];
    addBookmarkViewController.urlTextField.enabled = NO;
    addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    addBookmarkViewController.descriptionTextField.text = bookmark[@"description"];
    addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    addBookmarkViewController.markAsRead = @(!([bookmark[@"unread"] boolValue]));
    addBookmarkViewController.bookmarkUpdateDelegate = delegate;
    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewController {
    [self showAddBookmarkViewControllerWithURL:nil andTitle:nil];
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
    _sessionChecked = false;
    NSLog(@"Finished load");
    NSString *url = [UIPasteboard generalPasteboard].string;
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [webView stringByEvaluatingJavaScriptFromString:@"window.alert=null;"];
    [self showAddBookmarkViewControllerWithURL:url andTitle:title];
    [webView removeFromSuperview];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"checking");
    if (_sessionChecked) {
        return YES;
    }
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    [conn start];
    return NO;
}

@end

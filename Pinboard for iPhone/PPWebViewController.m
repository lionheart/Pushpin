//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <MessageUI/MessageUI.h>

#import "PPWebViewController.h"
#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "PPToolbar.h"
#import "NSString+URLEncoding2.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - kToolbarHeight - self.navigationController.navigationBar.frame.size.height)];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.webView addGestureRecognizer:self.rightSwipeGestureRecognizer];
    
    PPToolbar *toolbar = [[PPToolbar alloc] init];
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 30, 30);
    self.backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.backBarButtonItem.enabled = NO;

    UIButton *forwardButton = [[UIButton alloc] init];
    [forwardButton setImage:[UIImage imageNamed:@"forward_icon"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    forwardButton.frame = CGRectMake(0, 0, 30, 30);
    self.forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    self.forwardBarButtonItem.enabled = NO;
    
    UIButton *readerButton = [[UIButton alloc] init];
    [readerButton setImage:[UIImage imageNamed:@"glyphicons_110_align_left"] forState:UIControlStateNormal];
    [readerButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
    readerButton.frame = CGRectMake(0, 0, 30, 30);
    self.readerBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:readerButton];
    
    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton setImage:[UIImage imageNamed:@"UIButtonBarAction"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolbar.items = @[self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, flexibleSpace, self.readerBarButtonItem, fixedSpace, self.actionBarButtonItem];
    toolbar.frame = CGRectMake(0, size.height - kToolbarHeight, size.width, kToolbarHeight);
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:toolbar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    }
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    self.readerBarButtonItem.enabled = NO;
    self.actionBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.title = pageTitle;

    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    self.readerBarButtonItem.enabled = YES;
    self.actionBarButtonItem.enabled = YES;

    NSString *theURLString;
    if ([self.webView canGoBack]) {
        theURLString = self.url.absoluteString;
    }
    else {
        theURLString = self.urlString;
    }

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[theURLString]];
    [results next];
    if ([results intForColumnIndex:0] > 0) {
        UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(showEditViewController)];
        self.navigationItem.rightBarButtonItem = editBarButtonItem;
    }
    else {
        UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(showAddViewController)];
        self.navigationItem.rightBarButtonItem = addBarButtonItem;
    }
    [db close];
    
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.backBarButtonItem.enabled = NO;
    self.forwardBarButtonItem.enabled = NO;
    self.readerBarButtonItem.enabled = NO;
    self.actionBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = nil;
    self.title = @"Loading...";
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
}

- (void)backButtonTouchUp:(id)sender {
    [self.webView goBack];
}

- (void)forwardButtonTouchUp:(id)sender {
    [self.webView goForward];
}

- (void)actionButtonTouchUp:(id)sender {
    NSString *urlString = [self url].absoluteString;
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Email URL", nil)];
    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
        case BROWSER_SAFARI:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
            break;
            
        case BROWSER_OPERA:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Opera", nil)];
            break;
            
        case BROWSER_ICAB_MOBILE:
            #warning XXX - switch to correct browser
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
            break;
            
        case BROWSER_DOLPHIN:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Dolphin", nil)];
            break;
            
        case BROWSER_CYBERSPACE:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Cyberspace", nil)];
            break;
            
        case BROWSER_CHROME:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
            break;
            
        default:
            break;
    }
    
    [actionSheet showFrom:self.navigationController.view];
}

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSURL *url = [self url];
    NSString *urlString = url.absoluteString;
    NSRange range = [urlString rangeOfString:url.scheme];

    if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
        [self copyURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Email URL", nil)]) {
        [self emailURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        return;
    }
    else {
        if ([title isEqualToString:NSLocalizedString(@"Open in Chrome", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
            }
            else {
                url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
            }
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Opera", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"ohttp"]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Dolphin", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"dolphin"]];
        }
        else if ([title isEqualToString:NSLocalizedString(@"Open in Cyberspace", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"cyber"]];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)toggleMobilizer {
    NSURL *url;
    if ([self isMobilized]) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                url = [NSURL URLWithString:[self.url.absoluteString substringFromIndex:57]];
                break;
                
            case MOBILIZER_INSTAPAPER:
                url = [NSURL URLWithString:[self.url.absoluteString substringFromIndex:30]];
                break;
                
            case MOBILIZER_READABILITY:
                url = [NSURL URLWithString:[self.url.absoluteString substringFromIndex:33]];
                break;
        }
    }
    else {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", [self url].absoluteString]];
                break;
                
            case MOBILIZER_INSTAPAPER:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.instapaper.com/m?u=%@", [self url].absoluteString]];
                break;
                
            case MOBILIZER_READABILITY:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@", [self url].absoluteString]];
                break;
        }
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)emailURL {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setMessageBody:[self urlString] isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self url].absoluteString];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSURL *)url {
    return [self.webView.request URL];
}

- (void)showAddViewController {
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSDictionary *post = @{
        @"title": pageTitle,
        @"url": self.url.absoluteString
    };

    UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(NO) delegate:self callback:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    #warning XXX - make generic
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[self.urlString]];
    [results next];
    NSDictionary *post = @{
        @"title": [results stringForColumn:@"title"],
        @"description": [results stringForColumn:@"description"],
        @"unread": @([results boolForColumn:@"unread"]),
        @"url": [results stringForColumn:@"url"],
        @"private": @([results boolForColumn:@"private"]),
        @"tags": [[results stringForColumn:@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
        @"created_at": [results dateForColumn:@"created_at"],
        @"starred": @([results boolForColumn:@"starred"])
    };
    [db close];

    UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) delegate:self callback:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isMobilized {
    BOOL googleMobilized = [[self url].absoluteString hasPrefix:@"http://www.google.com/gwt/x"];
    BOOL readabilityMobilized = [[self url].absoluteString hasPrefix:@"http://www.readability.com/m?url="];
    BOOL instapaperMobilized = [[self url].absoluteString hasPrefix:@"http://www.instapaper.com/m?u="];
    return googleMobilized || readabilityMobilized || instapaperMobilized;
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

@end

//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <MessageUI/MessageUI.h>
#import <Social/Social.h>

#import "PPWebViewController.h"
#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "PPToolbar.h"
#import "NSString+URLEncoding2.h"
#import "KeychainItemWrapper.h"
#import "OAuthConsumer.h"
#import "PocketAPI.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.numberOfRequestsInProgress = 0;
    self.alreadyLoaded = NO;
    
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
    [backButton setImage:[UIImage imageNamed:@"back-dash"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 30, 30);
    self.backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.backBarButtonItem.enabled = NO;

    UIButton *forwardButton = [[UIButton alloc] init];
    [forwardButton setImage:[UIImage imageNamed:@"forward-dash"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    forwardButton.frame = CGRectMake(0, 0, 30, 30);
    self.forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    self.forwardBarButtonItem.enabled = NO;
    
    self.readerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.readerButton addTarget:self.webView action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
    [self.readerButton setImage:[UIImage imageNamed:@"stop-dash"] forState:UIControlStateNormal];
    self.readerButton.frame = CGRectMake(0, 0, 30, 30);
    self.readerBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.readerButton];

    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton setImage:[UIImage imageNamed:@"action-dash"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];

    UIButton *socialButton = [[UIButton alloc] init];
    [socialButton setImage:[UIImage imageNamed:@"share2-dash"] forState:UIControlStateNormal];
    [socialButton addTarget:self action:@selector(socialActionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    socialButton.frame = CGRectMake(0, 0, 30, 30);
    self.socialBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:socialButton];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolbar.items = @[self.backBarButtonItem, self.forwardBarButtonItem, flexibleSpace, self.readerBarButtonItem, flexibleSpace, self.socialBarButtonItem, self.actionBarButtonItem];
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

    if (!self.alreadyLoaded) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)socialActionButtonTouchUp:(id)sender {
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Twitter", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Facebook", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share on Messages", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Email URL", nil)];
    [actionSheet showFrom:self.navigationController.view];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.numberOfRequestsInProgress--;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    [self enableOrDisableButtons];
    
    if (self.numberOfRequestsInProgress == 0) {
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.numberOfRequestsInProgress--;
    [self enableOrDisableButtons];
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
}

- (void)enableOrDisableButtons {
    if (self.numberOfRequestsInProgress > 0) {
        self.backBarButtonItem.enabled = NO;
        self.forwardBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem = nil;
        [self.readerButton addTarget:self.webView action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
        [self.readerButton setImage:[UIImage imageNamed:@"stop-dash"] forState:UIControlStateNormal];
    }
    else {
        self.backBarButtonItem.enabled = self.webView.canGoBack;
        self.forwardBarButtonItem.enabled = self.webView.canGoForward;
        self.alreadyLoaded = YES;
        
        NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.title = pageTitle;

        NSString *theURLString;
        if ([self.webView canGoBack]) {
            theURLString = self.url.absoluteString;
        }
        else {
            theURLString = self.urlString;
        }

        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[[self urlStringForDemobilizedURL:[NSURL URLWithString:theURLString]]]];
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

        if (self.isMobilized) {
            [self.readerButton setImage:[UIImage imageNamed:@"globe-dash"] forState:UIControlStateNormal];
        }
        else {
            [self.readerButton setImage:[UIImage imageNamed:@"paper-dash"] forState:UIControlStateNormal];
        }

        [self.readerButton addTarget:self action:@selector(toggleMobilizer) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.numberOfRequestsInProgress++;
    [self enableOrDisableButtons];
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
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
        case BROWSER_SAFARI:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
            break;
            
        case BROWSER_OPERA:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Opera", nil)];
            break;
            
        case BROWSER_ICAB_MOBILE:
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in iCab Mobile", nil)];
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
    
    NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
    if (readlater == READLATER_INSTAPAPER) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
    }
    else if (readlater == READLATER_READABILITY) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
    }
    else if (readlater == READLATER_POCKET) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
    }
    
    [actionSheet showFrom:self.navigationController.view];
}

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    NSURL *url = [NSURL URLWithString:urlString];
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
    else if ([title isEqualToString:NSLocalizedString(@"Share on Twitter", nil)]) {
        SLComposeViewController *socialComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [socialComposeViewController setInitialText:self.title];
        [socialComposeViewController addURL:url];
        [self presentViewController:socialComposeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Share on Facebook", nil)]) {
        SLComposeViewController *socialComposeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [socialComposeViewController setInitialText:self.title];
        [socialComposeViewController addURL:url];
        [self presentViewController:socialComposeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Share on Messages", nil)]) {
        MFMessageComposeViewController *composeViewController = [[MFMessageComposeViewController alloc] init];
        composeViewController.messageComposeDelegate = self;
        [composeViewController setBody:[NSString stringWithFormat:@"%@ %@", self.title, urlString]];
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
        [self sendToReadLater];
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
        else if ([title isEqualToString:NSLocalizedString(@"Open in iCab Mobile", nil)]) {
            url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:range withString:@"icabmobile"]];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)sendToReadLater {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSString *urlString = [self urlStringForDemobilizedURL:self.url];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/bookmarks/add"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        NSMutableArray *parameters = [[NSMutableArray alloc] init];
        [parameters addObject:[OARequestParameter requestParameter:@"url" value:urlString]];
        [parameters addObject:[OARequestParameter requestParameter:@"description" value:@"Sent from Pushpin"]];
        [request setParameters:parameters];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   if (httpResponse.statusCode == 200) {
                                       notification.alertBody = NSLocalizedString(@"Sent to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                   }
                                   else if (httpResponse.statusCode == 1221) {
                                       notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[[OARequestParameter requestParameter:@"url" value:urlString]]];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   if (httpResponse.statusCode == 202) {
                                       notification.alertBody = @"Sent to Readability.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                   }
                                   else if (httpResponse.statusCode == 409) {
                                       notification.alertBody = @"Link already sent to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = @"Error sending to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_POCKET) {
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:urlString]
                             withTitle:self.title
                               handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                   if (!error) {
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertBody = @"Sent to Pocket.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                       
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                   }
                               }];
    }
}

- (NSString *)urlStringForDemobilizedURL:(NSURL *)url {
    if ([self isURLStringMobilized:url.absoluteString]) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                return [url.absoluteString substringFromIndex:57];
                break;
                
            case MOBILIZER_INSTAPAPER:
                return [url.absoluteString substringFromIndex:30];
                break;
                
            case MOBILIZER_READABILITY:
                return [url.absoluteString substringFromIndex:33];
                break;
        }
    }
    return url.absoluteString;
}

- (void)toggleMobilizer {
    NSURL *url;
    if (self.isMobilized) {
        [AppDelegate sharedDelegate].openLinksWithMobilizer = NO;
        url = [NSURL URLWithString:[self urlStringForDemobilizedURL:self.url]];
    }
    else {
        [AppDelegate sharedDelegate].openLinksWithMobilizer = YES;
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", self.url.absoluteString]];
                break;
                
            case MOBILIZER_INSTAPAPER:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.instapaper.com/m?u=%@", self.url.absoluteString]];
                break;
                
            case MOBILIZER_READABILITY:
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.url.absoluteString]];
                break;
        }
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)emailURL {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setMessageBody:[self urlStringForDemobilizedURL:self.url] isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self urlStringForDemobilizedURL:self.url]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSURL *)url {
    NSURL *url = [self.webView.request URL];
    if (!url) {
        return [NSURL URLWithString:self.urlString];
    }
    return url;
}

- (void)showAddViewController {
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSDictionary *post = @{
        @"title": pageTitle,
        @"url": [self urlStringForDemobilizedURL:self.url]
    };

    UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(NO) delegate:self callback:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showEditViewController {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        #warning XXX - make generic
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[[self urlStringForDemobilizedURL:self.url]]];
        [results next];
        NSDictionary *post = @{
            @"title": [results stringForColumn:@"title"],
            @"description": [results stringForColumn:@"description"],
            @"unread": @([results boolForColumn:@"unread"]),
            @"url": [results stringForColumn:@"url"],
            @"private": @([results boolForColumn:@"private"]),
            @"tags": [results stringForColumn:@"tags"],
            @"created_at": [results dateForColumn:@"created_at"],
            @"starred": @([results boolForColumn:@"starred"])
        };
        [db close];

        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationController *vc = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post update:@(YES) delegate:self callback:nil];
            [self presentViewController:vc animated:YES completion:nil];
        });
    });
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isMobilized {
    BOOL googleMobilized = [self.url.absoluteString hasPrefix:@"http://www.google.com/gwt/x"];
    BOOL readabilityMobilized = [self.url.absoluteString hasPrefix:@"http://www.readability.com/m?url="];
    BOOL instapaperMobilized = [self.url.absoluteString hasPrefix:@"http://www.instapaper.com/m?u="];
    return googleMobilized || readabilityMobilized || instapaperMobilized;
}

- (BOOL)isURLStringMobilized:(NSString *)url {
    BOOL googleMobilized = [url hasPrefix:@"http://www.google.com/gwt/x"];
    BOOL readabilityMobilized = [url hasPrefix:@"http://www.readability.com/m?url="];
    BOOL instapaperMobilized = [url hasPrefix:@"http://www.instapaper.com/m?u="];
    return googleMobilized || readabilityMobilized || instapaperMobilized;
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    NSString *urlString;
    if (![webViewController isURLStringMobilized:url]) {
        switch ([[AppDelegate sharedDelegate] mobilizer].integerValue) {
            case MOBILIZER_GOOGLE:
                urlString = [NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", url];
                break;
                
            case MOBILIZER_INSTAPAPER:
                urlString = [NSString stringWithFormat:@"http://www.instapaper.com/m?u=%@", url];
                break;
                
            case MOBILIZER_READABILITY:
                urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", url];
                break;
                
            default:
                break;
        }
    }
    else {
        urlString = url;
    }

    webViewController.urlString = urlString;
    return webViewController;
}

@end

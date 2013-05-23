//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <MessageUI/MessageUI.h>

#import "PPWebViewController.h"
#import "AppDelegate.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - kToolbarHeight - self.navigationController.navigationBar.frame.size.height)];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
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
    
    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton setImage:[UIImage imageNamed:@"UIButtonBarAction"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    toolbar.items = @[self.backBarButtonItem, self.forwardBarButtonItem, flexibleSpace, actionBarButtonItem];
    toolbar.frame = CGRectMake(0, size.height - kToolbarHeight - self.navigationController.navigationBar.frame.size.height, size.width, kToolbarHeight);

    [self.view addSubview:toolbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.title = pageTitle;

    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.backBarButtonItem.enabled = NO;
    self.forwardBarButtonItem.enabled = NO;
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
    NSURL* url = [self.webView.request URL];
    NSString *urlString = [url absoluteString];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:urlString cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Email URL", nil)];
#warning TODO
//    [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Pinboard", nil)];
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
    NSURL *url = [self.webView.request URL];
    NSString *urlString = [url absoluteString];
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

- (void)emailURL {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setMessageBody:[self.webView.request URL].absoluteString isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:[self.webView.request URL].absoluteString];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

@end

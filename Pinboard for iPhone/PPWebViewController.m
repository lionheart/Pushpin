//
//  PPWebViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPWebViewController.h"

static NSInteger kToolbarHeight = 44;

@interface PPWebViewController ()

@end

@implementation PPWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.frame.size;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - kToolbarHeight)];
    [self.view addSubview:self.webView];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [backButton addTarget:self.webView action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton setImage:[UIImage imageNamed:@"UIButtonBarAction"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(buttonActionTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    toolbar.items = @[backBarButtonItem, flexibleSpace, actionBarButtonItem];
    toolbar.frame = CGRectMake(0, size.height - kToolbarHeight - self.navigationController.navigationBar.frame.size.height, size.width, kToolbarHeight);

    [self.view addSubview:toolbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];

    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton setImage:[UIImage imageNamed:@"AddNavigationDimmed"] forState:UIControlStateNormal];
    [addButton setImage:[UIImage imageNamed:@"AddNavigation"] forState:UIControlStateSelected];
    addButton.frame = CGRectMake(0, 0, 40, 24);
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
}

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url {
    PPWebViewController *webViewController = [[PPWebViewController alloc] init];
    webViewController.urlString = url;
    return webViewController;
}

@end

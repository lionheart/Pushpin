//
//  LoginViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "NSData+Additions.h"
#import <ASPinboard/ASPinboard.h>
#import "PrimaryNavigationViewController.h"
#import "PinboardDataSource.h"
#import "FeedListViewController.h"
#import "RPSTPasswordManagementAppService.h"
#import "UserVoice.h"
#import "UIApplication+AppDimensions.h"
#import "UIView+LHSAdditions.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

static NSString *LoginTableCellIdentifier = @"LoginTableViewCell";

@synthesize activityIndicator;
@synthesize textView;
@synthesize progressView;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize activityIndicatorFrameBottom;
@synthesize activityIndicatorFrameTop;
@synthesize onePasswordButton;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Pushpin";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleDone target:self action:@selector(showContactForm)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStyleDone target:self action:@selector(login)];

    self.tableView.backgroundColor = HEX(0xeeeeeeff);
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:LoginTableCellIdentifier];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.hidden = YES;
    
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor darkGrayColor];
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.textView.text = NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil);

    CGSize size = [UIApplication currentSize];
    CGFloat radius = 5;
    CGRect buttonRect = CGRectMake(0, 0, radius * 2, 30);
    CAGradientLayer *barButtonItemLayer = [CAGradientLayer layer];
    barButtonItemLayer.frame = buttonRect;
    barButtonItemLayer.cornerRadius = radius;
    barButtonItemLayer.masksToBounds = YES;
    barButtonItemLayer.borderWidth = 0.5;
    barButtonItemLayer.borderColor = HEX(0x4C586AFF).CGColor;
    barButtonItemLayer.colors = @[(id)HEX(0xFDFDFDFF).CGColor, (id)HEX(0xCED4E0FF).CGColor];
    barButtonItemLayer.startPoint = CGPointMake(0.5, 0);
    barButtonItemLayer.endPoint = CGPointMake(0.5, 1.0);
    
    UIGraphicsBeginImageContextWithOptions(buttonRect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [barButtonItemLayer renderInContext:context];
    UIImage *barButtonBackground = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:radius topCapHeight:15];
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(buttonRect.size, NO, 0);
    context = UIGraphicsGetCurrentContext();
    barButtonItemLayer.colors = @[(id)HEX(0xCED4E0FF).CGColor, (id)HEX(0xFDFDFDFF).CGColor];
    [barButtonItemLayer renderInContext:context];
    UIImage *barButtonBackgroundHighlighted = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:radius topCapHeight:15];
    UIGraphicsEndImageContext();
    
    self.onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.onePasswordButton setFrame:CGRectMake((size.width - 180) / 2, 150, 180, 44)];
    [self.onePasswordButton setTitle:@"Launch 1Password" forState:UIControlStateNormal];
    [self.onePasswordButton setImage:[UIImage imageNamed:@"1P-29"] forState:UIControlStateNormal];
    [self.onePasswordButton setImage:[UIImage imageNamed:@"1P-29"] forState:UIControlStateHighlighted];
    [self.onePasswordButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, radius)];
    [self.onePasswordButton setTitleEdgeInsets:UIEdgeInsetsMake(0, radius, 0, 0)];
    [self.onePasswordButton setBackgroundImage:barButtonBackground forState:UIControlStateNormal];
    [self.onePasswordButton setBackgroundImage:barButtonBackgroundHighlighted forState:UIControlStateHighlighted];
    [self.onePasswordButton addTarget:self action:@selector(sendToOnePassword) forControlEvents:UIControlEventTouchUpInside];

    self.onePasswordButton.titleLabel.font = [UIFont fontWithName:[AppDelegate heavyFontName] size:15];
    [self.onePasswordButton setTitleColor:HEX(0x4A5768FF) forState:UIControlStateNormal];
    [self.onePasswordButton setTitleShadowColor:HEX(0xFFFFFF00) forState:UIControlStateNormal];
    self.onePasswordButton.hidden = YES;
    [self.view addSubview:self.onePasswordButton];
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.usernameTextField.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:18];
    self.usernameTextField.textAlignment = NSTextAlignmentLeft;
    self.usernameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.usernameTextField.backgroundColor = [UIColor whiteColor];
    self.usernameTextField.delegate = self;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.usernameTextField.rightViewMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.placeholder = NSLocalizedString(@"Username", nil);
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordTextField.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:18];
    self.passwordTextField.textAlignment = NSTextAlignmentLeft;
    self.passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTextField.backgroundColor = [UIColor whiteColor];
    self.passwordTextField.delegate = self;
    self.passwordTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordTextField.placeholder = NSLocalizedString(@"Password", nil);

    self.keyboard_shown = NO;
    self.loginTimer = nil;
    
    [self resetLoginScreen];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressNotificationReceived:) name:kPinboardDataSourceProgressNotification object:nil];
}

- (void)progressNotificationReceived:(NSNotification *)notification {
    NSInteger current = [notification.userInfo[@"current"] integerValue];
    NSInteger total = [notification.userInfo[@"total"] integerValue];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (total == current) {
            [self.messageUpdateTimer invalidate];
            self.activityIndicator.frame = self.activityIndicatorFrameTop;
            self.progressView.hidden = YES;
            self.textView.text = @"Finalizing Metadata";
        }
        else {
            CGFloat f = current / (float)total;
            [self.progressView setProgress:f animated:YES];
        }
    });
}

- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:updated.floatValue / total.floatValue];
        
        if (updated.integerValue == total.integerValue) {
            UINavigationController *controller = [AppDelegate sharedDelegate].navigationController;
            controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:controller animated:YES completion:nil];
        }
    });
}

- (void)resetLoginScreen {
    self.textView.text = NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil);
    
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];
    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];

    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Log In", nil)];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];

    if ([RPSTPasswordManagementAppService passwordManagementAppIsAvailable]) {
        self.onePasswordButton.hidden = NO;
        self.textView.hidden = YES;
    }
}

- (void)updateLoadingMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *messages = @[
            @"Avoiding Acquisitions",
            @"Calibrating Snark Levels",
            @"Debugging Retain Cycles",
            @"Depixilating Monads",
            @"Force Quitting Development Tools",
            @"Generating Bookmark Indices",
            @"Parsing Unicode Date Formatters",
            @"Evaluating Sync Solutions",
            @"Binding ARC Evaluators",
            @"Garbage Collecting Stale Note Data",
            @"Applying Bookmark Upgrades",
            @"Initializing Null Pointers",
            @"Calibrating Tag Optimizations",
            @"Polishing Retina Displays",
            @"Refactoring Applicative Factors",
            @"Regenerating Provisioning Profiles",
            @"Releasing View Controllers",
            @"Reticulating Splines",
            @"Reversing Feed Originators",
        ];
        self.textView.text = [messages objectAtIndex:arc4random_uniform(messages.count)];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.progressView.frame = CGRectMake(([UIApplication currentSize].width - 280) / 2, 380, 280, 50);
        });
    });
}

- (void)login {
    if (![self.usernameTextField.text isEqualToString:@""] && ![self.passwordTextField.text isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            
            UIActivityIndicatorView *loginActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [loginActivityView startAnimating];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loginActivityView];
            
            self.usernameTextField.enabled = NO;
            self.usernameTextField.textColor = [UIColor grayColor];
            self.passwordTextField.enabled = NO;
            self.passwordTextField.textColor = [UIColor grayColor];
            self.onePasswordButton.hidden = YES;
            self.textView.hidden = NO;
            self.textView.text = NSLocalizedString(@"Verifying your credentials...", nil);
        
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard authenticateWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                       success:^(NSString *token) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               self.textView.text = NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil);
                                               self.messageUpdateTimer = [NSTimer timerWithTimeInterval:6 target:self selector:@selector(updateLoadingMessage) userInfo:nil repeats:YES];
                                               [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
                                               
                                               self.progressView.hidden = NO;
                                               
                                               [self.tableView beginUpdates];
                                               [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                               [self.tableView endUpdates];

                                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                   [delegate setToken:token];
                                                   PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
                                                   
                                                   [dataSource updateLocalDatabaseFromRemoteAPIWithSuccess:^{
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self.messageUpdateTimer invalidate];
                                                           delegate.navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                                                           [self presentViewController:delegate.navigationController
                                                                              animated:YES
                                                                            completion:nil];
                                                       });
                                                   }
                                                                                                   failure:nil
                                                                                                  progress:nil
                                                                                                   options:@{@"count": @(-1)}];
                                                   
                                                   [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                                       [delegate setFeedToken:feedToken];
                                                   }];
                                                   
                                                   Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                   [mixpanel identify:[delegate username]];
                                                   [mixpanel.people set:@"$created" to:[NSDate date]];
                                                   [mixpanel.people set:@"$username" to:[delegate username]];
                                                   [mixpanel.people set:@"Browser" to:@"Webview"];
                                               });
                                           });
                                       }
                                       failure:^(NSError *error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               switch (error.code) {
                                                   case PinboardErrorInvalidCredentials: {
                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error" message:NSLocalizedString(@"We couldn't log you in. Please make sure you've provided valid credentials.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                       [alert show];
                                                       [[Mixpanel sharedInstance] track:@"Failed to log in"];
                                                       [self resetLoginScreen];
                                                       break;
                                                   }
                                                       
                                                   case PinboardErrorTimeout: {
                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                       [alert show];
                                                       [[Mixpanel sharedInstance] track:@"Cancelled log in"];
                                                       [self resetLoginScreen];
                                                       break;
                                                   }
                                                       
                                                   default:
                                                       break;
                                               }
                                           });
                                       }];
        });
    }
}

- (void)sendToOnePassword {
    [[UIApplication sharedApplication] openURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
        [self login];
    }
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.progressView.hidden) {
        return 2;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [view addSubview:self.progressView];
    [view addSubview:self.textView];
    
    NSDictionary *views = @{@"progress": self.progressView,
                            @"text": self.textView };
    [view lhs_addConstraints:@"V:|[progress]-5-[text]-5-|" views:views];
    [view lhs_addConstraints:@"H:|[progress]|" views:views];
    [view lhs_addConstraints:@"H:|-5-[text]-5-|" views:views];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoginTableCellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *subviews = [cell.contentView subviews];
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }

    UITextField *textField;
    if (indexPath.row == 0) {
        textField = self.usernameTextField;
    }
    else {
        textField = self.passwordTextField;
    }
    
    NSDictionary *views = @{
                            @"text": textField };
    [cell.contentView addSubview:textField];
    [cell.contentView lhs_addConstraints:@"H:|-15-[text]-5-|" views:views];
    [cell.contentView lhs_addConstraints:@"V:|-5-[text]-5-|" views:views];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.row == 0) {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
}

- (void)showContactForm {
    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];

    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
}

@end

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
#import "PrimaryNavigationViewController.h"
#import "PinboardDataSource.h"
#import "FeedListViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"

#import <ASPinboard/ASPinboard.h>
#import <uservoice-iphone-sdk/UserVoice.h>
#import <RPSTPasswordManagementAppService/RPSTPasswordManagementAppService.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/NSData+Base64.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

static NSString *LoginTableCellIdentifier = @"LoginTableViewCell";

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

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

    NSDictionary *textViewAttributes = @{NSFontAttributeName: [PPTheme urlFont]};
    NSAttributedString *textViewAttributedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil) attributes:textViewAttributes];
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor darkGrayColor];
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.attributedText = textViewAttributedString;
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.usernameTextField.font = [UIFont fontWithName:[PPTheme fontName] size:18];
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
    self.passwordTextField.font = [UIFont fontWithName:[PPTheme fontName] size:18];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            PPNavigationController *controller = [AppDelegate sharedDelegate].navigationController;
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
                                               [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kLoginUsernameRow inSection:0], [NSIndexPath indexPathForRow:kLoginPasswordRow inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
        [self login];
    }
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
    if ([[UIApplication sharedApplication] canOpenURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]]) {
        return 2;
    }
    else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.progressView.hidden) {
        switch (section) {
            case 0:
                return 2;
                
            case 1:
                return 1;
        }
    }

    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        CGRect rect = [self.textView.attributedText boundingRectWithSize:CGSizeMake(300, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        return rect.size.height + 14;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *view = [[UIView alloc] init];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [view addSubview:self.progressView];
        [view addSubview:self.textView];

        NSDictionary *views = @{@"progress": self.progressView,
                                @"text": self.textView };
        

        CGFloat height = 3;
        if (self.progressView.hidden) {
            height = 0;
        }
        NSDictionary *metrics = @{@"height": @(height)};
        [view lhs_addConstraints:@"V:|[progress(height)]-5-[text]-5-|" metrics:metrics views:views];
        [view lhs_addConstraints:@"H:|[progress]|" views:views];
        [view lhs_addConstraints:@"H:|-5-[text]-5-|" views:views];
        return view;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoginTableCellIdentifier forIndexPath:indexPath];

    [cell.contentView lhs_removeSubviews];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case kLoginUsernameRow: {
                    NSDictionary *views = @{@"view": self.usernameTextField };
                    [cell.contentView addSubview:self.usernameTextField];
                    [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
                    break;
                }
                    
                case kLoginPasswordRow: {
                    NSDictionary *views = @{@"view": self.passwordTextField };
                    [cell.contentView addSubview:self.passwordTextField];
                    [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
                    break;
                }
            }
            break;
            
        case 1: {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"56_Key-alt"]];
            cell.accessoryView = imageView;
            cell.textLabel.text = @"Launch 1Password";
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case kLoginUsernameRow:
                    [self.usernameTextField becomeFirstResponder];
                    break;
                    
                case kLoginPasswordRow:
                    [self.passwordTextField becomeFirstResponder];
                    break;
            }

            break;
            
        case 1:
            [[UIApplication sharedApplication] openURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]];
            break;
    }
    
}

- (void)showContactForm {
    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];

    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
}

@end

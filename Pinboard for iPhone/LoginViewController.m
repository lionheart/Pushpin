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
#import "ASStyleSheet.h"

#import <ASPinboard/ASPinboard.h>
#import <uservoice-iphone-sdk/UserVoice.h>
#import <RPSTPasswordManagementAppService/RPSTPasswordManagementAppService.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/NSData+Base64.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface LoginViewController ()

@property (nonatomic) BOOL loginInProgress;

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
    self.loginInProgress = NO;

    self.tableView.backgroundColor = HEX(0xeeeeeeff);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:LoginTableCellIdentifier];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.hidden = YES;

    self.textViewAttributes = @{NSFontAttributeName: [PPTheme urlFont]};
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor darkGrayColor];
    self.textView.editable = NO;
    self.textView.hidden = YES;
    self.textView.userInteractionEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentCenter;
    
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.usernameTextField.font = [PPTheme titleFont];
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
    self.passwordTextField.font = [PPTheme titleFont];
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
            self.textView.attributedText = [[NSAttributedString alloc] initWithString:@"Finalizing Metadata" attributes:self.textViewAttributes];
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
    self.loginInProgress = NO;

    self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil) attributes:self.textViewAttributes];
    self.textView.hidden = YES;
    
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];

    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleDone target:self action:@selector(showContactForm)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStyleDone target:self action:@selector(login)];
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
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:[messages objectAtIndex:arc4random_uniform(messages.count)] attributes:self.textViewAttributes];
    });
}

- (void)login {
    if (!self.loginInProgress) {
        self.loginInProgress = YES;

        if ([self.usernameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter both a username and password to sign into Pinboard." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            self.loginInProgress = NO;
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            
            UIActivityIndicatorView *loginActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [loginActivityView startAnimating];
            
            self.navigationItem.leftBarButtonItem.enabled = NO;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loginActivityView];
            
            self.usernameTextField.enabled = NO;
            self.usernameTextField.textColor = [UIColor grayColor];
            self.passwordTextField.enabled = NO;
            self.passwordTextField.textColor = [UIColor grayColor];
            self.textView.hidden = NO;
            self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Verifying your credentials...", nil) attributes:self.textViewAttributes];
            
            if ([self is1PasswordAvailable]) {
                [self.tableView beginUpdates];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            }
            
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard authenticateWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                       success:^(NSString *token) {
                                           self.loginInProgress = NO;

                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil) attributes:self.textViewAttributes];
                                               self.textView.hidden = NO;

                                               self.messageUpdateTimer = [NSTimer timerWithTimeInterval:4 target:self selector:@selector(updateLoadingMessage) userInfo:nil repeats:YES];
                                               [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
                                               
                                               self.progressView.hidden = NO;
                                               
                                               [self.tableView beginUpdates];
                                               [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kLoginUsernameRow inSection:0]]
                                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                                               [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kLoginPasswordRow inSection:0]]
                                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
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
                                                       break;
                                                   }
                                                       
                                                   case PinboardErrorTimeout: {
                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                       [alert show];
                                                       [[Mixpanel sharedInstance] track:@"Cancelled log in"];
                                                       break;
                                                   }
                                               }

                                               [self resetLoginScreen];
                                               
                                               if ([self is1PasswordAvailable]) {
                                                   [self.tableView beginUpdates];
                                                   [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView endUpdates];
                                               }
                                           });
                                       }];
        });
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.usernameTextField) {
        BOOL isInsertingNewCharacters = string.length > range.length;
        if (isInsertingNewCharacters) {
            BOOL isGreaterThanOrEqualTo30Characters = textField.text.length + string.length >= 30;
            if (isGreaterThanOrEqualTo30Characters) {
                return NO;
            }
        }
        else {
            if (string.length > 0) {
                NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^[\\w\\d-\\._]+$" options:0 error:nil];
                NSInteger numMatches = [expression numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
                BOOL containsInvalidCharacters = numMatches == 0;
                if (containsInvalidCharacters) {
                    return NO;
                }
            }
        }
    }
    return YES;
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

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.progressView.hidden && section == 0) {
        return @"Pinboard Login";
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.progressView.hidden || self.loginInProgress) {
        return 1;
    }
    else {
        if ([self is1PasswordAvailable]) {
            return 2;
        }
        else {
            return 1;
        }
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

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.progressView.hidden) {
        return 44;
    }
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if (self.textView.hidden) {
            return 0;
        }
        else {
            if (self.loginInProgress) {
                return 100;
            }
            else {
                CGRect rect = [self.textView.attributedText boundingRectWithSize:CGSizeMake(300, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
                return rect.size.height + 14;
            }
        }
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if (self.textView.hidden) {
            return nil;
        }
        else {
            UIView *view = [[UIView alloc] init];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [view addSubview:self.textView];
            
            NSDictionary *views = @{@"text": self.textView };

            [view lhs_addConstraints:@"V:|-5-[text]-5-|" views:views];
            [view lhs_addConstraints:@"H:|-5-[text]-5-|" views:views];
            return view;
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoginTableCellIdentifier forIndexPath:indexPath];

    [cell.contentView lhs_removeSubviews];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch (indexPath.section) {
        case 0:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch (indexPath.row) {
                case kLoginUsernameRow: {
                    if (self.progressView.hidden) {
                        NSDictionary *views = @{@"view": self.usernameTextField };
                        [cell.contentView addSubview:self.usernameTextField];
                        [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
                    }
                    else {
                        [cell.contentView addSubview:self.progressView];
                        NSDictionary *views = @{@"progress": self.progressView};
                        [cell.contentView lhs_addConstraints:@"V:|[progress]|" views:views];
                        [cell.contentView lhs_addConstraints:@"H:|[progress]|" views:views];
                    }
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
            cell.selectionStyle = UITableViewCellSelectionStyleGray;

            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"56_Key-alt"]];
            cell.accessoryView = imageView;
            cell.textLabel.text = @"Launch 1Password";
            cell.textLabel.font = [PPTheme titleFont];
            break;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case kLoginUsernameRow:
                    if (self.progressView.hidden) {
                        [self.usernameTextField becomeFirstResponder];
                    }
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

#pragma mark - Utils

- (void)showContactForm {
    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
    
    ASStyleSheet *styleSheet = [[ASStyleSheet alloc] init];
    [UVStyleSheet setStyleSheet:styleSheet];
    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
}

- (BOOL)is1PasswordAvailable {
    return YES;
    return [[UIApplication sharedApplication] canOpenURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]];
}

@end

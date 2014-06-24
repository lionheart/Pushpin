//
//  LoginViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import "PPLoginViewController.h"
@import QuartzCore;
#import "PPAppDelegate.h"
#import "PPPinboardDataSource.h"
#import "PPFeedListViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "ASStyleSheet.h"
#import "PPTableViewTitleView.h"
#import "PPDeliciousDataSource.h"

#import <uservoice-iphone-sdk/UserVoice.h>
#import <RPSTPasswordManagementAppService/RPSTPasswordManagementAppService.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/NSData+Base64.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSDelicious/LHSDelicious.h>

@interface PPLoginViewController ()

@property (nonatomic) BOOL loginInProgress;

@end

@implementation PPLoginViewController

static NSString *LoginTableCellIdentifier = @"LoginTableViewCell";

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

#ifdef DELICIOUS
    self.title = @"Pushpin for Delicious";
#endif
    
#ifdef PINBOARD
    self.title = @"Pushpin";
#endif
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
}

- (void)resetLoginScreen {
    self.loginInProgress = NO;

    self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil) attributes:self.textViewAttributes];
    self.textView.hidden = YES;
    
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];

    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help", nil) style:UIBarButtonItemStyleDone target:self action:@selector(showContactForm)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Log In", nil) style:UIBarButtonItemStyleDone target:self action:@selector(login)];
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
#ifdef DELICIOUS
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter both a username and password to sign into Delicious." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
#endif

#ifdef PINBOARD
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please enter both a username and password to sign into Pinboard.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
#endif
            [alert show];
            self.loginInProgress = NO;
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
            
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
            
            void (^LoginSuccessBlock)() = ^{
                self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil) attributes:self.textViewAttributes];
                self.textView.hidden = NO;
                
                self.messageUpdateTimer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(updateLoadingMessage) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
                
                self.progressView.hidden = NO;
                
                [CATransaction begin];
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kLoginUsernameRow inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kLoginPasswordRow inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
                [CATransaction setCompletionBlock:^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                }];
                [CATransaction begin];
            };
            
            void (^LoginFailureBlock)(NSError *) = ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (error.code) {
                        case PinboardErrorInvalidCredentials: {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentication Error", nil) message:NSLocalizedString(@"We couldn't log you in. Please make sure you've provided valid credentials.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                            [alert show];
                            [[Mixpanel sharedInstance] track:@"Failed to log in"];
                            break;
                        }

                        case PinboardErrorTimeout: {
#ifdef DELICIOUS
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Delicious is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
#endif
                            
#ifdef PINBOARD
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
#endif
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
            };
            
            void (^UpdateProgressBlock)(NSInteger, NSInteger) = ^(NSInteger current, NSInteger total) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (total == current) {
                        [self.messageUpdateTimer invalidate];
                        self.activityIndicator.frame = self.activityIndicatorFrameTop;
                        self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Finalizing Metadata", nil) attributes:self.textViewAttributes];
                    }
                    else {
                        CGFloat f = current / (float)total;
                        [self.progressView setProgress:f animated:YES];
                    }
                });
            };
            
            void (^SyncCompletedBlock)() = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageUpdateTimer invalidate];
                    
                    if ([UIApplication isIPad]) {
                        [delegate.window setRootViewController:delegate.splitViewController];
                    }
                    else {
                        delegate.navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                        [self presentViewController:delegate.navigationController
                                           animated:YES
                                         completion:nil];
                    }
                });

                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel identify:[delegate username]];
                [mixpanel.people set:@"$created" to:[NSDate date]];
                [mixpanel.people set:@"$username" to:[delegate username]];
                [mixpanel.people set:@"Browser" to:@"Webview"];
            };

#ifdef DELICIOUS
            [delegate migrateDatabase];

            LHSDelicious *delicious = [LHSDelicious sharedInstance];
            [delicious authenticateWithUsername:self.usernameTextField.text
                                       password:self.passwordTextField.text
                                     completion:^(NSError *error) {
                                         if (error) {
                                             LoginFailureBlock(error);
                                         }
                                         else {
                                             self.loginInProgress = NO;
                                             delegate.username = self.usernameTextField.text;
                                             delegate.password = self.passwordTextField.text;
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 LoginSuccessBlock();
                                                 
                                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                     PPDeliciousDataSource *dataSource = [[PPDeliciousDataSource alloc] init];
                                                     
                                                     [dataSource syncBookmarksWithCompletion:^(NSError *error) {
                                                         if (!error) {
                                                             SyncCompletedBlock();
                                                         }
                                                     } progress:UpdateProgressBlock];
                                                     
                                                     Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                     [mixpanel identify:delegate.username];
                                                     [mixpanel.people set:@"$created" to:[NSDate date]];
                                                     [mixpanel.people set:@"$username" to:[delegate username]];
                                                     [mixpanel.people set:@"Browser" to:@"Webview"];
                                                 });
                                             });
                                         }
                                     }];
#endif

#ifdef PINBOARD
            [delegate migrateDatabase];

            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard authenticateWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                       success:^(NSString *token) {
                                           self.loginInProgress = NO;
                                           delegate.password = self.passwordTextField.text;
                                           
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               LoginSuccessBlock();
                                               
                                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                   delegate.token = token;
                                                   PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];

                                                   [dataSource syncBookmarksWithCompletion:^(NSError *error) {
                                                       if (error) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               [[[UIAlertView alloc] initWithTitle:nil message:error.description delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                                                           });
                                                       }
                                                       else {
                                                           SyncCompletedBlock();
                                                       }
                                                   } progress:UpdateProgressBlock];

                                                   [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                                       [delegate setFeedToken:feedToken];
                                                   }];
                                               });
                                           });
                                       }
                                       failure:LoginFailureBlock];
#endif
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
#ifdef DELICIOUS
    return @"Delicious Login";
#endif
        
#ifdef PINBOARD
    return @"Pinboard Login";
#endif
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
                return 120;
            }
            else {
                CGFloat width = CGRectGetWidth(tableView.frame) - 20;
                CGRect rect = [self.textView.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                         context:nil];
                return CGRectGetHeight(rect) + 30;
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
    
    [ASStyleSheet applyStyles];
    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
}

- (BOOL)is1PasswordAvailable {
    return [[UIApplication sharedApplication] canOpenURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]];
}

@end

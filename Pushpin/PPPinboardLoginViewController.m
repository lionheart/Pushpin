//
//  PPPinboardLoginViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

@import QuartzCore;
@import LHSCategoryCollection;
@import ASPinboard;
@import MessageUI;

#if !TARGET_OS_MACCATALYST
@import Beacon;
#endif

#import "PPPinboardLoginViewController.h"
#import "PPAppDelegate.h"
#import "PPPinboardDataSource.h"
#import "PPFeedListViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPTableViewTitleView.h"
#import "PPSettings.h"
#import "PPUtilities.h"

@interface PPPinboardLoginViewController ()

@property (nonatomic, strong) UITextField *authTokenTextField;
@property (nonatomic, strong) UITextView *authTokenFooterTextView;

@property (nonatomic) BOOL loginInProgress;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UITextView *textView;

- (BOOL)authTokenProvided;

@end

@implementation PPPinboardLoginViewController

static NSString *LoginTableCellIdentifier = @"LoginTableViewCell";

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    

    self.title = @"Pinboard";
    self.loginInProgress = NO;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(showContactForm)];

    self.tableView.backgroundColor = HEX(0xeeeeeeff);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:LoginTableCellIdentifier];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.hidden = YES;

    self.textViewAttributes = @{NSFontAttributeName: [PPTheme detailLabelFontAlternate1]};
    

    self.authTokenFooterTextView = [[UITextView alloc] init];
    self.authTokenFooterTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authTokenFooterTextView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Note: Logging in with your API token will prevent Pushpin from accessing Pinboard's full-text search feature.", nil)
                                                                                  attributes:self.textViewAttributes];
    self.authTokenFooterTextView.backgroundColor = [UIColor clearColor];
    self.authTokenFooterTextView.textColor = [UIColor darkGrayColor];
    self.authTokenFooterTextView.editable = NO;
    self.authTokenFooterTextView.hidden = NO;
    self.authTokenFooterTextView.userInteractionEnabled = NO;
    self.authTokenFooterTextView.textAlignment = NSTextAlignmentLeft;
    
    self.authTokenTextField = [[UITextField alloc] init];
    self.authTokenTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.authTokenTextField.font = [PPTheme titleFont];
    self.authTokenTextField.textAlignment = NSTextAlignmentLeft;
    self.authTokenTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.authTokenTextField.backgroundColor = [UIColor whiteColor];
    self.authTokenTextField.delegate = self;
    self.authTokenTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.authTokenTextField.returnKeyType = UIReturnKeyDone;
    self.authTokenTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.authTokenTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.authTokenTextField.placeholder = NSLocalizedString(@"username:NNNNNN", nil);

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

    NSString *textViewText = NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil);
    
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:textViewText
                                                                   attributes:self.textViewAttributes];
    self.textView.hidden = YES;

    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];

    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Log In", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(login)];
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
            @"Nulling Initialization Pointers",
            @"Calibrating Tag Optimizations",
            @"Polishing Retina Displays",
            @"Refactoring Applicative Factors",
            @"Regenerating Provisioning Profiles",
            @"Releasing View Controllers",
            @"Reticulating Splines",
            @"Reversing Feed Originators",
            @"Force Carbing Kegs",
            @"Repairing Hyperdrive Motivators",
        ];
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:messages[arc4random_uniform((uint32_t)messages.count)]
                                                                       attributes:self.textViewAttributes];
    });
}

- (void)loginFailureCallback:(NSError *)error authTokenProvided:(BOOL)authTokenProvided {
    if (error != nil) {
        switch (error.code) {
            case PinboardErrorInvalidCredentials: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Authentication Error", nil)
                                                                                 message:NSLocalizedString(@"We couldn't log you in. Please make sure you've provided valid credentials.", nil)];

                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:nil];

                    [self presentViewController:alert animated:YES completion:nil];
                });

                
                break;
            }

            case PinboardErrorTimeout: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil);

                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                 message:message];

                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:nil];

                    [self presentViewController:alert animated:YES completion:nil];
                });

                
                break;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetLoginScreen];
        [self.tableView beginUpdates];

        if (authTokenProvided) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPLoginCredentialSection] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPLoginAuthTokenSection] withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView endUpdates];
    });
}

- (void)syncCompletedCallback {
    [self.messageUpdateTimer invalidate];

    dispatch_async(dispatch_get_main_queue(), ^{
        PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

        if ([UIApplication isIPad]) {
            [delegate.window setRootViewController:delegate.splitViewController];
        } else {
            delegate.navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:delegate.navigationController
                               animated:YES
                             completion:nil];
        }
    });

    PPSettings *settings = [PPSettings sharedSettings];
    
    
    
    
    
}

- (void)updateProgressCallback:(NSInteger)current total:(NSInteger)total {
    if (current < total) {
        float f = current / (float)total;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:f animated:YES];
        });
    } else {
        [self.messageUpdateTimer invalidate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityIndicator.frame = self.activityIndicatorFrameTop;
            self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Finalizing Metadata", nil)
                                                                           attributes:self.textViewAttributes];
        });
    }
}

- (void)loginSuccessCallback:(BOOL)authTokenProvided {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil)
                                                                       attributes:self.textViewAttributes];
        self.textView.hidden = NO;
        self.title = NSLocalizedString(@"Downloading", nil);
        
        self.messageUpdateTimer = [NSTimer timerWithTimeInterval:3
                                                          target:self
                                                        selector:@selector(updateLoadingMessage)
                                                        userInfo:nil
                                                         repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
        
        self.progressView.hidden = NO;
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPLoginCredentialSection] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];

            [dataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
                if (error) {
                    [self loginFailureCallback:error authTokenProvided:authTokenProvided];
                } else {
                    [self syncCompletedCallback];
                }
            } progress:^(NSInteger current, NSInteger total) {
                [self updateProgressCallback:current total:total];
            }];
        });
    });
}

- (void)login {
    if (!self.loginInProgress) {
        self.loginInProgress = YES;

        BOOL authTokenProvided = [self authTokenProvided];
        BOOL usernameAndPasswordProvided = self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0;
        BOOL validCredentialsProvided = usernameAndPasswordProvided || authTokenProvided;

        if (!validCredentialsProvided) {
            NSString *message = NSLocalizedString(@"Please enter both a username and password to sign into Pinboard.", nil);

            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                           message:message];
            
            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
            
            [self presentViewController:alert animated:YES completion:nil];
            self.loginInProgress = NO;
            return;
        }

        PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
        
        UIActivityIndicatorView *loginActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [loginActivityView startAnimating];
        
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loginActivityView];
        
        self.usernameTextField.enabled = NO;
        self.usernameTextField.textColor = [UIColor grayColor];

        self.passwordTextField.enabled = NO;
        self.passwordTextField.textColor = [UIColor grayColor];

        self.textView.hidden = NO;
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Verifying your credentials...", nil)
                                                                       attributes:self.textViewAttributes];
        
        [self.tableView beginUpdates];

        if (authTokenProvided) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPLoginCredentialSection] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPLoginAuthTokenSection] withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView endUpdates];

        [PPUtilities resetDatabase];
        [PPUtilities migrateDatabase];

        ASPinboard *pinboard = [ASPinboard sharedInstance];
        PPSettings *settings = [PPSettings sharedSettings];
        if (authTokenProvided) {
            // Check if the auth token passes.
            pinboard.token = self.authTokenTextField.text;
            [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (feedToken) {
                        NSString *token = self.authTokenTextField.text;

                        settings.feedToken = feedToken;
                        settings.token = token;

                        [self loginSuccessCallback:authTokenProvided];
                    } else {
                        NSError *error = [NSError errorWithDomain:ASPinboardErrorDomain code:PinboardErrorInvalidCredentials userInfo:nil];
                        [self loginFailureCallback:error authTokenProvided:authTokenProvided];
                    }
                });
            } failure:^(NSError *error) {
                [self loginFailureCallback:error authTokenProvided:authTokenProvided];
            }];
        } else {
            [pinboard authenticateWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                       success:^(NSString *token) {
                                           settings.password = self.passwordTextField.text;
                                           settings.token = token;

                                           [self loginSuccessCallback:authTokenProvided];

                                           [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                               settings.feedToken = feedToken;
                                           } failure:nil];
                                       }
                                       failure:^(NSError *error) {
                                           [self loginFailureCallback:error authTokenProvided:authTokenProvided];
                                       }];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.usernameTextField) {
        BOOL isInsertingNewCharacters = string.length > range.length;
        if (isInsertingNewCharacters) {
            BOOL isGreaterThanOrEqualTo40Characters = textField.text.length + string.length >= 40;
            if (isGreaterThanOrEqualTo40Characters) {
                return NO;
            }
        } else {
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
    } else if (textField == self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
        [self login];
    }
    
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((PPLoginSectionType)section) {
        case PPLoginCredentialSection:
            if (self.progressView.hidden) {
                

                return @"Pinboard Login";
            }
            break;
            
        case PPLoginAuthTokenSection:
            return @"API Token";
            
        default:
            return nil;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.loginInProgress) {
        return 1;
    } else {
        return PPLoginSectionCount;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.progressView.hidden) {
        if (self.loginInProgress && [self authTokenProvided]) {
            section++;
        }
        
        switch ((PPLoginSectionType)section) {
            case PPLoginCredentialSection:
                return 2;
                
            case PPLoginAuthTokenSection:
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
    switch ((PPLoginSectionType)section) {
        case PPLoginCredentialSection:
            if (self.textView.hidden) {
                return 0;
            } else {
                if (self.loginInProgress) {
                    return 120;
                } else {
                    CGFloat width = CGRectGetWidth(tableView.frame) - 20;
                    CGRect rect = [self.textView.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                             context:nil];
                    return CGRectGetHeight(rect) + 30;
                }
            }
            

        case PPLoginAuthTokenSection: {
            CGFloat width = CGRectGetWidth(tableView.frame) - 20;
            CGRect rect = [self.authTokenFooterTextView.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                                    context:nil];
            return CGRectGetHeight(rect) + 30;
        }

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    switch ((PPLoginSectionType)section) {
        case PPLoginCredentialSection:
            if (self.textView.hidden) {
                return nil;
            } else {
                UIView *view = [[UIView alloc] init];
                view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [view addSubview:self.textView];
                [self.textView lhs_expandToFillSuperviewWithMargins:UIEdgeInsetsMake(5, 5, 5, 5)];
                return view;
            }

            break;
            

        case PPLoginAuthTokenSection:
            if (self.authTokenFooterTextView.hidden) {
                return nil;
            } else {
                UIView *view = [[UIView alloc] init];
                view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [view addSubview:self.authTokenFooterTextView];
                [self.authTokenFooterTextView lhs_expandToFillSuperviewWithMargins:UIEdgeInsetsMake(5, 5, 5, 5)];
                return view;
            }
            break;
            
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoginTableCellIdentifier forIndexPath:indexPath];

    [cell.contentView lhs_removeSubviews];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch ((PPLoginSectionType)indexPath.section) {
        case PPLoginCredentialSection:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPLoginCredentialRowType)indexPath.row) {
                case PPLoginCredentialUsernameRow: {
                    if (self.progressView.hidden) {
                        NSDictionary *views = @{@"view": self.usernameTextField };
                        [cell.contentView addSubview:self.usernameTextField];
                        [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
                    } else {
                        [cell.contentView addSubview:self.progressView];
                        NSDictionary *views = @{@"progress": self.progressView};
                        [cell.contentView lhs_addConstraints:@"V:|[progress]|" views:views];
                        [cell.contentView lhs_addConstraints:@"H:|[progress]|" views:views];
                    }
                    break;
                }
                    
                case PPLoginCredentialPasswordRow: {
                    NSDictionary *views = @{@"view": self.passwordTextField };
                    [cell.contentView addSubview:self.passwordTextField];
                    [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
                    break;
                }
            }
            break;
            

        case PPLoginAuthTokenSection: {
            NSDictionary *views = @{@"view": self.authTokenTextField };
            [cell.contentView addSubview:self.authTokenTextField];
            [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ((PPLoginSectionType)indexPath.section) {
        case PPLoginCredentialSection:
            switch ((PPLoginCredentialRowType)indexPath.row) {
                case PPLoginCredentialUsernameRow:
                    if (self.progressView.hidden) {
                        [self.usernameTextField becomeFirstResponder];
                    }
                    break;
                    
                case PPLoginCredentialPasswordRow:
                    [self.passwordTextField becomeFirstResponder];
                    break;
            }

            break;


        case PPLoginAuthTokenSection:
            [self.authTokenTextField becomeFirstResponder];
            break;
            
        default:
            break;
    }
}

#pragma mark - Utils
            
- (BOOL)authTokenProvided {
    return self.authTokenTextField.text.length > 0;
}

#if !TARGET_OS_MACCATALYST
#pragma mark - Utils

- (void)showContactForm {
    HSBeaconSettings *settings = [[HSBeaconSettings alloc] initWithBeaconId:kHelpScoutBeaconId];
    settings.delegate = self;
    [HSBeacon openBeacon:settings];
}

#pragma mark - HSBeaconDelegate

- (void)prefill:(HSBeaconContactForm *)form {
    form.subject = @"Pushpin Support Inquiry";
}
#endif

@end

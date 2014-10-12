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
#import "PPSettings.h"

#import <uservoice-iphone-sdk/UserVoice.h>
#import <RPSTPasswordManagementAppService/RPSTPasswordManagementAppService.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/NSData+Base64.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSDelicious/LHSDelicious.h>
#import <OnePasswordExtension.h>

@interface PPLoginViewController ()

#ifdef PINBOARD
@property (nonatomic, strong) UITextField *authTokenTextField;
@property (nonatomic, strong) UITextView *authTokenFooterTextView;
#endif

@property (nonatomic) BOOL loginInProgress;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UITextView *textView;

- (BOOL)authTokenProvided;

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
    
#ifdef PINBOARD
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
    self.authTokenTextField.placeholder = NSLocalizedString(@"username:NNNNNN", nil);
#endif

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

#ifdef PINBOARD
    NSString *textViewText = NSLocalizedString(@"Enter your Pinboard credentials above. Email support@lionheartsw.com if you have any issues.", nil);
#endif
    
#ifdef DELICIOUS
    NSString *textViewText = NSLocalizedString(@"Enter your Delicious credentials above. Email support@lionheartsw.com if you have any issues.", nil);
#endif
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:textViewText
                                                                   attributes:self.textViewAttributes];
    self.textView.hidden = YES;

    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];

    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(showContactForm)];

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
            @"Calibrating Tag Optimizations",
            @"Polishing Retina Displays",
            @"Refactoring Applicative Factors",
            @"Regenerating Provisioning Profiles",
            @"Releasing View Controllers",
            @"Reticulating Splines",
            @"Reversing Feed Originators",
        ];
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:messages[arc4random_uniform((uint32_t)messages.count)]
                                                                       attributes:self.textViewAttributes];
    });
}

- (void)login {
    if (!self.loginInProgress) {
        self.loginInProgress = YES;

#ifdef PINBOARD
        BOOL authTokenProvided = [self authTokenProvided];
#endif

        BOOL usernameAndPasswordProvided = self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0;
#ifdef PINBOARD
        BOOL validCredentialsProvided = usernameAndPasswordProvided || authTokenProvided;
#else
        BOOL validCredentialsProvided = usernameAndPasswordProvided;
#endif

        if (!validCredentialsProvided) {
#ifdef DELICIOUS
            NSString *message = NSLocalizedString(@"Please enter both a username and password to sign into Delicious.", nil);
#endif

#ifdef PINBOARD
            NSString *message = NSLocalizedString(@"Please enter both a username and password to sign into Pinboard.", nil);
#endif

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
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
            self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Verifying your credentials...", nil)
                                                                           attributes:self.textViewAttributes];
            
            [self.tableView beginUpdates];
            
#ifdef PINBOARD
            if (authTokenProvided) {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPLoginCredentialSection] withRowAnimation:UITableViewRowAnimationFade];
            }
            else {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPLoginAuthTokenSection] withRowAnimation:UITableViewRowAnimationFade];
            }
#endif
            
#ifdef DELICIOUS
#endif

            if ([self is1PasswordAvailable]) {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPLogin1PasswordSection] withRowAnimation:UITableViewRowAnimationFade];
            }

            [self.tableView endUpdates];
            
            void (^LoginSuccessBlock)() = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.textView.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil)
                                                                                   attributes:self.textViewAttributes];
                    self.textView.hidden = NO;
                    
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
                });
            };
            
            void (^LoginFailureBlock)(NSError *) = ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (error.code) {
                        case PinboardErrorInvalidCredentials: {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Authentication Error", nil)
                                                                                           message:NSLocalizedString(@"We couldn't log you in. Please make sure you've provided valid credentials.", nil)
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            
                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:nil]];
                            
                            [self presentViewController:alert animated:YES completion:nil];
                            
                            [[Mixpanel sharedInstance] track:@"Failed to log in"];
                            break;
                        }
                            
                        case LHSDeliciousErrorEmptyResponse:
                            break;

                        case PinboardErrorTimeout: {
#ifdef DELICIOUS
                            NSString *message = NSLocalizedString(@"Delicious is currently down. Please try logging in later.", nil);
#endif
                            
#ifdef PINBOARD
                            NSString *message = NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil);
#endif

                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                           message:message
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            
                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:nil]];
                            
                            [self presentViewController:alert animated:YES completion:nil];

                            [[Mixpanel sharedInstance] track:@"Cancelled log in"];
                            break;
                        }
                    }
                    
                    [self resetLoginScreen];
                    
                    [self.tableView beginUpdates];

#ifdef PINBOARD
                    if (authTokenProvided) {
                        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPLoginCredentialSection] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    else {
                        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPLoginAuthTokenSection] withRowAnimation:UITableViewRowAnimationFade];
                    }
#endif

                    if ([self is1PasswordAvailable]) {
                        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPLogin1PasswordSection] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    [self.tableView endUpdates];
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
                
                PPSettings *settings = [PPSettings sharedSettings];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel identify:settings.username];
                [mixpanel.people set:@"$created" to:[NSDate date]];
                [mixpanel.people set:@"$username" to:settings.username];
                [mixpanel.people set:@"Browser" to:@"Webview"];
            };

            [PPUtilities resetDatabase];
            [PPUtilities migrateDatabase];
#ifdef DELICIOUS

            LHSDelicious *delicious = [LHSDelicious sharedInstance];
            [delicious authenticateWithUsername:self.usernameTextField.text
                                       password:self.passwordTextField.text
                                     completion:^(NSError *error) {
                                         if (error) {
                                             LoginFailureBlock(error);
                                         }
                                         else {
                                             settings.username = self.usernameTextField.text;
                                             settings.password = self.passwordTextField.text;
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 LoginSuccessBlock();
                                                 
                                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                     PPDeliciousDataSource *dataSource = [[PPDeliciousDataSource alloc] init];
                                                     
                                                     [dataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
                                                         if (!error) {
                                                             SyncCompletedBlock();
                                                         }
                                                     } progress:UpdateProgressBlock];
                                                     
                                                     Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                     [mixpanel identify:settings.username];
                                                     [mixpanel.people set:@"$created" to:[NSDate date]];
                                                     [mixpanel.people set:@"$username" to:[delegate username]];
                                                     [mixpanel.people set:@"Browser" to:@"Webview"];
                                                 });
                                             });
                                         }
                                     }];
#endif

#ifdef PINBOARD
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            
            void (^PinboardAuthenticationSuccessBlock)() = ^{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
                    
                    [dataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
                        if (error) {
                            LoginFailureBlock(error);
                        }
                        else {
                            SyncCompletedBlock();
                        }
                    } progress:UpdateProgressBlock];
                });
            };
            
            PPSettings *settings = [PPSettings sharedSettings];
            if (authTokenProvided) {
                // Check if the auth token passes.
                pinboard.token = self.authTokenTextField.text;
                [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                    settings.feedToken = feedToken;
                    settings.token = self.authTokenTextField.text;

                    LoginSuccessBlock();
                    PinboardAuthenticationSuccessBlock();
                } failure:LoginFailureBlock];
            }
            else {
                [pinboard authenticateWithUsername:self.usernameTextField.text
                                          password:self.passwordTextField.text
                                           success:^(NSString *token) {
                                               settings.password = self.passwordTextField.text;
                                               settings.token = token;
                                               
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   LoginSuccessBlock();
                                                   PinboardAuthenticationSuccessBlock();
                                                   
                                                   [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                                       settings.feedToken = feedToken;
                                                   } failure:nil];
                                               });
                                           }
                                           failure:LoginFailureBlock];
            }
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
    switch ((PPLoginSectionType)section) {
        case PPLoginCredentialSection:
            if (self.progressView.hidden) {
#ifdef DELICIOUS
                return @"Delicious Login";
#endif
                
#ifdef PINBOARD
                return @"Pinboard Login";
#endif
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
        DLog(@"A");
        return 1;
    }
    else {
        if ([self is1PasswordAvailable]) {
            DLog(@"B");
            return PPLoginSectionCount;
        }
        else {
            DLog(@"C");
            return PPLoginSectionCount - 1;
        }
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
                
            case PPLogin1PasswordSection:
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
            
#ifdef PINBOARD
        case PPLoginAuthTokenSection: {
            CGFloat width = CGRectGetWidth(tableView.frame) - 20;
            CGRect rect = [self.authTokenFooterTextView.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                                    context:nil];
            return CGRectGetHeight(rect) + 30;
        }
#endif

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    switch ((PPLoginSectionType)section) {
        case PPLoginCredentialSection:
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

            break;
            
#ifdef PINBOARD
        case PPLoginAuthTokenSection:
            if (self.authTokenFooterTextView.hidden) {
                return nil;
            }
            else {
                UIView *view = [[UIView alloc] init];
                view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [view addSubview:self.authTokenFooterTextView];
                
                NSDictionary *views = @{@"text": self.authTokenFooterTextView };
                [view lhs_addConstraints:@"V:|-5-[text]-5-|" views:views];
                [view lhs_addConstraints:@"H:|-5-[text]-5-|" views:views];
                return view;
            }
            break;
#endif
            
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
                    }
                    else {
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
            
#ifdef PINBOARD
        case PPLoginAuthTokenSection: {
            NSDictionary *views = @{@"view": self.authTokenTextField };
            [cell.contentView addSubview:self.authTokenTextField];
            [cell.contentView lhs_addConstraints:@"H:|-15-[view]-5-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-5-[view]-5-|" views:views];
            break;
        }
#endif
            
        case PPLogin1PasswordSection: {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;

            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"56_Key-alt"]];
            cell.accessoryView = imageView;
            cell.textLabel.text = NSLocalizedString(@"Launch 1Password", nil);
            cell.textLabel.font = [PPTheme titleFont];
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

#ifdef PINBOARD
        case PPLoginAuthTokenSection:
            [self.authTokenTextField becomeFirstResponder];
            break;
#endif

        case PPLogin1PasswordSection: {
            __weak typeof (self) weakself = self;
            UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
            [[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://pinboard.in"
                                                        forViewController:self
                                                                   sender:cell
                                                               completion:^(NSDictionary *loginDict, NSError *error) {
                                                                   if (!loginDict) {
                                                                       if (error.code != AppExtensionErrorCodeCancelledByUser) {
                                                                           NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
                                                                       }
                                                                       return;
                                                                   }

                                                                   __strong typeof(self) strongself = weakself;
                                                                   strongself.usernameTextField.text = loginDict[AppExtensionUsernameKey];
                                                                   strongself.passwordTextField.text = loginDict[AppExtensionPasswordKey];
            }];
            break;
        }
            
        default:
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
#ifdef PINBOARD
    NSString *searchTerm = @"pinboard";
#endif
    
#ifdef DELICIOUS
    NSString *searchTerm = @"delicious";
#endif
    return [[UIApplication sharedApplication] canOpenURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:searchTerm]];
}
            
- (BOOL)authTokenProvided {
    return self.authTokenTextField.text.length > 0;
}

@end

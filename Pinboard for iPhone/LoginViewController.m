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
#import "UIApplication+AppDimensions.h"
#import "LoginTableCell.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = [UIApplication currentSize];
    
    self.tableView.sectionFooterHeight = 0;
    
    [self.tableView registerClass:[LoginTableCell class] forCellReuseIdentifier:LoginTableCellIdentifier];
    
    /*
    self.onePasswordButton = [[UIButton alloc] initWithFrame:CGRectMake((size.width - 180) / 2, 352, 180, 44)];
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
    */

    /*
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGSize activitySize = self.activityIndicator.frame.size;
    self.activityIndicatorFrameTop = CGRectMake((size.width - activitySize.width) / 2., 380, activitySize.width, activitySize.height);
    self.activityIndicatorFrameMiddle = CGRectMake((size.width - activitySize.width) / 2., 400, activitySize.width, activitySize.height);
    self.activityIndicatorFrameBottom = CGRectMake((size.width - activitySize.width) / 2., 425, activitySize.width, activitySize.height);
    self.activityIndicator.frame = self.activityIndicatorFrameTop;
    [self.view addSubview:self.activityIndicator];
     */

    keyboard_shown = false;
    self.loginTimer = nil;
    
    [self resetLoginScreen];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardWillHideNotification object:nil];
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

- (void)keyboardWasShown:(NSNotification *)notification {
    if (!keyboard_shown) {
        NSDictionary *info = [notification userInfo];
        NSValue *notificationData = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
        
        NSTimeInterval duration = 0;
        NSValue *infoDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [infoDuration getValue:&duration];

        CGSize keyboardSize = [notificationData CGRectValue].size;

        CGRect frame = self.view.frame;
        frame.origin.y -= keyboardSize.height - 50;
        frame.size.height += keyboardSize.height - 50;

        [UIView animateWithDuration:duration animations:^(void) {
            self.view.frame = frame;
        }];
        
        keyboard_shown = true;
    }
}

- (void)keyboardWasHidden:(NSNotification *)notification {
    if (keyboard_shown) {
        NSDictionary *info = [notification userInfo];
        NSValue *notificationData = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
        CGSize keyboardSize = [notificationData CGRectValue].size;
        
        NSTimeInterval duration = 0;
        NSValue *infoDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [infoDuration getValue:&duration];

        CGRect frame = self.view.frame;
        frame.origin.y += keyboardSize.height - 50;
        frame.size.height -= keyboardSize.height - 50;

        [UIView animateWithDuration:duration animations:^(void) {
            self.view.frame = frame;
        }];

        keyboard_shown = false;
    }
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
    self.textView.text = NSLocalizedString(@"Enter your Pinboard credentials above. Email support support@aurora.io if you have any issues.", nil);

    LoginTableCell *usernameCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    LoginTableCell *passwordCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [usernameCell.inputField setEnabled:YES];
    usernameCell.inputField.textColor = [UIColor blackColor];
    [passwordCell.inputField setEnabled:YES];
    passwordCell.inputField.textColor = [UIColor blackColor];

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
            //self.activityIndicator.frame = self.activityIndicatorFrameMiddle;
        });
    });
}

- (IBAction)login:(id)sender {
    LoginTableCell *usernameCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    LoginTableCell *passwordCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    if (![usernameCell.inputField.text isEqualToString:@""] && ![passwordCell.inputField.text isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            
            //self.activityIndicator.frame = self.activityIndicatorFrameTop;
            //[self.activityIndicator startAnimating];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            [self.navigationItem.rightBarButtonItem setTitle:@"Wait"];
            usernameCell.inputField.enabled = NO;
            usernameCell.inputField.textColor = [UIColor grayColor];
            passwordCell.inputField.enabled = NO;
            passwordCell.inputField.textColor = [UIColor grayColor];
            self.onePasswordButton.hidden = YES;
            self.textView.hidden = NO;
            self.textView.text = NSLocalizedString(@"Verifying your credentials...", nil);
        
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard authenticateWithUsername:usernameCell.inputField.text
                                      password:passwordCell.inputField.text
                                       success:^(NSString *token) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               //self.activityIndicator.frame = self.activityIndicatorFrameBottom;
                                               self.textView.text = NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil);
                                               self.messageUpdateTimer = [NSTimer timerWithTimeInterval:6 target:self selector:@selector(updateLoadingMessage) userInfo:nil repeats:YES];
                                               [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
                                               
                                               self.progressView.hidden = NO;

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
    LoginTableCell *usernameCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    LoginTableCell *passwordCell = (LoginTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if (textField == usernameCell.inputField) {
        [passwordCell.inputField becomeFirstResponder];
    } else if (textField == passwordCell.inputField) {
        [passwordCell.inputField resignFirstResponder];
        [self login:nil];
    }
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin"]];
        return logoView.frame.size.height;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin"]];
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        return logoView;
    }
    return nil;
}
*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LoginTableCell *cell = [tableView dequeueReusableCellWithIdentifier:LoginTableCellIdentifier forIndexPath:indexPath];

    switch (indexPath.row) {
        case 0:
            cell.imageView.image = [UIImage imageNamed:@"user"];
            cell.inputField.placeholder = @"Username";
            break;
        case 1:
            cell.imageView.image = [UIImage imageNamed:@"lock"];
            cell.inputField.placeholder = @"Password";
            [cell.inputField setSecureTextEntry:YES];
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [((LoginTableCell *)[tableView cellForRowAtIndexPath:indexPath]).inputField becomeFirstResponder];
}

@end

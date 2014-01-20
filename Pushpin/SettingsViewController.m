//
//  SettingsViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <ASPinboard/ASPinboard.h>
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "ASStyleSheet.h"
#import "NSString+URLEncoding.h"
#import "PPBrowserSettingsViewController.h"
#import "PPDisplaySettingsViewController.h"
#import "PPAboutViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "UITableViewCellValue1.h"
#import "PPMobilizerUtility.h"
#import "PPConstants.h"
#import "PPTwitter.h"

#import <uservoice-iphone-sdk/UserVoice.h>
#import <uservoice-iphone-sdk/UVStyleSheet.h>
#import <FMDB/FMDatabase.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About Navigation Bar", nil)
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(showAboutPage)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.logOutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"This will log you out and delete the local bookmark database from your device.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Logout", nil), nil];

    self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Contact Support", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Request a feature", nil), NSLocalizedString(@"Report a bug", nil), @"Tweet us", NSLocalizedString(@"Email us", nil), nil];

    self.mobilizerActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Google", @"Readability", @"Instapaper", nil];

    self.readLaterActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];

    self.readLaterServices = [NSMutableArray array];
    [self.readLaterServices addObject:@[@(PPReadLaterInstapaper)]];
    [self.readLaterActionSheet addButtonWithTitle:@"Instapaper"];
    [self.readLaterServices addObject:@[@(PPReadLaterReadability)]];
    [self.readLaterActionSheet addButtonWithTitle:@"Readability"];
    [self.readLaterServices addObject:@[@(PPReadLaterPocket)]];
    [self.readLaterActionSheet addButtonWithTitle:@"Pocket"];
    [self.readLaterActionSheet addButtonWithTitle:NSLocalizedString(@"None", nil)];
    [self.readLaterActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    self.readLaterActionSheet.cancelButtonIndex = self.readLaterActionSheet.numberOfButtons - 1;

    self.instapaperAlertView = [[UIAlertView alloc] initWithTitle:@"Instapaper Login" message:@"Password may be blank." delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"Log In", nil];
    self.instapaperAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[self.instapaperAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self.instapaperAlertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyNext];
    [[self.instapaperAlertView textFieldAtIndex:0] setPlaceholder:@"Email Address"];
    [[self.instapaperAlertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeAlphabet];
    [[self.instapaperAlertView textFieldAtIndex:1] setReturnKeyType:UIReturnKeyGo];
    [[self.instapaperAlertView textFieldAtIndex:1] setDelegate:self];

    self.readabilityAlertView = [[UIAlertView alloc] initWithTitle:@"Readability Login" message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"Log In", nil];
    self.readabilityAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[self.readabilityAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self.readabilityAlertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyNext];
    [[self.readabilityAlertView textFieldAtIndex:0] setPlaceholder:@"Email Address"];
    [[self.readabilityAlertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeAlphabet];
    [[self.readabilityAlertView textFieldAtIndex:1] setReturnKeyType:UIReturnKeyGo];
    [[self.readabilityAlertView textFieldAtIndex:1] setDelegate:self];

    self.instapaperVerificationAlertView = [[UIAlertView alloc] initWithTitle:@"Verifying credentials"
                                                                      message:@"Logging into Instapaper."
                                                                     delegate:nil
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:nil];
    self.readabilityVerificationAlertView = [[UIAlertView alloc] initWithTitle:@"Verifying credentials"
                                                                       message:@"Logging into Readability."
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:nil];
    self.pocketVerificationAlertView = [[UIAlertView alloc] initWithTitle:@"Verifying credentials"
                                                                  message:@"Logging into Pocket."
                                                                 delegate:nil
                                                        cancelButtonTitle:nil
                                                        otherButtonTitles:nil];
    self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketStartedLogin) name:(NSString *)PocketAPILoginStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketFinishedLogin) name:(NSString *)PocketAPILoginFinishedNotification object:nil];
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == [self.instapaperAlertView textFieldAtIndex:1]) {
        [self.instapaperAlertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    else if (textField == [self.readabilityAlertView textFieldAtIndex:1]) {
        [self.readabilityAlertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Mixpanel sharedInstance] track:@"Opened settings"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)showAboutPage {
    [[Mixpanel sharedInstance] track:@"Opened about page"];
    dispatch_async(dispatch_get_main_queue(), ^{
        PPAboutViewController *aboutViewController = [[PPAboutViewController alloc] init];
        [self.navigationController pushViewController:aboutViewController animated:YES];
    });
}

- (void)closeAboutPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((PPSectionType)section) {
        case PPSectionMainSettings:
            return @"Main Settings";

        default:
            return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPSectionType)section) {
        case PPSectionMainSettings:
            return PPRowCountMain;

        case PPSectionOtherSettings:
            return PPRowCountOther;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReadLater:
                    cell.textLabel.text = NSLocalizedString(@"Read Later", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

                    PPReadLaterType readLater = [AppDelegate sharedDelegate].readLater;
                    switch (readLater) {
                        case PPReadLaterNone:
                            cell.detailTextLabel.text = NSLocalizedString(@"None", nil);
                            break;

                        case PPReadLaterInstapaper:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;

                        case PPReadLaterReadability:
                            cell.detailTextLabel.text = @"Readability";
                            break;
                            
                        case PPReadLaterPocket:
                            cell.detailTextLabel.text = @"Pocket";
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                case PPMainMobilizer:
                    cell.textLabel.text = NSLocalizedString(@"Mobilizer", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

                    PPMobilizerType mobilizer = [AppDelegate sharedDelegate].mobilizer;
                    switch (mobilizer) {
                        case PPMobilizerGoogle:
                            cell.detailTextLabel.text = @"Google";
                            break;

                        case PPMobilizerReadability:
                            cell.detailTextLabel.text = @"Readability";
                            break;

                        case PPMobilizerInstapaper:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;
                    }
                    
                    break;

                case PPMainAdvanced:
                    cell.textLabel.text = NSLocalizedString(@"Advanced Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case PPMainBrowser:
                    cell.textLabel.text = NSLocalizedString(@"Browser Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                default:
                    break;
            }
            break;
        }

        case PPSectionOtherSettings: {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;

            switch ((PPOtherSettingsRowType)indexPath.row) {
                case PPOtherRatePushpin:
                    cell.textLabel.text = @"Rate Pushpin on the App Store";
                    break;
                    
                case PPOtherFollow:
                    cell.textLabel.text = @"Follow @Pushpin_app on Twitter";
                    break;

                case PPOtherFeedback:
                    cell.textLabel.text = NSLocalizedString(@"Feedback & Support", nil);
                    break;

                case PPOtherLogout:
                    cell.textLabel.text = NSLocalizedString(@"Log Out", nil);
                    break;

                case PPOtherClearCache:
                    cell.textLabel.text = NSLocalizedString(@"Purge Cache", nil);
                    break;

                default:
                    break;
            }

            break;
        }
        default:
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ((PPSectionType)section) {
        case PPSectionOtherSettings:
            return NSLocalizedString(@"Logging out of the application will reset the bookmark database on this device.", nil);

        default:
            break;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.logOutAlertView) {
        if (buttonIndex == 1) {
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            [[ASPinboard sharedInstance] resetAuthentication];
            [delegate setToken:nil];
            [delegate setLastUpdated:nil];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:[AppDelegate databasePath] error:nil];
            [delegate setLoginViewController:nil];
            [delegate setNavigationController:nil];
            delegate.loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

            if ([UIApplication isIPad]) {
                [delegate.window setRootViewController:delegate.loginViewController];
            }
            else {
                [self presentViewController:delegate.loginViewController
                                   animated:YES
                                 completion:nil];
            }

            [[AppDelegate sharedDelegate] migrateDatabase];
        }
    }
    else if (alertView == self.instapaperAlertView) {
        // Check for cancel
        if (buttonIndex == 0)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.instapaperVerificationAlertView show];

            if (self.instapaperVerificationAlertView != nil) {
                self.loadingIndicator.center = CGPointMake(CGRectGetWidth(self.instapaperVerificationAlertView.bounds)/2, CGRectGetHeight(self.instapaperVerificationAlertView.bounds)-45);
                [self.loadingIndicator startAnimating];
                [self.instapaperVerificationAlertView addSubview:self.loadingIndicator];
            }
        });

        NSString *username = [[alertView textFieldAtIndex:0] text];
        NSString *password = [[alertView textFieldAtIndex:1] text];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/oauth/access_token"]];

        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:nil realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[
             [OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
             [OARequestParameter requestParameter:@"x_auth_username" value:username],
             [OARequestParameter requestParameter:@"x_auth_password" value:password]]];
        [request prepare];

        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   [self.instapaperVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                   if (httpResponse.statusCode == 400 || error != nil) {
                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:@"We couldn't log you into Instapaper with those credentials."
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                                   }
                                   else {
                                       OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[NSString stringWithUTF8String:[data bytes]]];
                                       KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
                                       [keychain setObject:token.key forKey:(__bridge id)kSecAttrAccount];
                                       [keychain setObject:token.secret forKey:(__bridge id)kSecValueData];
                                       
                                       [AppDelegate sharedDelegate].readLater = PPReadLaterInstapaper;
                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Instapaper"];

                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                                                       message:@"You've successfully logged in."
                                                                                      delegate:nil
                                                                             cancelButtonTitle:nil
                                                                             otherButtonTitles:nil];
                                       [alert show];
                                       int64_t delayInSeconds = 1.5;
                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                           [alert dismissWithClickedButtonIndex:0 animated:YES];
                                           [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                                 withRowAnimation:UITableViewRowAnimationFade];
                                       });
                                   }
                               }];
    }
    else if (alertView == self.readabilityAlertView) {
        // Check for cancel
        if (buttonIndex == 0)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.readabilityVerificationAlertView show];

            if (self.readabilityVerificationAlertView != nil) {
                self.loadingIndicator.center = CGPointMake(CGRectGetWidth(self.readabilityVerificationAlertView.bounds)/2, CGRectGetHeight(self.readabilityVerificationAlertView.bounds)-45);
                [self.loadingIndicator startAnimating];
                [self.readabilityVerificationAlertView addSubview:self.loadingIndicator];
            }
        });

        NSString *username = [[alertView textFieldAtIndex:0] text];
        NSString *password = [[alertView textFieldAtIndex:1] text];
        NSURL *endpoint = [NSURL URLWithString:@"https://www.readability.com/api/rest/v1/oauth/access_token/"];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:nil realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[
            [OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
            [OARequestParameter requestParameter:@"x_auth_username" value:username],
            [OARequestParameter requestParameter:@"x_auth_password" value:password]]];
        [request prepare];

        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];

                                   [self.readabilityVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                   if (!error) {
                                       OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[NSString stringWithUTF8String:[data bytes]]];
                                       KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
                                       [keychain setObject:token.key forKey:(__bridge id)kSecAttrAccount];
                                       [keychain setObject:token.secret forKey:(__bridge id)kSecValueData];
                                       
                                       [AppDelegate sharedDelegate].readLater = PPReadLaterReadability;
                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Readability"];
                                       [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                             withRowAnimation:UITableViewRowAnimationFade];

                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                                                       message:@"You've successfully logged in."
                                                                                      delegate:nil
                                                                             cancelButtonTitle:nil
                                                                             otherButtonTitles:nil];
                                       [alert show];
                                       int64_t delayInSeconds = 1.5;
                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                           [alert dismissWithClickedButtonIndex:0 animated:YES];
                                       });
                                   }
                                   else {
                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                   message:@"We couldn't log you into Readability with those credentials."
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"Shucks", nil), nil] show];
                                   }
                               }];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0) {
        if (actionSheet == self.supportActionSheet) {
            if (buttonIndex == 3) {
                MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
                emailComposer.mailComposeDelegate = self;
                [emailComposer setSubject:NSLocalizedString(@"Support Email Subject", nil)];
                [emailComposer setToRecipients:@[@"support@aurora.io"]];
                [self presentViewController:emailComposer animated:YES completion:nil];
                return;
            }
            else if (buttonIndex == 0) {
                UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                                     andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                  andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                
                [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
                return;
            }
        }
        else if (actionSheet == self.mobilizerActionSheet) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            AppDelegate *delegate = [AppDelegate sharedDelegate];

            if ([buttonTitle isEqualToString:@"Google"]) {
                delegate.mobilizer = PPMobilizerGoogle;
            }
            else if ([buttonTitle isEqualToString:@"Instapaper"]) {
                delegate.mobilizer = PPMobilizerInstapaper;
            }
            else if ([buttonTitle isEqualToString:@"Readability"]) {
                delegate.mobilizer = PPMobilizerReadability;
            }

            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainMobilizer inSection:PPSectionMainSettings]]
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
        else if (actionSheet == self.readLaterActionSheet) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

            if ([buttonTitle isEqualToString:@"Instapaper"]) {
                [self.instapaperAlertView show];
            }
            else if ([buttonTitle isEqualToString:@"Readability"]) {
                [self.readabilityAlertView show];
            }
            else if ([buttonTitle isEqualToString:@"Pocket"]) {
                [[PocketAPI sharedAPI] loginWithDelegate:nil];;
            }
            else if ([buttonTitle isEqualToString:@"None"]) {
                [AppDelegate sharedDelegate].readLater = PPReadLaterNone;
                [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"None"];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        }

        self.actionSheet = nil;
    }
    else {
        self.actionSheet = nil;
    }
}

- (void)pocketStartedLogin {
    [self.pocketVerificationAlertView show];

    if (self.pocketVerificationAlertView) {
        self.loadingIndicator.center = CGPointMake(CGRectGetWidth(self.pocketVerificationAlertView.bounds)/2, CGRectGetHeight(self.pocketVerificationAlertView.bounds)-45);
        [self.loadingIndicator startAnimating];
        [self.pocketVerificationAlertView addSubview:self.loadingIndicator];
    }
}

- (void)pocketFinishedLogin {
    [self.pocketVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
    [AppDelegate sharedDelegate].readLater = PPReadLaterPocket;
    [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Pocket"];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            BOOL isIPad = [UIApplication isIPad];
            CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
            
            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReadLater:
                    if (isIPad) {
                        if (!self.actionSheet) {
                            [self.readLaterActionSheet showFromRect:rect inView:tableView animated:YES];
                            self.actionSheet = self.readLaterActionSheet;
                        }
                    }
                    else {
                        [self.readLaterActionSheet showInView:self.navigationController.view];
                    }
                    break;
                    
                case PPMainMobilizer:
                    if (isIPad) {
                        if (!self.actionSheet) {
                            [self.mobilizerActionSheet showFromRect:rect inView:tableView animated:YES];
                            self.actionSheet = self.mobilizerActionSheet;
                        }
                    }
                    else {
                        [self.mobilizerActionSheet showInView:self.navigationController.view];
                    }
                    break;
                    
                case PPMainAdvanced:
                    [self.navigationController pushViewController:[[PPDisplaySettingsViewController alloc] init] animated:YES];
                    break;
                    
                case PPMainBrowser:
                    [self.navigationController pushViewController:[[PPBrowserSettingsViewController alloc] init] animated:YES];
                    break;
            }

            break;
        }

        case PPSectionOtherSettings: {
            switch ((PPOtherSettingsRowType)indexPath.row) {
                case PPOtherRatePushpin:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=548052590&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
                    break;
                    
                case PPOtherFollow: {
                    UIView *view = [tableView cellForRowAtIndexPath:indexPath];
                    CGPoint point = view.center;
                    [[PPTwitter sharedInstance] followScreenName:@"pushpin_app" point:point view:view callback:nil];
                    break;
                }

                case PPOtherFeedback: {
                    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                    [ASStyleSheet applyStyles];
                    [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
                    break;
                }
                    
                case PPOtherLogout:
                    [self.logOutAlertView show];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;

                case PPOtherClearCache: {
                    UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:@"Resetting Cache" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                    [loadingAlertView show];
                    
                    self.loadingIndicator.center = CGPointMake(CGRectGetWidth(loadingAlertView.bounds)/2, CGRectGetHeight(loadingAlertView.bounds)-45);
                    [self.loadingIndicator startAnimating];
                    [loadingAlertView addSubview:self.loadingIndicator];
                    
                    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                    [db open];
                    [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                    [db close];
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                        
                        UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your cache was cleared." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                        [successAlertView show];
                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [successAlertView dismissWithClickedButtonIndex:0 animated:YES];
                        });
                    });
                    break;
                }
            }
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PPSectionMainSettings) {
        switch ((PPMainSettingsRowType)indexPath.row) {
            case PPMainAdvanced:
                [self.navigationController pushViewController:[[PPDisplaySettingsViewController alloc] init] animated:YES];
                break;
                
            case PPMainBrowser:
                [self.navigationController pushViewController:[[PPBrowserSettingsViewController alloc] init] animated:YES];
                break;
                
            default:
                break;
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

@end

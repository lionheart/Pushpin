//
//  SettingsViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <ASPinboard/ASPinboard.h>
#import <QuartzCore/QuartzCore.h>

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "UserVoice.h"
#import "UVStyleSheet.h"
#import "ASStyleSheet.h"
#import "NSString+URLEncoding.h"
#import "KeychainItemWrapper.h"
#import "OAuthConsumer.h"
#import "PPBrowserSettingsViewController.h"
#import "PPDisplaySettingsViewController.h"
#import "FMDatabase.h"
#import "PPGroupedTableViewCell.h"
#import "PPAboutViewController.h"
#import "UIApplication+Additions.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize logOutAlertView;
@synthesize supportActionSheet;
@synthesize readLaterServices;
@synthesize readLaterActionSheet;
@synthesize privateByDefaultSwitch;
@synthesize instapaperAlertView;
@synthesize instapaperVerificationAlertView;
@synthesize loadingIndicator;
@synthesize readByDefaultSwitch;
@synthesize readabilityAlertView;
@synthesize readabilityVerificationAlertView;

- (id)init {
    //self = [super initWithStyle:UITableViewStyleGrouped];
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad {
    self.logOutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"This will log you out and delete the local bookmark database from your device.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Logout", nil), nil];

    self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Contact Support", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Request a feature", nil), NSLocalizedString(@"Report a bug", nil), @"Tweet us", NSLocalizedString(@"Email us", nil), nil];

    self.mobilizerActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"For stripping text, CSS, and Javascript from webpages.", nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Google", @"Readability", @"Instapaper", nil];

    self.readLaterActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Set Read Later service to:", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

    self.readLaterServices = [NSMutableArray array];
    [self.readLaterServices addObject:@[@(READLATER_INSTAPAPER)]];
    [self.readLaterActionSheet addButtonWithTitle:@"Instapaper"];
    [self.readLaterServices addObject:@[@(READLATER_READABILITY)]];
    [self.readLaterActionSheet addButtonWithTitle:@"Readability"];
    [self.readLaterServices addObject:@[@(READLATER_POCKET)]];
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

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)showAboutPage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Mixpanel sharedInstance] track:@"Opened about page"];
        PPAboutViewController *aboutViewController = [[PPAboutViewController alloc] init];
        aboutViewController.title = @"Pushpin 2.1.1";
        [self.navigationController pushViewController:aboutViewController animated:YES];
    });
}

- (void)closeAboutPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setPrivateByDefault:@(self.privateByDefaultSwitch.on)];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setReadByDefault:@(self.readByDefaultSwitch.on)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;
            break;

        case 1:
            return 3;
            break;
            
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        switch (indexPath.section) {
            case 0:
                cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ChoiceCellIdentifier];
                break;
                
            case 1:
                cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
                
            default:
                break;
        }
    }
    
    cell.accessoryView = nil;
    
    CGSize size;
    CGSize switchSize;

    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    cell.detailTextLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Private by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.privateByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateByDefaultSwitch.on = [[AppDelegate sharedDelegate] privateByDefault].boolValue;
                    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateByDefaultSwitch;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Read by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.readByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.readByDefaultSwitch.frame.size;
                    self.readByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.readByDefaultSwitch.on = [[AppDelegate sharedDelegate] readByDefault].boolValue;
                    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.readByDefaultSwitch;
                    break;
                    
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Read Later", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    switch ([[[AppDelegate sharedDelegate] readlater] integerValue]) {
                        case READLATER_NONE:
                            cell.detailTextLabel.text = NSLocalizedString(@"None", nil);
                            break;
                        case READLATER_INSTAPAPER:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;
                        case READLATER_READABILITY:
                            cell.detailTextLabel.text = @"Readability";
                            break;
                        case READLATER_POCKET:
                            cell.detailTextLabel.text = @"Pocket";
                            break;
                        default:
                            break;
                    }

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Mobilizer", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                    switch ([[[AppDelegate sharedDelegate] mobilizer] integerValue]) {
                        case MOBILIZER_GOOGLE:
                            cell.detailTextLabel.text = @"Google";
                            break;
                        case MOBILIZER_READABILITY:
                            cell.detailTextLabel.text = @"Readability";
                            break;
                        case MOBILIZER_INSTAPAPER:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;
                        default:
                            break;
                    }
                    break;


                case 4:
                    cell.textLabel.text = NSLocalizedString(@"Advanced Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    break;

                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Browser Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    break;

                default:
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Feedback & Support", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Purge Cache", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Log Out", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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
    switch (section) {
        case 1:
            return NSLocalizedString(@"Logging out of the application will reset the bookmark database on this device.", nil);
            break;
            
        default:
            break;
    }
    return @"";
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
                [self.modalDelegate closeModal:self success:^{
                    [(UIViewController *)self.modalDelegate presentViewController:delegate.loginViewController
                                                                         animated:YES
                                                   completion:nil];
                        
                    [[AppDelegate sharedDelegate] migrateDatabase];
                }];

            }
            else {
                [self presentViewController:delegate.loginViewController
                                   animated:YES
                                 completion:nil];
                
                [[AppDelegate sharedDelegate] migrateDatabase];
            }
        }
    }
    else if (alertView == self.instapaperAlertView) {
        // Check for cancel
        if (buttonIndex == 0)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.instapaperVerificationAlertView show];

            if (self.instapaperVerificationAlertView != nil) {
                self.loadingIndicator.center = CGPointMake(self.instapaperVerificationAlertView.bounds.size.width/2, self.instapaperVerificationAlertView.bounds.size.height-45);
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
                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                   message:@"We couldn't log you into Instapaper with those credentials."
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"Shucks", nil), nil] show];
                                   }
                                   else {
                                       OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[NSString stringWithUTF8String:[data bytes]]];
                                       KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
                                       [keychain setObject:token.key forKey:(__bridge id)kSecAttrAccount];
                                       [keychain setObject:token.secret forKey:(__bridge id)kSecValueData];
                                       [[AppDelegate sharedDelegate] setReadlater:@(READLATER_INSTAPAPER)];
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
                                           [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
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
                self.loadingIndicator.center = CGPointMake(self.readabilityVerificationAlertView.bounds.size.width/2, self.readabilityVerificationAlertView.bounds.size.height-45);
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
                                       [[AppDelegate sharedDelegate] setReadlater:@(READLATER_READABILITY)];
                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Readability"];
                                       [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0) {
        if (actionSheet == (UIActionSheet *)self.supportActionSheet) {
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
        else if (actionSheet == (UIActionSheet *)self.mobilizerActionSheet) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

            if ([buttonTitle isEqualToString:@"Google"]) {
                [[AppDelegate sharedDelegate] setMobilizer:@(MOBILIZER_GOOGLE)];
            }
            else if ([buttonTitle isEqualToString:@"Instapaper"]) {
                [[AppDelegate sharedDelegate] setMobilizer:@(MOBILIZER_INSTAPAPER)];
            }
            else if ([buttonTitle isEqualToString:@"Readability"]) {
                [[AppDelegate sharedDelegate] setMobilizer:@(MOBILIZER_READABILITY)];
            }

            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        else if (actionSheet == (UIActionSheet *)self.readLaterActionSheet) {
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
                [[AppDelegate sharedDelegate] setReadlater:nil];
                [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"None"];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
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
    
    if (self.pocketVerificationAlertView != nil) {
        self.loadingIndicator.center = CGPointMake(self.pocketVerificationAlertView.bounds.size.width/2, self.pocketVerificationAlertView.bounds.size.height-45);
        [self.loadingIndicator startAnimating];
        [self.pocketVerificationAlertView addSubview:self.loadingIndicator];
    }
}

- (void)pocketFinishedLogin {
    [self.pocketVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
    [[AppDelegate sharedDelegate] setReadlater:@(READLATER_POCKET)];
    [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Pocket"];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            BOOL isIPad = [UIApplication isIPad];
            CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
            if (indexPath.row == 2) {
                if (isIPad) {
                    if (!self.actionSheet) {
                        [self.readLaterActionSheet showFromRect:rect inView:tableView animated:YES];
                        self.actionSheet = self.readLaterActionSheet;
                    }
                }
                else {
                    [self.readLaterActionSheet showInView:self.navigationController.view];
                }
            }
            else if (indexPath.row == 3) {
                if (isIPad) {
                    if (!self.actionSheet) {
                        [self.mobilizerActionSheet showFromRect:rect inView:tableView animated:YES];
                        self.actionSheet = self.mobilizerActionSheet;
                    }
                }
                else {
                    [self.mobilizerActionSheet showInView:self.navigationController.view];
                }
            }
            else if (indexPath.row == 4) {
                [self.navigationController pushViewController:[[PPDisplaySettingsViewController alloc] init] animated:YES];
            }
            else if (indexPath.row == 5) {
                [self.navigationController pushViewController:[[PPBrowserSettingsViewController alloc] init] animated:YES];
            }
            break;
        }

        case 1: {
            switch (indexPath.row) {
                case 0: {
                    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                    [UVStyleSheet setStyleSheet:[[ASStyleSheet alloc] init]];
                    [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
                    break;
                }
                    
                case 1: {
                    UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:@"Resetting Cache" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                    [loadingAlertView show];
                    
                    self.loadingIndicator.center = CGPointMake(loadingAlertView.bounds.size.width/2, loadingAlertView.bounds.size.height-45);
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
                    
                case 2:
                    [self.logOutAlertView show];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 4) {
            [self.navigationController pushViewController:[[PPDisplaySettingsViewController alloc] init] animated:YES];
        }
        else if (indexPath.row == 5) {
            [self.navigationController pushViewController:[[PPBrowserSettingsViewController alloc] init] animated:YES];
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

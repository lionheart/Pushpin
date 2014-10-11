//
//  SettingsViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import QuartzCore;

#import "PPAppDelegate.h"
#import "PPSettingsViewController.h"
#import "PPLoginViewController.h"
#import "ASStyleSheet.h"
#import "NSString+URLEncoding.h"
#import "PPBrowserSettingsViewController.h"
#import "PPDisplaySettingsViewController.h"
#import "PPAboutViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "PPMobilizerUtility.h"
#import "PPConstants.h"
#import "PPTwitter.h"
#import "PPSettings.h"
#import "PPReaderSettingsViewController.h"

#import <ASPinboard/ASPinboard.h>
#import <uservoice-iphone-sdk/UserVoice.h>
#import <uservoice-iphone-sdk/UVStyleSheet.h>
#import <FMDB/FMDatabase.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSDelicious/LHSDelicious.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPSettingsViewController ()

@end

@implementation PPSettingsViewController

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
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.logOutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"This will log you out and delete the local bookmark database from your device.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Log Out", nil), nil];

    self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Contact Support", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Request a feature", nil), NSLocalizedString(@"Report a bug", nil), @"Tweet us", NSLocalizedString(@"Email us", nil), nil];

    self.readLaterServices = [NSMutableArray array];
    [self.readLaterServices addObject:@[@(PPReadLaterInstapaper)]];
    [self.readLaterServices addObject:@[@(PPReadLaterReadability)]];
    [self.readLaterServices addObject:@[@(PPReadLaterPocket)]];

    self.instapaperAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Instapaper Login", nil) message:NSLocalizedString(@"Password may be blank.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Log In", nil), nil];
    self.instapaperAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[self.instapaperAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self.instapaperAlertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyNext];
    [[self.instapaperAlertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Email Address", nil)];
    [[self.instapaperAlertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeAlphabet];
    [[self.instapaperAlertView textFieldAtIndex:1] setReturnKeyType:UIReturnKeyGo];
    [[self.instapaperAlertView textFieldAtIndex:1] setDelegate:self];

    self.readabilityAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Readability Login", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Log In", nil), nil];
    self.readabilityAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[self.readabilityAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self.readabilityAlertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyNext];
    [[self.readabilityAlertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Email Address", nil)];
    [[self.readabilityAlertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeAlphabet];
    [[self.readabilityAlertView textFieldAtIndex:1] setReturnKeyType:UIReturnKeyGo];
    [[self.readabilityAlertView textFieldAtIndex:1] setDelegate:self];

    self.instapaperVerificationAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                      message:NSLocalizedString(@"Logging into Instapaper.", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:nil];
    self.readabilityVerificationAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                       message:NSLocalizedString(@"Logging into Readability.", nil)
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:nil];
    self.pocketVerificationAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                  message:NSLocalizedString(@"Logging into Pocket.", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:nil
                                                        otherButtonTitles:nil];
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketStartedLogin) name:(NSString *)PocketAPILoginStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketFinishedLogin) name:(NSString *)PocketAPILoginFinishedNotification object:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
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

    PPSettings *settings = [PPSettings sharedSettings];
    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReadLater:
                    cell.textLabel.text = NSLocalizedString(@"Read Later", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

                    PPReadLaterType readLater = settings.readLater;
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
                    
                case PPMainReader:
                    cell.textLabel.text = NSLocalizedString(@"Reader Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case PPMainAdvanced:
                    cell.textLabel.text = NSLocalizedString(@"Advanced Settings", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.isAccessibilityElement = YES;
                    cell.accessibilityLabel = NSLocalizedString(@"Advanced Settings", nil);
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
                    cell.textLabel.text = NSLocalizedString(@"Rate Pushpin on the App Store", nil);
                    break;
                    
                case PPOtherFollow:
                    cell.textLabel.text = [NSString stringWithFormat:@"Follow @%@ on Twitter", PPTwitterUsername];
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
            PPSettings *settings = [PPSettings sharedSettings];
            PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
            settings.lastUpdated = nil;
            [delegate logout];

#ifdef DELICIOUS
            [[LHSDelicious sharedInstance] resetAuthentication];
#endif

#ifdef PINBOARD
            [[ASPinboard sharedInstance] resetAuthentication];
#endif

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

            [PPUtilities migrateDatabase];
        }
    }
    else if (alertView == self.instapaperAlertView) {
        // Check for cancel
        if (buttonIndex == 0) {
            return;
        }

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
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1.1/oauth/access_token"]];

        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:nil realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[
             [OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
             [OARequestParameter requestParameter:@"x_auth_username" value:username],
             [OARequestParameter requestParameter:@"x_auth_password" value:password]]];
        [request prepare];

        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                                                      [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   [self.instapaperVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                   if (httpResponse.statusCode == 400 || error != nil) {
                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:NSLocalizedString(@"We couldn't log you into Instapaper with those credentials.", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                                   }
                                   else {
                                       PPSettings *settings = [PPSettings sharedSettings];
                                       OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                       settings.instapaperToken = token;
                                       settings.readLater = PPReadLaterInstapaper;

                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Instapaper"];

                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                                                       message:NSLocalizedString(@"You've successfully logged in.", nil)
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

        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;

                                   [self.readabilityVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                   if (!error) {
                                       OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[NSString stringWithUTF8String:[data bytes]]];
                                       KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
                                       [keychain setObject:token.key forKey:(__bridge id)kSecAttrAccount];
                                       [keychain setObject:token.secret forKey:(__bridge id)kSecValueData];

                                       PPSettings *settings = [PPSettings sharedSettings];
                                       settings.readLater = PPReadLaterReadability;
                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Readability"];
                                       [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                             withRowAnimation:UITableViewRowAnimationFade];

                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                                                       message:NSLocalizedString(@"You've successfully logged in.", nil)
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
                                                                   message:NSLocalizedString(@"We couldn't log you into Readability with those credentials.", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"Shucks", nil), nil] show];
                                   }
                               }];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    PPSettings *settings = [PPSettings sharedSettings];

    if (buttonIndex >= 0) {
        if (actionSheet == self.supportActionSheet) {
            if (buttonIndex == 3) {
                MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
                emailComposer.mailComposeDelegate = self;
                [emailComposer setSubject:NSLocalizedString(@"Support Email Subject", nil)];
                [emailComposer setToRecipients:@[@"support@lionheartsw.com"]];
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
        else if (actionSheet == self.readLaterActionSheet) {
            
            self.readLaterActionSheet = nil;
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
    PPSettings *settings = [PPSettings sharedSettings];
    settings.readLater = PPReadLaterPocket;
    [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Pocket"];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            BOOL isIPad = [UIApplication isIPad];
            UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
            CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
            
            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReadLater:
                    if (isIPad) {
                        if (!self.actionSheet) {
                            self.readLaterActionSheet.popoverPresentationController.sourceView = cell;
                            self.readLaterActionSheet.popoverPresentationController.sourceRect = (CGRect){cell.center, {1, 1}};
                            
                            [self presentViewController:self.readLaterActionSheet
                                               animated:YES
                                             completion:nil];

                            self.actionSheet = self.readLaterActionSheet;
                        }
                    }
                    else {
                        [self presentViewController:self.readLaterActionSheet
                                           animated:YES
                                         completion:nil];
                    }
                    break;

                case PPMainReader: {
                    PPReaderSettingsViewController *viewController = [[PPReaderSettingsViewController alloc] init];
                    [self.navigationController pushViewController:viewController animated:YES];
                    break;
                }
                    
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
#ifdef DELICIOUS
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=806918542&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
#endif
                    
#ifdef PINBOARD
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=548052590&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
#endif
                    break;
                    
                case PPOtherFollow: {
                    UIView *view = [tableView cellForRowAtIndexPath:indexPath];
                    CGPoint point = view.center;
                    [[PPTwitter sharedInstance] followScreenName:PPTwitterUsername point:point view:view callback:nil];
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
                    UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Resetting Cache", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                    [loadingAlertView show];
                    
                    self.loadingIndicator.center = CGPointMake(CGRectGetWidth(loadingAlertView.bounds)/2, CGRectGetHeight(loadingAlertView.bounds)-45);
                    [self.loadingIndicator startAnimating];
                    [loadingAlertView addSubview:self.loadingIndicator];
                    
                    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                        [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                    }];
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                        
                        UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Your cache was cleared.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
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

- (UIAlertController *)readLaterActionSheet {
    if (!_readLaterActionSheet) {
        _readLaterActionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];

        [_readLaterActionSheet addAction:[UIAlertAction actionWithTitle:@"Instapaper"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [self.instapaperAlertView show];
                                                                    self.actionSheet = nil;
                                                                }]];
        
        [_readLaterActionSheet addAction:[UIAlertAction actionWithTitle:@"Readability"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [self.readabilityAlertView show];
                                                                    self.actionSheet = nil;
                                                                }]];
        
        [_readLaterActionSheet addAction:[UIAlertAction actionWithTitle:@"Pocket"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [[PocketAPI sharedAPI] loginWithDelegate:nil];
                                                                    self.actionSheet = nil;
                                                                }]];
        
        // Only show the "Remove" option if the user already has a read later service chosen.
        PPSettings *settings = [PPSettings sharedSettings];
        BOOL readLaterServiceChosen = settings.readLater != PPReadLaterNone;
        if (readLaterServiceChosen) {
            [_readLaterActionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil)
                                                                      style:UIAlertActionStyleDestructive
                                                                    handler:^(UIAlertAction *action) {
                                                                        settings.readLater = PPReadLaterNone;
                                                                        [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"None"];
                                                                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                                                              withRowAnimation:UITableViewRowAnimationFade];
                                                                        self.actionSheet = nil;
                                                                    }]];
        }

        [_readLaterActionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                  style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction *action) {
                                                                    self.actionSheet = nil;
                                                                }]];
    }
    return _readLaterActionSheet;
}

@end

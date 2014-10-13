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
#import "UIAlertController+LHSAdditions.h"

#import <ASPinboard/ASPinboard.h>
#import <uservoice-iphone-sdk/UserVoice.h>
#import <uservoice-iphone-sdk/UVStyleSheet.h>
#import <FMDB/FMDatabase.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSDelicious/LHSDelicious.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <OnePasswordExtension.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPSettingsViewController ()

@property (nonatomic, retain) UIAlertController *instapaperVerificationAlertView;
@property (nonatomic, retain) UIAlertController *readabilityVerificationAlertView;
@property (nonatomic, strong) UIAlertController *pocketVerificationAlertView;

@property (nonatomic, retain) UIAlertController *instapaperAlertView;
@property (nonatomic, retain) UIAlertController *readabilityAlertView;
@property (nonatomic, retain) UIAlertController *logOutAlertView;

@property (nonatomic, strong) UIAlertController *instapaperLoginWith1PasswordAlertView;
@property (nonatomic, strong) UIAlertController *readabilityLoginWith1PasswordAlertView;

- (void)loginToInstapaperWithUsername:(NSString *)username password:(NSString *)password;
- (void)loginToReadabilityWithUsername:(NSString *)username password:(NSString *)password;

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

    self.logOutAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Are you sure?", nil)
                                                             message:NSLocalizedString(@"This will log you out and delete the local bookmark database from your device.", nil)];

    [self.logOutAlertView lhs_addActionWithTitle:NSLocalizedString(@"Log Out", nil)
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
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
                                         }];
    
    [self.logOutAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIAlertActionStyleCancel
                                         handler:nil];

    self.supportActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Contact Support", nil)];

    [self.supportActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Request a feature", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                                                                     andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                                                  andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                                                
                                                [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
                                            }];
    
    [self.supportActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Report a bug", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil];
    
    [self.supportActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Tweet us", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil];
    
    [self.supportActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Email us", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
                                                emailComposer.mailComposeDelegate = self;
                                                [emailComposer setSubject:NSLocalizedString(@"Support Email Subject", nil)];
                                                [emailComposer setToRecipients:@[@"support@lionheartsw.com"]];
                                                [self presentViewController:emailComposer animated:YES completion:nil];
                                            }];
    
    [self.supportActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIAlertActionStyleCancel
                                         handler:nil];

    self.readLaterServices = [NSMutableArray array];
    [self.readLaterServices addObject:@[@(PPReadLaterInstapaper)]];
    [self.readLaterServices addObject:@[@(PPReadLaterReadability)]];
    [self.readLaterServices addObject:@[@(PPReadLaterPocket)]];

    self.instapaperAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Instapaper Login", nil)
                                                                 message:NSLocalizedString(@"Password may be blank.", nil)];
    
    [self.instapaperAlertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.returnKeyType = UIReturnKeyNext;
        textField.placeholder = NSLocalizedString(@"Email Address", nil);
    }];

    __weak typeof (self) weakself = self;
    [self.instapaperAlertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeAlphabet;
        textField.returnKeyType = UIReturnKeyGo;
        textField.placeholder = NSLocalizedString(@"Password", nil);
        
        __strong typeof (self) strongself = weakself;
        textField.delegate = strongself;
    }];

    [self.instapaperAlertView lhs_addActionWithTitle:NSLocalizedString(@"Log In", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                                 NSString *username = [self.instapaperAlertView.textFields[0] text];
                                                 NSString *password = [self.instapaperAlertView.textFields[1] text];
                                                 [self loginToInstapaperWithUsername:username password:password];
                                             }];
    
    [self.instapaperAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                               style:UIAlertActionStyleCancel
                                             handler:nil];

    self.readabilityAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Readability Login", nil)
                                                                  message:nil];
    
    [self.readabilityAlertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.returnKeyType = UIReturnKeyNext;
        textField.placeholder = NSLocalizedString(@"Email Address", nil);
    }];
    
    [self.readabilityAlertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeAlphabet;
        textField.returnKeyType = UIReturnKeyGo;
        textField.placeholder = NSLocalizedString(@"Password", nil);
        
        __strong typeof (self) strongself = weakself;
        textField.delegate = strongself;
    }];
    
    [self.readabilityAlertView lhs_addActionWithTitle:NSLocalizedString(@"Log In", nil)
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  NSString *username = [self.readabilityAlertView.textFields[0] text];
                                                  NSString *password = [self.readabilityAlertView.textFields[1] text];
                                                  [self loginToReadabilityWithUsername:username password:password];
                                              }];
    
    [self.readabilityAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                style:UIAlertActionStyleCancel
                                              handler:nil];
    
    self.instapaperLoginWith1PasswordAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Use 1Password?", nil)
                                                                                   message:NSLocalizedString(@"Would you like to use your credentials from 1Password to login to Instapaper?", nil)];
    
    [self.instapaperLoginWith1PasswordAlertView lhs_addActionWithTitle:NSLocalizedString(@"Enter Manually", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   [self presentViewController:self.instapaperAlertView animated:YES completion:nil];
                                                               }];
    
    [self.instapaperLoginWith1PasswordAlertView lhs_addActionWithTitle:NSLocalizedString(@"Login with 1Password", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
                                                                   [[OnePasswordExtension sharedExtension] findLoginForURLString:@"instapaper.com"
                                                                                                               forViewController:self
                                                                                                                          sender:self.view
                                                                                                                      completion:^(NSDictionary *loginDict, NSError *error) {
                                                                                                                          if (!loginDict) {
                                                                                                                              if (error.code != AppExtensionErrorCodeCancelledByUser) {
                                                                                                                                  NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
                                                                                                                              }
                                                                                                                              return;
                                                                                                                          }
                                                                                                                          
                                                                                                                          NSString *username = loginDict[AppExtensionUsernameKey];
                                                                                                                          NSString *password = loginDict[AppExtensionPasswordKey];
                                                                                                                          [self loginToInstapaperWithUsername:username password:password];
                                                                                                                      }];
                                                               }];
    
    self.readabilityLoginWith1PasswordAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Use 1Password?", nil)
                                                                                    message:NSLocalizedString(@"Would you like to use your credentials from 1Password to login to Readability?", nil)];
    
    [self.readabilityLoginWith1PasswordAlertView lhs_addActionWithTitle:NSLocalizedString(@"Enter Manually", nil)
                                                                  style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction *action) {
                                                                    [self presentViewController:self.readabilityAlertView animated:YES completion:nil];
                                                                }];
    
    [self.readabilityLoginWith1PasswordAlertView lhs_addActionWithTitle:NSLocalizedString(@"Login with 1Password", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [[OnePasswordExtension sharedExtension] findLoginForURLString:@"readability.com"
                                                                                                                forViewController:self
                                                                                                                           sender:self.view
                                                                                                                       completion:^(NSDictionary *loginDict, NSError *error) {
                                                                                                                           if (!loginDict) {
                                                                                                                               if (error.code != AppExtensionErrorCodeCancelledByUser) {
                                                                                                                                   NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
                                                                                                                               }
                                                                                                                               return;
                                                                                                                           }

                                                                                                                           NSString *username = loginDict[AppExtensionUsernameKey];
                                                                                                                           NSString *password = loginDict[AppExtensionPasswordKey];
                                                                                                                           [self loginToReadabilityWithUsername:username password:password];
                                                                                                                       }];
                                                                }];

    self.instapaperVerificationAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                             message:NSLocalizedString(@"Logging into Instapaper.", nil)];
    
    self.readabilityVerificationAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                              message:NSLocalizedString(@"Logging into Readability.", nil)];
    
    self.pocketVerificationAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Verifying credentials", nil)
                                                                         message:NSLocalizedString(@"Logging into Pocket.", nil)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketStartedLogin) name:(NSString *)PocketAPILoginStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pocketFinishedLogin) name:(NSString *)PocketAPILoginFinishedNotification object:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.instapaperAlertView.textFields[1]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (textField == self.readabilityAlertView.textFields[1]) {
        [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)pocketStartedLogin {
    [self presentViewController:self.pocketVerificationAlertView animated:YES completion:nil];
}

- (void)pocketFinishedLogin {
    [self dismissViewControllerAnimated:YES completion:nil];

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
            
            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReadLater:
                    if (isIPad) {
                        if (!self.readLaterActionSheet.presentingViewController) {
                            self.readLaterActionSheet.popoverPresentationController.sourceRect = [self.view convertRect:[cell lhs_centerRect] fromView:cell];
                            self.readLaterActionSheet.popoverPresentationController.sourceView = self.view;
                            
                            [self presentViewController:self.readLaterActionSheet
                                               animated:YES
                                             completion:nil];
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
                    [self presentViewController:self.logOutAlertView animated:YES completion:nil];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;

                case PPOtherClearCache: {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Resetting Cache", nil) message:nil];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                        [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                    }];
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self dismissViewControllerAnimated:YES completion:nil];
                        
                        UIAlertController *successAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                                message:NSLocalizedString(@"Your cache was cleared.", nil)];
                        [self presentViewController:successAlertView animated:YES completion:nil];

                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [self dismissViewControllerAnimated:YES completion:nil];
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
        _readLaterActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
        
        [_readLaterActionSheet lhs_addActionWithTitle:@"Instapaper"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
                                                      [self presentViewController:self.instapaperLoginWith1PasswordAlertView animated:YES completion:nil];
                                                  }
                                                  else {
                                                      [self presentViewController:self.instapaperAlertView animated:YES completion:nil];
                                                  }
                                              }];
        
        [_readLaterActionSheet lhs_addActionWithTitle:@"Readability"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
                                                      [self presentViewController:self.readabilityLoginWith1PasswordAlertView animated:YES completion:nil];
                                                  }
                                                  else {
                                                      [self presentViewController:self.readabilityAlertView animated:YES completion:nil];
                                                  }
                                              }];
        
        [_readLaterActionSheet lhs_addActionWithTitle:@"Pocket"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  [[PocketAPI sharedAPI] loginWithDelegate:nil];
                                              }];
        
        // Only show the "Remove" option if the user already has a read later service chosen.
        PPSettings *settings = [PPSettings sharedSettings];
        BOOL readLaterServiceChosen = settings.readLater != PPReadLaterNone;
        if (readLaterServiceChosen) {
            [_readLaterActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Remove", nil)
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction *action) {
                                                      settings.readLater = PPReadLaterNone;
                                                      [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"None"];
                                                      [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                                            withRowAnimation:UITableViewRowAnimationFade];
                                                  }];
        }
        
        [_readLaterActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                style:UIAlertActionStyleCancel
                                              handler:nil];
    }
    return _readLaterActionSheet;
}

- (void)loginToInstapaperWithUsername:(NSString *)username password:(NSString *)password {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:self.instapaperVerificationAlertView animated:YES completion:nil];
    });

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
                               [self dismissViewControllerAnimated:YES completion:nil];
                               
                               if (httpResponse.statusCode == 400 || error != nil) {
                                   UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Error", nil)
                                                                                                message:NSLocalizedString(@"We couldn't log you into Instapaper with those credentials.", nil)];
                                   
                                   [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
                                   
                                   [self presentViewController:alert animated:YES completion:nil];
                               }
                               else {
                                   PPSettings *settings = [PPSettings sharedSettings];
                                   OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                   settings.instapaperToken = token;
                                   settings.readLater = PPReadLaterInstapaper;
                                   
                                   [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Instapaper"];
                                   
                                   UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                                message:NSLocalizedString(@"You've successfully logged in.", nil)];
                                   
                                   [self presentViewController:alert animated:YES completion:nil];
                                   
                                   int64_t delayInSeconds = 1.5;
                                   dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                   dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                       [self dismissViewControllerAnimated:YES completion:nil];
                                       [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                             withRowAnimation:UITableViewRowAnimationFade];
                                   });
                               }
                           }];
}

- (void)loginToReadabilityWithUsername:(NSString *)username password:(NSString *)password {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:self.readabilityVerificationAlertView animated:YES completion:nil];
    });

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
                               
                               [self dismissViewControllerAnimated:YES completion:nil];
                               if (error) {
                                   UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                                                message:NSLocalizedString(@"We couldn't log you into Readability with those credentials.", nil)];
                                   
                                   [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
                                   
                                   [self presentViewController:alert animated:YES completion:nil];
                               }
                               else {
                                   OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:[NSString stringWithUTF8String:[data bytes]]];
                                   KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
                                   [keychain setObject:token.key forKey:(__bridge id)kSecAttrAccount];
                                   [keychain setObject:token.secret forKey:(__bridge id)kSecValueData];
                                   
                                   PPSettings *settings = [PPSettings sharedSettings];
                                   settings.readLater = PPReadLaterReadability;
                                   [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Readability"];
                                   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPMainReadLater inSection:PPSectionMainSettings]]
                                                         withRowAnimation:UITableViewRowAnimationFade];
                                   
                                   UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                                message:NSLocalizedString(@"You've successfully logged in.", nil)];
                                   
                                   [self presentViewController:alert animated:YES completion:nil];
                                   
                                   int64_t delayInSeconds = 1.5;
                                   dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                   dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                       [self dismissViewControllerAnimated:YES completion:nil];
                                   });
                               }
                           }];
}

@end

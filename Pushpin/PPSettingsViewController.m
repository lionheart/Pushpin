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
#import "PPOfflineSettingsViewController.h"
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>

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
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>
#import <OnePasswordExtension.h>

static NSString *CellIdentifier = @"CellIdentifier";
static NSString *DeleteCellIdentifier = @"DeleteCellIdentifier";
static NSString *SubtitleCellIdentifier = @"SubtitleCellIdentifier";

@interface PPSettingsViewController ()

@property (nonatomic, retain) UIAlertController *logOutAlertView;
@property (nonatomic) NSInteger numberOfRatings;

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

    if (!self.numberOfRatings) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:@"https://itunes.apple.com/lookup?id=548052590"]
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                                                
                                                NSDictionary *app = object[@"results"][0];
                                                
                                                NSNumber *rating = app[@"userRatingCountForCurrentVersion"];
                                                if (rating) {
                                                    self.numberOfRatings = [app[@"userRatingCountForCurrentVersion"] integerValue];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self.tableView beginUpdates];
                                                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOtherRatePushpin inSection:1]]
                                                                              withRowAnimation:UITableViewRowAnimationNone];
                                                        [self.tableView endUpdates];
                                                    });
                                                }
                                                else {
                                                    self.numberOfRatings = 0;
                                                }
                                            }];
        [task resume];
    }
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DeleteCellIdentifier];
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
            return NSLocalizedString(@"Main Settings", nil);

        default:
            return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPSectionType)section) {
        case PPSectionMainSettings:
            return PPRowCountMain;

        case PPSectionOtherSettings:
            return PPRowCountOther;
            
        case PPSectionCacheSettings:
            return PPRowCountCache;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == PPOtherRatePushpin) {
        return 54;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if (indexPath.section == PPSectionCacheSettings) {
        cell = [tableView dequeueReusableCellWithIdentifier:DeleteCellIdentifier forIndexPath:indexPath];
    }
    else if (indexPath.section == 1 && indexPath.row == PPOtherRatePushpin) {
        cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier forIndexPath:indexPath];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    }

    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.textColor = [PPTheme detailLabelFontColor];
    cell.detailTextLabel.font = [PPTheme detailLabelFontAlternate1];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;

            switch ((PPMainSettingsRowType)indexPath.row) {
                case PPMainReader:
                    cell.imageView.image = [UIImage imageNamed:@"874-newspaper"];
                    cell.textLabel.text = NSLocalizedString(@"Reader View", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case PPMainAdvanced:
                    cell.imageView.image = [UIImage imageNamed:@"740-gear"];
                    cell.textLabel.text = NSLocalizedString(@"Advanced", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.isAccessibilityElement = YES;
                    cell.accessibilityLabel = NSLocalizedString(@"Advanced", nil);
                    break;

                case PPMainBrowser:
                    cell.imageView.image = [UIImage imageNamed:@"782-compass"];
                    cell.textLabel.text = NSLocalizedString(@"Browser", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case PPMainOffline:
                    cell.imageView.image = [UIImage imageNamed:@"731-cloud-download"];
                    cell.textLabel.text = NSLocalizedString(@"Offline", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
        }

        case PPSectionOtherSettings: {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;

            switch ((PPOtherSettingsRowType)indexPath.row) {
                case PPOtherRatePushpin:
                    cell.textLabel.text = NSLocalizedString(@"Rate Pushpin on the App Store", nil);

                    if (self.numberOfRatings == 0) {
                        cell.detailTextLabel.text = @"No ratings for this version.";
                    }
                    else if (self.numberOfRatings == 1) {
                        cell.detailTextLabel.text = @"Only 1 rating for this version.";
                    }
                    else if (self.numberOfRatings < 10) {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"Only %lu ratings for this version.", (unsigned long)self.numberOfRatings];
                    }
                    else {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu ratings for this version.", (unsigned long)self.numberOfRatings];
                    }
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

                default:
                    break;
            }

            break;
        }
            
        case PPSectionCacheSettings: {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.text = NSLocalizedString(@"Clear Cache", nil);
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
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

        case PPSectionCacheSettings:
            return NSLocalizedString(@"Clearing your cache removes all stored cookies and session information from the in-app browser.", nil);

        default:
            break;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch ((PPSectionType)indexPath.section) {
        case PPSectionMainSettings: {
            switch ((PPMainSettingsRowType)indexPath.row) {
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
                    
                case PPMainOffline:
                    [self.navigationController pushViewController:[[PPOfflineSettingsViewController alloc] init] animated:YES];
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
            }
            break;
        }
            
        case PPSectionCacheSettings: {
            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Resetting Cache", nil) message:nil];
            [self presentViewController:alert animated:YES completion:nil];
            
            NSHTTPCookie *cookie;
            NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            for (cookie in [storage cookies]) {
                [storage deleteCookie:cookie];
            }
            
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self dismissViewControllerAnimated:YES completion:nil];
                
                UIAlertController *successAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                        message:NSLocalizedString(@"Your cache was cleared.", nil)];
                [self presentViewController:successAlertView animated:YES completion:nil];
                
                double delayInSeconds = 2.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self dismissViewControllerAnimated:YES completion:nil];
                });
            });
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

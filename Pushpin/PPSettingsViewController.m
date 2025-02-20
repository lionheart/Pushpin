// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  SettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import QuartzCore;
@import LHSCategoryCollection;
@import FMDB;
@import ASPinboard;
@import KeychainItemWrapper;
@import LHSTableViewCells;

#if !TARGET_OS_MACCATALYST
#import "Pushpin-Swift.h"
#endif

#import "PPAppDelegate.h"
#import "PPSettingsViewController.h"
#import "PPPinboardLoginViewController.h"
#import "PPBrowserSettingsViewController.h"
#import "PPDisplaySettingsViewController.h"
#import "PPAboutViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPMobilizerUtility.h"
#import "PPConstants.h"
#import "PPSettings.h"
#import "PPReaderSettingsViewController.h"
#import "PPOfflineSettingsViewController.h"
#import "PPUtilities.h"

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

    self.navigationItem.title = NSLocalizedString(@"Settings", nil);

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

        [[ASPinboard sharedInstance] resetAuthentication];

        [delegate setLoginViewController:nil];
        [delegate setNavigationController:nil];
        delegate.loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

        [delegate.window setRootViewController:delegate.loginViewController];

        [PPUtilities migrateDatabase];
    }];

    [self.logOutAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIAlertActionStyleCancel
                                         handler:nil];

    if (!self.numberOfRatings) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:@"https://itunes.apple.com/lookup?id=548052590"]
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

            NSDictionary *app = [object[@"results"] firstObject];

            if (app) {
                NSNumber *rating = app[@"userRatingCountForCurrentVersion"];
                if (rating) {
                    self.numberOfRatings = [app[@"userRatingCountForCurrentVersion"] integerValue];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOtherRatePushpin inSection:1]]
                                              withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                    });
                } else {
                    self.numberOfRatings = 0;
                }
            }
        }];
        [task resume];
    }

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;

    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DeleteCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];;
        return NO;
    }
    return YES;
}

- (void)showAboutPage {
    PPAboutViewController *aboutViewController = [[PPAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutViewController animated:YES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if (indexPath.section == PPSectionCacheSettings) {
        cell = [tableView dequeueReusableCellWithIdentifier:DeleteCellIdentifier forIndexPath:indexPath];
    } else if (indexPath.section == 1 && (indexPath.row == PPOtherGitHub || indexPath.row == PPOtherRatePushpin || indexPath.row == PPOtherTipJar || indexPath.row == PPOtherFeedback)) {
        cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier forIndexPath:indexPath];
    } else {
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
                    cell.imageView.image = [UIImage imageNamed:@"News"];
                    cell.textLabel.text = NSLocalizedString(@"Reader View", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case PPMainAdvanced:
                    cell.imageView.image = [UIImage imageNamed:@"Gear"];
                    cell.textLabel.text = NSLocalizedString(@"Advanced Settings - Short", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.isAccessibilityElement = YES;
                    cell.accessibilityLabel = NSLocalizedString(@"Advanced Settings - Short", nil);
                    break;

                case PPMainBrowser:
                    cell.imageView.image = [UIImage imageNamed:@"Compass"];
                    cell.textLabel.text = NSLocalizedString(@"Browser", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case PPMainOffline:
                    cell.imageView.image = [UIImage imageNamed:@"Download"];
                    cell.textLabel.text = NSLocalizedString(@"Offline", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
        }

        case PPSectionOtherSettings: {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;

            switch ((PPOtherSettingsRowType)indexPath.row) {
                case PPOtherTipJar:
                    cell.textLabel.text = NSLocalizedString(@"Tip Jar", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Help support continued Pushpin development!", nil);
                    cell.detailTextLabel.numberOfLines = 0;
                    break;
                
              case PPOtherGitHub:
                cell.textLabel.text = @"View Source Code on GitHub";
                cell.detailTextLabel.text = @"The source code for Pushpin for Pinboard is made fully available under the GPLv3 license. Check it out on GitHub.";
                cell.detailTextLabel.numberOfLines = 0;
                break;

                case PPOtherRatePushpin:
                    cell.textLabel.text = NSLocalizedString(@"Rate Pushpin on the App Store", nil);

                    if (self.numberOfRatings == 0) {
                        cell.detailTextLabel.text = NSLocalizedString(@"No ratings for this version.", nil);
                    } else if (self.numberOfRatings == 1) {
                        cell.detailTextLabel.text = @"Only 1 rating for this version.";
                    } else if (self.numberOfRatings < 10) {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"Only %lu ratings for this version.", (unsigned long)self.numberOfRatings];
                    } else {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu ratings for this version.", (unsigned long)self.numberOfRatings];
                    }
                    break;

                case PPOtherFollow:
                    cell.textLabel.text = NSLocalizedString(@"Follow @Pushpin_app on Twitter", nil);
                    break;

                case PPOtherFeedback:
                    cell.textLabel.text = NSLocalizedString(@"Feedback & Support", nil);
                    cell.detailTextLabel.text = @"Email support@lionheartsw.com";
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
                case PPOtherGitHub:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/lionheart/pushpin"] options:@{} completionHandler:nil];;
                    break;

                case PPOtherRatePushpin:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/pushpin-for-pinboard/id548052590?mt=8&uo=4&at=1l3vbEC&action=write-review"] options:@{} completionHandler:nil];;
                    break;

                case PPOtherFollow: {
                    NSURL *url = [NSURL URLWithString:@"https://twitter.com/pushpin_app"];
                    NSMutableDictionary *options = [NSMutableDictionary dictionary];
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
                        options[UIApplicationOpenURLOptionUniversalLinksOnly] = @YES;
                    }
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    break;
                }

                case PPOtherFeedback: {
                    NSURL *url = [NSURL URLWithString:@"mailto:support@lionheartsw.com"];
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    break;
                }

                case PPOtherLogout:
                    [self presentViewController:self.logOutAlertView animated:YES completion:nil];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;

                case PPOtherTipJar: {
#if !TARGET_OS_MACCATALYST
                    UIViewController *controller = [PPTipJarViewControllerFactory controller];
                    [self.navigationController pushViewController:controller animated:YES];
                    break;
#endif
                }
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
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

@end


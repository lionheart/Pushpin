//
//  PPBrowserSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "PPBrowserSettingsViewController.h"
#import "BookmarkletInstallationViewController.h"
#import "AppDelegate.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "UITableViewCellValue1.h"
#import "PPTableViewTitleView.h"
#import "PPConstants.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";

@interface PPBrowserSettingsViewController ()

@end

@implementation PPBrowserSettingsViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Browser Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
    
    self.browserActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:nil];
    
    [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"Safari", nil)];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://"]]) {
        [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"iCab Mobile", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"Chrome", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ohttp://"]]) {
        [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"Opera", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dolphin://"]]) {
        [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"Dolphin", nil)];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cyber://"]]) {
        [self.browserActionSheet addButtonWithTitle:NSLocalizedString(@"Cyberspace", nil)];
    }
    
    [self.browserActionSheet addButtonWithTitle:@"Cancel"];
    self.browserActionSheet.cancelButtonIndex = self.browserActionSheet.numberOfButtons - 1;

    self.installChromeAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Install Chrome?", nil) message:NSLocalizedString(@"In order to open links with Google Chrome, you first have to install it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
    self.installiCabMobileAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Install iCab Mobile?", nil) message:NSLocalizedString(@"In order to open links with iCab Mobile, you first have to install it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Browser Bookmarklet", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.font = [PPTheme textLabelFont];

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Default Browser", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    
                    PPBrowserType browser = [AppDelegate sharedDelegate].browser;

                    switch (browser) {
                        case PPBrowserWebview:
                            cell.detailTextLabel.text = @"Webview";
                            break;

                        case PPBrowserSafari:
                            cell.detailTextLabel.text = @"Safari";
                            break;

                        case PPBrowserChrome:
                            cell.detailTextLabel.text = @"Chrome";
                            break;

                        case PPBrowseriCabMobile:
                            cell.detailTextLabel.text = @"iCab Mobile";
                            break;

                        case PPBrowserDolphin:
                            cell.detailTextLabel.text = @"Dolphin";
                            break;

                        case PPBrowserCyberspace:
                            cell.detailTextLabel.text = @"Cyberspace";
                            break;

                        case PPBrowserOpera:
                            cell.detailTextLabel.text = @"Opera";
                            break;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Open links in-app", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    CGSize size = cell.frame.size;
                    self.openLinksInAppSwitch = [[UISwitch alloc] init];
                    CGSize switchSize = self.openLinksInAppSwitch.frame.size;
                    self.openLinksInAppSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.openLinksInAppSwitch.on = [AppDelegate sharedDelegate].openLinksInApp;
                    [self.openLinksInAppSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.openLinksInAppSwitch;
                    break;
            }
            break;
        }
            
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Installation instructions", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if (!self.actionSheet) {
                CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
                [self.browserActionSheet showFromRect:rect inView:tableView animated:YES];
            }
        }
    }
    else {
        [self.navigationController pushViewController:[[BookmarkletInstallationViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self.navigationController pushViewController:[[BookmarkletInstallationViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.installChromeAlertView && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.com/app/chrome"]];
    }
    else if (alertView == self.installiCabMobileAlertView && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/icab-mobile-web-browser/id308111628"]];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0) {
        if (actionSheet == (UIActionSheet *)self.browserActionSheet) {
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            if ([title isEqualToString:@"Webview"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Webview"];
                delegate.browser = PPBrowserWebview;
            }
            else if ([title isEqualToString:@"Safari"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Safari"];
                delegate.browser = PPBrowserSafari;
            }
            else if ([title isEqualToString:@"Chrome"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Chrome"];
                delegate.browser = PPBrowserChrome;
            }
            else if ([title isEqualToString:@"iCab Mobile"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"iCab Mobile"];
                delegate.browser = PPBrowseriCabMobile;
            }
            else if ([title isEqualToString:@"Dolphin"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Dolphin"];
                delegate.browser = PPBrowserDolphin;
            }
            else if ([title isEqualToString:@"Cyberspace"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Cyberpsace"];
                delegate.browser = PPBrowserCyberspace;
            }
            else if ([title isEqualToString:@"Opera"]) {
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Opera"];
                delegate.browser = PPBrowserOpera;
            }
            
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else {
        self.actionSheet = nil;
    }
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setOpenLinksInApp:self.openLinksInAppSwitch.on];
}

@end

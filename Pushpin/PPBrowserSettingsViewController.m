//
//  PPBrowserSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

@import QuartzCore;
@import Mixpanel;
@import OpenInChrome;
@import LHSCategoryCollection;
@import LHSTableViewCells;

#import "PPBrowserSettingsViewController.h"
#import "BookmarkletInstallationViewController.h"
#import "PPAppDelegate.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "PPTableViewTitleView.h"
#import "PPConstants.h"
#import "PPSettings.h"

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
    
    self.browserActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    void (^BrowserAlertActionHandler)(UIAlertAction *action) = ^(UIAlertAction *action) {
        PPSettings *settings = [PPSettings sharedSettings];

        if ([action.title isEqualToString:NSLocalizedString(@"Webview", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Webview"];
            settings.browser = PPBrowserWebview;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"Safari", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Safari"];
            settings.browser = PPBrowserSafari;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"Chrome", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Chrome"];
            settings.browser = PPBrowserChrome;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"iCab Mobile", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"iCab Mobile"];
            settings.browser = PPBrowseriCabMobile;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"Dolphin", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Dolphin"];
            settings.browser = PPBrowserDolphin;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"Cyberspace", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Cyberpsace"];
            settings.browser = PPBrowserCyberspace;
        }
        else if ([action.title isEqualToString:NSLocalizedString(@"Opera", nil)]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Opera"];
            settings.browser = PPBrowserOpera;
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        self.actionSheet = nil;
    };
    
    [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Safari", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:BrowserAlertActionHandler];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://"]]) {
        [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"iCab Mobile", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:BrowserAlertActionHandler];
    }
    
    OpenInChromeController *openInChromeController = [OpenInChromeController sharedInstance];
    if ([openInChromeController isChromeInstalled]) {
        [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Chrome", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:BrowserAlertActionHandler];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ohttp://"]]) {
        [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Opera", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:BrowserAlertActionHandler];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dolphin://"]]) {
        [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Dolphin", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:BrowserAlertActionHandler];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cyber://"]]) {
        [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cyberspace", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:BrowserAlertActionHandler];
    }
    
    [self.browserActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
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
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Default Browser", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    
                    PPBrowserType browser = [PPSettings sharedSettings].browser;

                    switch (browser) {
                        case PPBrowserWebview:
                            cell.detailTextLabel.text = NSLocalizedString(@"Webview", nil);
                            break;

                        case PPBrowserSafari:
                            cell.detailTextLabel.text = NSLocalizedString(@"Safari", nil);
                            break;

                        case PPBrowserChrome:
                            cell.detailTextLabel.text = NSLocalizedString(@"Chrome", nil);
                            break;

                        case PPBrowseriCabMobile:
                            cell.detailTextLabel.text = NSLocalizedString(@"iCab Mobile", nil);
                            break;

                        case PPBrowserDolphin:
                            cell.detailTextLabel.text = NSLocalizedString(@"Dolphin", nil);
                            break;

                        case PPBrowserCyberspace:
                            cell.detailTextLabel.text = NSLocalizedString(@"Cyberspace", nil);
                            break;

                        case PPBrowserOpera:
                            cell.detailTextLabel.text = NSLocalizedString(@"Cyberspace", nil);
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
                    self.openLinksInAppSwitch.on = [PPSettings sharedSettings].openLinksInApp;
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
                UIView *cell = [tableView cellForRowAtIndexPath:indexPath];

                self.browserActionSheet.popoverPresentationController.sourceRect = [cell lhs_centerRect];
                self.browserActionSheet.popoverPresentationController.sourceView = cell;

                [self presentViewController:self.browserActionSheet animated:YES completion:^{
                    self.actionSheet = self.browserActionSheet;
                }];
            }
        }
    } else {
        [self.navigationController pushViewController:[[BookmarkletInstallationViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self.navigationController pushViewController:[[BookmarkletInstallationViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
    }
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[PPSettings sharedSettings] setOpenLinksInApp:self.openLinksInAppSwitch.on];
}

@end

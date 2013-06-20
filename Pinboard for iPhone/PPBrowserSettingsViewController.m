//
//  PPBrowserSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPBrowserSettingsViewController.h"
#import "BookmarkletInstallationViewController.h"
#import "AppDelegate.h"
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface PPBrowserSettingsViewController ()

@end

@implementation PPBrowserSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Browser Settings", nil);

        self.browserActionSheet = [[RDActionSheet alloc] initWithTitle:NSLocalizedString(@"Open links with:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

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
        
        self.installChromeAlertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Install Chrome?", nil) message:NSLocalizedString(@"In order to open links with Google Chrome, you first have to install it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
        self.installiCabMobileAlertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Install iCab Mobile?", nil) message:NSLocalizedString(@"In order to open links with iCab Mobile, you first have to install it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
    }
    return self;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
        
        float width = tableView.bounds.size.width;
        int fontSize = 17;
        int padding = isIPad ? 45 : 15;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 8, width - padding, fontSize)];
        NSString *sectionTitle = NSLocalizedString(@"Browser Bookmarklet", nil);
        label.text = sectionTitle;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = [UIFont fontWithName:[AppDelegate heavyFontName] size:fontSize];
        CGSize textSize = [sectionTitle sizeWithFont:label.font];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Default Browser", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
                        case BROWSER_WEBVIEW:
                            cell.detailTextLabel.text = @"Webview";
                            break;
                        case BROWSER_SAFARI:
                            cell.detailTextLabel.text = @"Safari";
                            break;
                        case BROWSER_CHROME:
                            cell.detailTextLabel.text = @"Chrome";
                            break;
                        case BROWSER_ICAB_MOBILE:
                            cell.detailTextLabel.text = @"iCab Mobile";
                            break;
                        case BROWSER_DOLPHIN:
                            cell.detailTextLabel.text = @"Dolphin";
                            break;
                        case BROWSER_CYBERSPACE:
                            cell.detailTextLabel.text = @"Cyberspace";
                            break;
                        case BROWSER_OPERA:
                            cell.detailTextLabel.text = @"Opera";
                            break;
                        default:
                            break;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Open links in-app", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    CGSize size = cell.frame.size;
                    self.openLinksInAppSwitch = [[PPSwitch alloc] init];
                    CGSize switchSize = self.openLinksInAppSwitch.frame.size;
                    self.openLinksInAppSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.openLinksInAppSwitch.on = [[AppDelegate sharedDelegate] openLinksInApp].boolValue;
                    [self.openLinksInAppSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.openLinksInAppSwitch;
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Installation instructions", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
            [self.browserActionSheet showFrom:self.navigationController.view];
        }
        else {
            
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

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.browserActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Webview"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Webview"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_WEBVIEW)];
        }
        else if ([title isEqualToString:@"Safari"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Safari"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_SAFARI)];
        }
        else if ([title isEqualToString:@"Chrome"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Chrome"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_CHROME)];
        }
        else if ([title isEqualToString:@"iCab Mobile"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"iCab Mobile"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_ICAB_MOBILE)];
        }
        else if ([title isEqualToString:@"Dolphin"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Dolphin"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_DOLPHIN)];
        }
        else if ([title isEqualToString:@"Cyberspace"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Cyberpsace"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_CYBERSPACE)];
        }
        else if ([title isEqualToString:@"Opera"]) {
            [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Opera"];
            [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_OPERA)];
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setOpenLinksInApp:@(self.openLinksInAppSwitch.on)];
}

@end

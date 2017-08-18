//
//  BookmarkletInstallationViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 1/21/13.
//
//

@import QuartzCore;
@import LHSCategoryCollection;

#import "PPAppDelegate.h"
#import "BookmarkletInstallationViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "PPTableViewTitleView.h"
#import "PPNotification.h"

static NSString *CellIdentifier = @"Cell";

@interface BookmarkletInstallationViewController ()

@end

@implementation BookmarkletInstallationViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Browser Integration", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Watch a video", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.font = [PPTheme textLabelFont];
    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Copy bookmarklet to clipboard", nil);
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"How to install on Safari", nil);
        } else {
            cell.textLabel.text = NSLocalizedString(@"How to install on Chrome for iOS", nil);
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [[UIPasteboard generalPasteboard] setString:@"javascript:window.location='pushpin://x-callback-url/add?url='+encodeURIComponent(location.href)+'&title='+encodeURIComponent(document.title)"];

        [PPNotification notifyWithMessage:NSLocalizedString(@"Bookmarklet copied to clipboard.", nil)
                                  success:YES
                                  updated:NO];
    } else {
        if (indexPath.row == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=svFHucdSjPI"]];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=y9hjzceX_FE"]];
        }
    }
}

@end

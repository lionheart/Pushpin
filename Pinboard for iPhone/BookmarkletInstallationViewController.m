//
//  BookmarkletInstallationViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 1/21/13.
//
//

#import "BookmarkletInstallationViewController.h"
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface BookmarkletInstallationViewController ()

@end

@implementation BookmarkletInstallationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Browser Integration", nil);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else {
        return 2;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        float width = tableView.bounds.size.width;

        int fontSize = 17;
        int padding = 15;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 8, width - padding, fontSize)];
        NSString *sectionTitle = NSLocalizedString(@"Watch a video", nil);
        label.text = sectionTitle;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];
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
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
        }
        
        if (indexPath.row == 0) {
            [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
        }
    }

    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];

    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Copy bookmarklet to clipboard", nil);
    }
    else {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"How to install on Safari", nil);
        }
        else {
            cell.textLabel.text = NSLocalizedString(@"How to install on Chrome for iOS", nil);
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [[UIPasteboard generalPasteboard] setString:@"javascript:window.location='pushpin://x-callback-url/add?url='+encodeURIComponent(location.href)+'&title='+encodeURIComponent(document.title)"];

        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = NSLocalizedString(@"Bookmarklet copied to clipboard.", nil);
        notification.alertAction = @"Open Pushpin";
        notification.userInfo = @{@"success": @YES, @"updated": @NO};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else {
        if (indexPath.row == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=svFHucdSjPI"]];
        }
        else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=y9hjzceX_FE"]];
        }
    }
}

@end

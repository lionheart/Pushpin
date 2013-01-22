//
//  BookmarkletInstallationViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 1/21/13.
//
//

#import "BookmarkletInstallationViewController.h"
#import "ZAActivityBar.h"

@interface BookmarkletInstallationViewController ()

@end

@implementation BookmarkletInstallationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Browser Integration";
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"";
    }
    else {
        return NSLocalizedString(@"Watch a video", nil);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return @"Note: Chrome bookmarklet installation instructions are not specific to Pushpin.";
    }
    else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    if (indexPath.section == 0) {
        cell.textLabel.text = @"Copy bookmarklet to clipboard";
    }
    else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"How to install on Safari";
        }
        else {
            cell.textLabel.text = @"How to install on Chrome for iOS";
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [[UIPasteboard generalPasteboard] setString:@"javascript:window.location='pushpin://x-callback-url/add?url='+encodeURIComponent(location.href)+'&title='+encodeURIComponent(document.title)"];
        [ZAActivityBar showSuccessWithStatus:NSLocalizedString(@"Bookmarklet copied to clipboard.", nil)];
    }
    else {
        if (indexPath.row == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=V-wgsEhSAh4"]];
        }
        else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=WgH-OqqpfFU"]];
        }
    }
}

@end

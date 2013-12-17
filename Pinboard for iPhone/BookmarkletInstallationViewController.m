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
#import "AppDelegate.h"
#import "UIApplication+Additions.h"
#import "PPTheme.h"

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
        BOOL isIPad = [UIApplication isIPad];

        NSUInteger fontSize = 17;
        NSUInteger padding = isIPad ? 45 : 15;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 8, width - padding, fontSize)];
        NSString *sectionTitle = NSLocalizedString(@"Watch a video", nil);
        label.text = sectionTitle;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = [UIFont fontWithName:[PPTheme boldFontName] size:fontSize];
        
        CGRect textRect = [sectionTitle boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: label.font} context:nil];
        CGSize textSize = textRect.size;
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

    cell.textLabel.font = [UIFont fontWithName:[PPTheme fontName] size:16];
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
            /*
            NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"safari-instructions" ofType:@"html"]];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];

            UIWebView *webView = [[UIWebView alloc] init];
            [webView loadRequest:request];
            webView.frame = CGRectMake(0, 0, 320, 460);
            UIViewController *controller = [[UIViewController alloc] init];
            controller.view = webView;

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
            [self presentViewController:navController animated:YES completion:nil];
             */
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=svFHucdSjPI"]];
        }
        else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=y9hjzceX_FE"]];
        }
    }
}

@end

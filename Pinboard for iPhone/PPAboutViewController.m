//
//  PPAboutViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <StoreKit/StoreKit.h>

#import "AppDelegate.h"
#import "PPAboutViewController.h"
#import "PPWebViewController.h"
#import "PPChangelogViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "UITableViewCellSubtitle.h"
#import "PPTableViewTitleView.h"

#import "UITableView+Additions.h"

#import <Mixpanel/Mixpanel.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPAboutViewController ()

@end

@implementation PPAboutViewController

- (id)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Pushpin 2.1.1", nil) imageName:nil];
    self.navigationItem.titleView = titleView;

    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"plist"];
    self.data = [NSArray arrayWithContentsOfFile:plistPath];
    self.expandedIndexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.heights = [NSMutableDictionary dictionary];
    self.titles = [NSMutableArray array];
    NSInteger index = 0;
    CGFloat width = CGRectGetWidth(self.tableView.frame) - 2 * self.tableView.groupedCellMargin - 40;
    CGFloat descriptionHeight;
    NSUInteger emptyLines;
    NSArray *lines;
    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);

    UITableViewCell *testCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
    NSDictionary *titleAttributes = @{NSFontAttributeName: testCell.textLabel.font};
    NSDictionary *detailAttributes = @{NSFontAttributeName: testCell.detailTextLabel.font};
    for (NSArray *list in self.data) {
        [self.titles addObject:NSLocalizedString(list[0], nil)];
        for (NSArray *pair in list[1]) {
            NSString *title = NSLocalizedString(pair[0], nil);
            NSString *description = NSLocalizedString(pair[1], nil);

            if ([title isEqualToString:@""]) {
                self.heights[title] = @(0);
            }
            else {
                self.heights[title] = @(MIN(22, [title boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:titleAttributes context:nil].size.height));
            }

            if ([description isEqualToString:@""]) {
                descriptionHeight = 0;
            }
            else {
                emptyLines = 0;
                lines = [description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                for (NSString *line in lines) {
                    if ([line isEqualToString:@""]) {
                        emptyLines++;
                    }
                }

                if (index == 4) {
                    descriptionHeight = [description boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:detailAttributes context:nil].size.height;
                }
                else {
                    descriptionHeight = [description boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:detailAttributes context:nil].size.height;
                }
            }

            self.heights[description] = @(descriptionHeight);
        }
        index++;
    }

    self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [[Mixpanel sharedInstance] track:@"Opened about page"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section][1] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [PPTableViewTitleView heightWithText:self.titles[section]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [PPTableViewTitleView headerWithText:self.titles[section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat topHeight = [self.heights[self.data[indexPath.section][1][indexPath.row][0]] floatValue];
    CGFloat bottomHeight = [self.heights[self.data[indexPath.section][1][indexPath.row][1]] floatValue];
    if (bottomHeight > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        bottomHeight = 22;
    }

    return topHeight + bottomHeight + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.accessoryView = nil;

    if (indexPath.section == [self.titles indexOfObject:@"Attributions"]) {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    }

    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (indexPath.section == 0 && indexPath.row == 2) {
        cell.imageView.image = [UIImage imageNamed:@"twitter"];
    }
    else if (indexPath.section == 0 && indexPath.row == 3) {
        cell.imageView.image = [UIImage imageNamed:@"apple"];
    }
    
    NSArray *info = self.data[indexPath.section][1];
    NSString *title = info[indexPath.row][0];
    NSString *detail = info[indexPath.row][1];
    
    if ([info[indexPath.row] count] > 3) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (![title isEqualToString:@""]) {
        cell.textLabel.text = title;
    }
    if ([self.heights[detail] floatValue] > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        cell.detailTextLabel.font = [PPTheme cellDetailLabelFont];
        if (indexPath.section == [self.titles indexOfObject:NSLocalizedString(@"Attributions", nil)]) {
            cell.detailTextLabel.text = NSLocalizedString(@"Tap to view license.", nil);
        }
        else {
            cell.detailTextLabel.text = NSLocalizedString(@"Tap to expand.", nil);
        }
    }
    else {
        if (![detail isEqualToString:@""]) {
            cell.detailTextLabel.text = detail;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0 && indexPath.row == 1) {
        PPChangelogViewController *changelogViewController = [[PPChangelogViewController alloc] init];
        [self.navigationController pushViewController:changelogViewController animated:YES];
    }
    else if (indexPath.section == 0 && indexPath.row == 2) {
        [self followScreenName:@"pushpin_app"];
    }
    else if (indexPath.section == 0 && indexPath.row == 3) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=548052590&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
    }
    else if ([self.data[indexPath.section][1][indexPath.row] count] > 3) {
        NSURL *url = [NSURL URLWithString:self.data[indexPath.section][1][indexPath.row][3]];
        [[UIApplication sharedApplication] openURL:url];
    }
    else {
        if ([self.expandedIndexPaths containsObject:indexPath]) {
            [self.expandedIndexPaths removeObject:indexPath];
        }
        else {
            [self.expandedIndexPaths addObject:indexPath];
        }

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)followScreenName:(NSString *)screenName withAccountScreenName:(NSString *)accountScreenName {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSString *identifier;
    for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
        if ([account.username isEqualToString:accountScreenName]) {
            identifier = account.identifier;
            break;
        }
    }
    
    if (identifier) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ACAccount *account = [accountStore accountWithIdentifier:identifier];
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"]
                                                       parameters:@{@"screen_name": screenName, @"follow": @"true"}];
            [request setAccount:account];

            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];

                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (response[@"errors"]) {
                        NSString *code = [NSString stringWithFormat:@"Error #%@", response[@"errors"][0][@"code"]];
                        NSString *message = [NSString stringWithFormat:@"%@", response[@"errors"][0][@"message"]];
                        [[[UIAlertView alloc] initWithTitle:code message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Uh oh.", nil) otherButtonTitles:nil] show];
                    }
                    else {
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:[NSString stringWithFormat:@"You are now following @%@!", screenName] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                    }
                });

                self.actionSheet = nil;
                self.selectedItem = nil;
                self.selectedPoint = CGPointZero;
                self.selectedIndexPath = nil;
            }];
        });
    }
}

- (void)followScreenName:(NSString *)screenName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        void (^AccessGrantedBlock)(UIAlertView *) = ^(UIAlertView *loadingAlertView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Twitter Account:", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                
                NSMutableDictionary *accounts = [NSMutableDictionary dictionary];
                NSString *accountScreenName;
                for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
                    accountScreenName = account.username;
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:accountScreenName];
                    [accounts setObject:account.identifier forKey:accountScreenName];
                }
                
                if (loadingAlertView) {
                    [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                }

                // Properly set the cancel button index
                [self.actionSheet addButtonWithTitle:@"Cancel"];
                self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;

                if ([accounts count] > 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.actionSheet respondsToSelector:@selector(showFromRect:inView:animated:)]) {
                            [(UIActionSheet *)self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.view animated:NO];
                        }
                    });
                }
                else if ([accounts count] == 1) {
                    [self followScreenName:screenName withAccountScreenName:accountScreenName];
                }
            });
        };
        
        if (twitter.accessGranted) {
            AccessGrantedBlock(nil);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:@"Loading" message:@"Requesting access to your Twitter accounts." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [loadingAlertView show];

                self.loadingIndicator.center = CGPointMake(CGRectGetWidth(loadingAlertView.bounds)/2, CGRectGetHeight(loadingAlertView.bounds)-45);
                [self.loadingIndicator startAnimating];
                [loadingAlertView addSubview:self.loadingIndicator];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [accountStore requestAccessToAccountsWithType:twitter
                                                          options:nil
                                                       completion:^(BOOL granted, NSError *error) {
                                                           if (granted) {
                                                               AccessGrantedBlock(loadingAlertView);
                                                           }
                                                           else {
                                                               [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                                               [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:@"There was an error connecting to Twitter." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                                           }
                                                       }];
                });
            });
        }
    });
}

- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer && recognizer.state == UIGestureRecognizerStateBegan) {
        if (!self.actionSheet) {
            self.selectedPoint = [recognizer locationInView:self.tableView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:self.selectedPoint];
            self.selectedItem = self.data[indexPath.section][1][indexPath.row];

            if (indexPath.section == [self.titles indexOfObject:@"Attributions"] || indexPath.section == [self.titles indexOfObject:@"Acknowledgements"] || indexPath.section == [self.titles indexOfObject:@"Team"]) {

                self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

                if (indexPath.section == [self.titles indexOfObject:@"Attributions"]) {
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:@"Copy Project URL"];
                }
                else if (indexPath.section == [self.titles indexOfObject:@"Acknowledgements"] || indexPath.section == [self.titles indexOfObject:@"Team"]) {
                    NSString *screenName = self.selectedItem[2];
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:[NSString stringWithFormat:@"Follow @%@ on Twitter", screenName]];
                }

                // Properly set the cancel button index
                [self.actionSheet addButtonWithTitle:@"Cancel"];
                self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;

                [(UIActionSheet *)self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.view animated:YES];
            }
        }
        else {
            if ([self.actionSheet respondsToSelector:@selector(dismissWithClickedButtonIndex:animated:)]) {
                [(UIActionSheet *)self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
                self.actionSheet = nil;
            }
        }
    }
}

#pragma mark Action Sheet Delegate

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.actionSheet && buttonIndex >= 0) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Copy Project URL"]) {
            [[UIPasteboard generalPasteboard] setString:self.selectedItem[2]];
        }
        else if ([buttonTitle hasPrefix:@"Follow"]) {
            [self followScreenName:self.selectedItem[2]];
        }
        else if ([[(UIActionSheet *)actionSheet title] isEqualToString:NSLocalizedString(@"Select Twitter Account:", nil)]) {
            [self followScreenName:self.selectedItem[2] withAccountScreenName:buttonTitle];
        }
    }
    self.actionSheet = nil;
}

@end

//
//  PPAboutViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "AppDelegate.h"
#import "PPAboutViewController.h"
#import "PPGroupedTableViewCell.h"
#import "WCAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "RDActionSheet.h"
#import <StoreKit/StoreKit.h>
#import "RDActionSheet.h"
#import "PPWebViewController.h"
#import "PPChangelogViewController.h"

@interface PPAboutViewController ()

@end

@implementation PPAboutViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"plist"];
        self.data = [NSArray arrayWithContentsOfFile:plistPath];

        self.expandedIndexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
        
        self.heights = [NSMutableDictionary dictionary];
        self.titles = [NSMutableArray array];
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        UIFont *fixedWidthFont = [UIFont fontWithName:@"Courier" size:12];
        NSInteger index = 0;
        for (NSArray *list in self.data) {
            [self.titles addObject:list[0]];
            for (NSArray *pair in list[1]) {
                NSString *title = pair[0];
                NSString *description = pair[1];

                if ([title isEqualToString:@""]) {
                    self.heights[title] = @(0);
                }
                else {
                    self.heights[title] = @(MIN(22, [title sizeWithFont:font constrainedToSize:CGSizeMake(SCREEN.bounds.size.width - 40, CGFLOAT_MAX)].height));
                }

                if ([description isEqualToString:@""]) {
                    self.heights[description] = @(0);
                }
                else {
                    if (index == 4) {
                        self.heights[description] = @([description sizeWithFont:fixedWidthFont constrainedToSize:CGSizeMake(SCREEN.bounds.size.width - 40, CGFLOAT_MAX)].height);
                    }
                    else {
                        self.heights[description] = @([description sizeWithFont:font constrainedToSize:CGSizeMake(SCREEN.bounds.size.width - 40, CGFLOAT_MAX)].height);
                    }
                }
            }
            index++;
        }
        
        self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section][1] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = self.titles[section];
    if (![title isEqualToString:@""]) {
        float width = tableView.bounds.size.width;
        BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
        NSUInteger fontSize = 17;
        NSUInteger padding = isIPad ? 45 : 15;
        UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 16, width - padding, fontSize)];
        label.text = title;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = font;
        CGSize textSize = [title sizeWithFont:label.font];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = self.titles[section];
    if (![title isEqual:@""]) {
        UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        return [self.titles[section] sizeWithFont:font constrainedToSize:CGSizeMake(SCREEN.bounds.size.width - 20, CGFLOAT_MAX)].height + 20;
    }
    return 0;
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
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ChoiceCellIdentifier];
    }
    
    cell.accessoryView = nil;
    
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];

    if (indexPath.section == [self.titles indexOfObject:@"Attributions"]) {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    }
    else {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    }
    cell.detailTextLabel.numberOfLines = 0;
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
    
    CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackgroundForHeight:height];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayerForHeight:height]];
    }

    if (indexPath.row < info.count - 1) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayerForHeight:height]];
    }
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer forHeight:height];

    if ([info[indexPath.row] count] > 3) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (![title isEqualToString:@""]) {
        cell.textLabel.text = title;
    }
    if ([self.heights[detail] floatValue] > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        if (indexPath.section == [self.titles indexOfObject:@"Attributions"]) {
            cell.detailTextLabel.text = @"Tap to view license.";
        }
        else {
            cell.detailTextLabel.text = @"Tap to expand.";
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
        PPWebViewController *webViewController = [PPWebViewController webViewControllerWithURL:self.data[indexPath.section][1][indexPath.row][3]];
        [self.navigationController pushViewController:webViewController animated:YES];
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

- (void)followScreenName:(NSString *)screenName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        void (^AccessGrantedBlock)(WCAlertView *) = ^(WCAlertView *loadingAlertView) {
            self.twitterAccountActionSheet = [[RDActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Twitter Account:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

            NSMutableDictionary *accounts = [NSMutableDictionary dictionary];
            for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
                [self.twitterAccountActionSheet addButtonWithTitle:account.username];
                [accounts setObject:account.identifier forKey:account.username];
            }

            if (loadingAlertView) {
                [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
            }

            void (^Tweet)(NSString *) = ^(NSString *username) {
                ACAccount *account = [accountStore accountWithIdentifier:accounts[username]];
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                        requestMethod:SLRequestMethodPOST
                                                                  URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"]
                                                           parameters:@{@"screen_name": screenName, @"follow": @"true"}];
                [request setAccount:account];
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
                    if (response[@"errors"]) {
                        NSString *code = [NSString stringWithFormat:@"Error #%@", response[@"errors"][0][@"code"]];
                        NSString *message = [NSString stringWithFormat:@"%@", response[@"errors"][0][@"message"]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            WCAlertView *alertView = [[WCAlertView alloc] initWithTitle:code message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Uh oh.", nil) otherButtonTitles:nil];
                            [alertView show];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            WCAlertView *alertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:[NSString stringWithFormat:@"You are now following @%@!", screenName] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                            [alertView show];
                        });
                    }
                }];
            };

            if ([accounts count] == 0) {
            }
            else if ([accounts count] == 1) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];

                ACAccount *account = [accountStore accountsWithAccountType:twitter][0];
                Tweet(account.username);
            }
            else {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];

                self.twitterAccountActionSheet.callbackBlock = ^(RDActionSheetCallbackType result, NSInteger buttonIndex, NSString *buttonTitle) {
                    if (result == RDActionSheetCallbackTypeClickedButtonAtIndex && ![buttonTitle isEqualToString:@"Cancel"]) {
                        Tweet(buttonTitle);
                    }
                };

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.twitterAccountActionSheet showFrom:self.navigationController.view];
                });
            }
        };
        
        if (!twitter.accessGranted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WCAlertView *loadingAlertView = [[WCAlertView alloc] initWithTitle:@"Loading" message:@"Requesting access to your Twitter accounts." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [loadingAlertView show];

                self.loadingIndicator.center = CGPointMake(loadingAlertView.bounds.size.width/2, loadingAlertView.bounds.size.height-45);
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
                                                           }
                                                       }];
                });
            });
        }
        else {
            AccessGrantedBlock(nil);
        }
    });
}

- (void)followUserOnTwitter:(id)sender {
    NSString *screenName = self.data[self.selectedIndexPath.section][1][self.selectedIndexPath.row][2];
    if (![screenName isEqualToString:@""]) {
        [self followScreenName:screenName];
    }
}

- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer && recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint pressPoint = [recognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pressPoint];
        NSArray *info = self.data[indexPath.section][1][indexPath.row];
        
        if (indexPath.section == [self.titles indexOfObject:@"Attributions"] || indexPath.section == [self.titles indexOfObject:@"Acknowledgements"] || indexPath.section == [self.titles indexOfObject:@"Team"]) {
            RDActionSheet *sheet = [[RDActionSheet alloc] initWithTitle:info[0] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            if (indexPath.section == [self.titles indexOfObject:@"Attributions"]) {
                [sheet addButtonWithTitle:@"Copy Project URL"];
                sheet.callbackBlock = ^(RDActionSheetCallbackType result, NSInteger buttonIndex, NSString *buttonTitle) {
                    if (result == RDActionSheetCallbackTypeClickedButtonAtIndex && ![buttonTitle isEqualToString:@"Cancel"]) {
                        [[UIPasteboard generalPasteboard] setString:info[2]];
                    }
                };
            }
            else if (indexPath.section == [self.titles indexOfObject:@"Acknowledgements"] || indexPath.section == [self.titles indexOfObject:@"Team"]) {
                NSString *screenName = info[2];
                [sheet addButtonWithTitle:[NSString stringWithFormat:@"Follow @%@ on Twitter", screenName]];
                sheet.callbackBlock = ^(RDActionSheetCallbackType result, NSInteger buttonIndex, NSString *buttonTitle) {
                    if (result == RDActionSheetCallbackTypeClickedButtonAtIndex && ![buttonTitle isEqualToString:@"Cancel"]) {
                        [self followScreenName:screenName];
                    }
                };
            }

            [sheet showFrom:self.navigationController.view];
        }
    }
}

@end

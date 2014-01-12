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
#import "PPTheme.h"
#import "PPLicenseViewController.h"

#import "UITableView+Additions.h"

#import <Mixpanel/Mixpanel.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPAboutViewController ()

@property (nonatomic, strong) NSDictionary *titleAttributes;
@property (nonatomic, strong) NSDictionary *detailAttributes;

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
    [titleView setTitle:@"Pushpin 3.0" imageName:nil];
    self.navigationItem.titleView = titleView;

    NSString* aboutPlist = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"plist"];
    self.sections = [NSArray arrayWithContentsOfFile:aboutPlist];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.heights = [NSMutableArray array];

    self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGSize maxSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 20, CGFLOAT_MAX);
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    self.titleAttributes = @{NSFontAttributeName: [PPTheme textLabelFont],
                             NSParagraphStyleAttributeName: paragraphStyle };
    self.detailAttributes = @{NSFontAttributeName: [PPTheme detailLabelFontAlternate1],
                              NSParagraphStyleAttributeName: paragraphStyle,
                              NSForegroundColorAttributeName: [PPTheme detailLabelFontColor]};
    
    [self.sections enumerateObjectsUsingBlock:^(NSDictionary *sectionData, NSUInteger section, BOOL *stop) {
        NSArray *rows = sectionData[@"rows"];
        
        self.heights[section] = [NSMutableArray array];
        
        [rows enumerateObjectsUsingBlock:^(NSDictionary *rowData, NSUInteger row, BOOL *stop) {
            CGFloat height = 0;
            
            NSString *title = rowData[@"title"];
            NSString *detail = rowData[@"detail"];
            
            if (title) {
                height += CGRectGetHeight([title boundingRectWithSize:maxSize
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:self.titleAttributes
                                                              context:nil]);
            }
            
            if (detail) {
                height += CGRectGetHeight([detail boundingRectWithSize:maxSize
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:self.detailAttributes
                                                               context:nil]);
            }
            
            self.heights[section][row] = @(height);
        }];
    }];

    [[Mixpanel sharedInstance] track:@"Opened about page"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"title"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.heights[indexPath.section][indexPath.row] floatValue] + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;

    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.clipsToBounds = YES;
    cell.accessoryType = UITableViewCellAccessoryNone;;

    NSDictionary *info = self.sections[indexPath.section][@"rows"][indexPath.row];
    NSString *title = info[@"title"];
    NSString *detail = info[@"detail"];

    if (title) {
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:self.titleAttributes];
    }
    
    if (detail) {
        cell.detailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:detail attributes:self.detailAttributes];
    }
    
    if (info[@"license"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.section == 0 && indexPath.row == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    break;
                    
                case 1: {
                    PPChangelogViewController *changelogViewController = [[PPChangelogViewController alloc] init];
                    [self.navigationController pushViewController:changelogViewController animated:YES];
                    break;
                }
                    
                case 2:
                    [self followScreenName:@"pushpin_app"];
                    break;

                default:
                    break;
            }
            break;
            
        case 4: {
            NSDictionary *row = self.sections[indexPath.section][@"rows"][indexPath.row];
            
            NSString *license = row[@"license"];
            if (license) {
                PPLicenseViewController *licenseViewController = [PPLicenseViewController licenseViewControllerWithLicense:license];
                licenseViewController.title = row[@"title"];
                [self.navigationController pushViewController:licenseViewController animated:YES];
            }
            break;
        }
            
        default:
            break;
    }

//    else if (indexPath.section == 0 && indexPath.row == 3) {
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=548052590&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
//    }
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
            self.selectedItem = self.sections[indexPath.section][@"rows"][indexPath.row];
            
            NSString *title = self.sections[indexPath.section][@"title"];
            if ([@[@"Acknowledgements", @"Team"] containsObject:title] && self.selectedItem[@"username"]) {
                self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

                NSString *screenName = self.selectedItem[@"username"];
                [self.actionSheet addButtonWithTitle:[NSString stringWithFormat:@"Follow @%@ on Twitter", screenName]];

                // Properly set the cancel button index
                [self.actionSheet addButtonWithTitle:@"Cancel"];
                self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
                
                [(UIActionSheet *)self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.view animated:YES];
            }
        }
        else {
            if ([self.actionSheet respondsToSelector:@selector(dismissWithClickedButtonIndex:animated:)]) {
                [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
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

        if ([buttonTitle hasPrefix:@"Follow"]) {
            [self followScreenName:self.selectedItem[@"username"]];
        }
        else if ([[(UIActionSheet *)actionSheet title] isEqualToString:NSLocalizedString(@"Select Twitter Account:", nil)]) {
            [self followScreenName:self.selectedItem[@"username"] withAccountScreenName:buttonTitle];
        }
    }
    self.actionSheet = nil;
}

@end

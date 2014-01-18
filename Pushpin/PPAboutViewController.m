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
#import "PPTwitter.h"

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
                    
                case 2: {
                    [[PPTwitter sharedInstance] followScreenName:@"pushpin_app"
                                                           point:self.selectedPoint
                                                            view:self.view
                                                        callback:^{
                                                            self.selectedItem = nil;
                                                            self.selectedPoint = CGPointZero;
                                                            self.selectedIndexPath = nil;
                                                        }];
                    break;
                }

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
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
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

                [self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.view animated:YES];
            }
        }
        else {
            [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
            self.actionSheet = nil;
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
            [[PPTwitter sharedInstance] followScreenName:self.selectedItem[@"username"]
                                                   point:self.selectedPoint
                                                    view:self.view
                                                callback:^{
                                                    self.selectedItem = nil;
                                                    self.selectedPoint = CGPointZero;
                                                    self.selectedIndexPath = nil;
                                                }];
        }
    }
    self.actionSheet = nil;
}

@end

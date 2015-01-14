//
//  PPAboutViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

@import QuartzCore;
@import Accounts;
@import Social;
@import StoreKit;

#import "PPAboutViewController.h"
#import "PPChangelogViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "PPPlainTextViewController.h"
#import "PPTwitter.h"

#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>
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

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef DELICIOUS
    NSString *title = @"Pushpin for Delicious";
    NSString* aboutPlist = [[NSBundle mainBundle] pathForResource:@"About-Delicious" ofType:@"plist"];
#endif
    
#ifdef PINBOARD
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *title = [NSString stringWithFormat:@"Pushpin %@ (%@)", info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]];
    NSString* aboutPlist = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"plist"];
#endif

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:title imageName:nil];
    self.navigationItem.titleView = titleView;

    self.sections = [NSArray arrayWithContentsOfFile:aboutPlist];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.heights = [NSMutableArray array];

    self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGSize maxSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 30, CGFLOAT_MAX);
    CGRect maxRect = (CGRect){{0, 0}, maxSize};
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    self.titleAttributes = @{NSFontAttributeName: [PPTheme textLabelFont],
                             NSParagraphStyleAttributeName: paragraphStyle };
    self.detailAttributes = @{NSFontAttributeName: [PPTheme detailLabelFontAlternate1],
                              NSParagraphStyleAttributeName: paragraphStyle,
                              NSForegroundColorAttributeName: [PPTheme detailLabelFontColor]};
    UILabel *fakeLabel = [[UILabel alloc] init];
    fakeLabel.preferredMaxLayoutWidth = maxSize.width;

    __block NSMutableArray *heights = [NSMutableArray array];

    [self.sections enumerateObjectsUsingBlock:^(NSDictionary *sectionData, NSUInteger section, BOOL *stop) {
        NSArray *rows = sectionData[@"rows"];
        
        heights[section] = [NSMutableArray array];
        
        [rows enumerateObjectsUsingBlock:^(NSDictionary *rowData, NSUInteger row, BOOL *stop) {
            CGFloat height = 0;
            
            NSString *title = rowData[@"title"];
            NSString *detail = rowData[@"detail"];
            
            if (title) {
                fakeLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:self.titleAttributes];
                height += CGRectGetHeight([fakeLabel textRectForBounds:maxRect limitedToNumberOfLines:0]);
            }
            
            if (detail) {
                fakeLabel.attributedText = [[NSAttributedString alloc] initWithString:detail attributes:self.detailAttributes];
                height += CGRectGetHeight([fakeLabel textRectForBounds:maxRect limitedToNumberOfLines:0]);
            }
            
            heights[section][row] = @(height);
        }];
    }];
    
    self.heights = [heights mutableCopy];
    
    [[Mixpanel sharedInstance] track:@"Opened about page"];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.heights.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.heights[section] count];
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
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;

    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

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
                    PPChangelogViewController *changelogViewController = [[PPChangelogViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
                PPPlainTextViewController *licenseViewController = [PPPlainTextViewController plainTextViewControllerWithString:license];
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
            UIView *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            NSString *title = self.sections[indexPath.section][@"title"];
            if ([@[@"Acknowledgements", @"Team"] containsObject:title] && self.selectedItem[@"username"]) {
                self.actionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];

                NSString *screenName = self.selectedItem[@"username"];
                [self.actionSheet lhs_addActionWithTitle:[NSString stringWithFormat:@"Follow @%@ on Twitter", screenName]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
                                                     [[PPTwitter sharedInstance] followScreenName:self.selectedItem[@"username"]
                                                                                            point:self.selectedPoint
                                                                                             view:self.view
                                                                                         callback:^{
                                                                                             self.selectedItem = nil;
                                                                                             self.selectedPoint = CGPointZero;
                                                                                             self.selectedIndexPath = nil;
                                                                                         }];
                                                     
                                                     self.actionSheet = nil;
                                                 }];
                
                [self.actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *action) {
                                                     self.actionSheet = nil;
                                                 }];

                self.actionSheet.popoverPresentationController.sourceRect = (CGRect){{cell.frame.size.width / 2.0, cell.frame.size.height / 2.0}, {1, 1}};
                self.actionSheet.popoverPresentationController.sourceView = cell;

                [self presentViewController:self.actionSheet animated:YES completion:nil];
            }
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
            self.actionSheet = nil;
        }
    }
}

@end

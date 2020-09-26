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
@import LHSCategoryCollection;
@import LHSTableViewCells;

#import "PPAboutViewController.h"
#import "PPChangelogViewController.h"
#import "PPTheme.h"
#import "PPPlainTextViewController.h"

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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *title = [NSString stringWithFormat:@"Pushpin %@ (%@)", info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]];
    NSString* aboutPlist = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"plist"];

    self.navigationItem.title = title;

    self.sections = [NSArray arrayWithContentsOfFile:aboutPlist];

    self.heights = [NSMutableArray array];

    self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
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
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.selectedItem = self.sections[indexPath.section][@"rows"][indexPath.row];
    UIView *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    NSString *title = self.sections[indexPath.section][@"title"];
    if (self.selectedItem[@"username"]) {
        NSString *screenName = self.selectedItem[@"username"];

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@", screenName]];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
            options[UIApplicationOpenURLOptionUniversalLinksOnly] = @YES;
        }
        [[UIApplication sharedApplication] openURL:url options:options completionHandler:nil];
        return;
    }

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
                    NSURL *url = [NSURL URLWithString:@"https://twitter.com/pushpin_app"];
                    NSMutableDictionary *options = [NSMutableDictionary dictionary];
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
                        options[UIApplicationOpenURLOptionUniversalLinksOnly] = @YES;
                    }
                    [[UIApplication sharedApplication] openURL:url options:options completionHandler:nil];
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

@end

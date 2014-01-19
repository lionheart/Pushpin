//
//  PPChangelogViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/5/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "PPChangelogViewController.h"
#import "PPTheme.h"
#import "UITableViewCellSubtitle.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import "UITableView+Additions.h"

static NSString *CellIdentifier = @"Cell";

@interface PPChangelogViewController ()

@property (nonatomic, strong) NSDictionary *detailAttributes;

@end

@implementation PPChangelogViewController

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"plist"];
    self.data = [NSArray arrayWithContentsOfFile:plistPath];
    self.title = @"Changelog";
    self.heights = [NSMutableDictionary dictionary];
    self.titles = [NSMutableArray array];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    self.detailAttributes = @{NSFontAttributeName: [PPTheme detailLabelFont],
                              NSParagraphStyleAttributeName: paragraphStyle };

    [self calculateHeightsForWidth:CGRectGetWidth(self.tableView.frame) - 20];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)calculateHeightsForWidth:(CGFloat)w {
    [self.titles removeAllObjects];

    CGFloat descriptionHeight;

    for (NSArray *list in self.data) {
        [self.titles addObject:list[0]];
        for (NSArray *pair in list[1]) {
            NSString *description = pair[1];
            
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = [[NSAttributedString alloc] initWithString:description attributes:self.detailAttributes];

            if ([description isEqualToString:@""]) {
                descriptionHeight = 0;
            }
            else {
                descriptionHeight = CGRectGetHeight([label textRectForBounds:CGRectMake(0, 0, w, CGFLOAT_MAX) limitedToNumberOfLines:0]);
            }
            
            self.heights[description] = @(descriptionHeight);
        }
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section][1] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *info = self.data[indexPath.section][1];
    NSString *description = info[indexPath.row][1];
    CGFloat topHeight = [self.heights[description] floatValue];
    return topHeight + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *info = self.data[indexPath.section][1];
    NSString *description = info[indexPath.row][1];
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:description attributes:self.detailAttributes];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self calculateHeightsForWidth:[UIApplication currentSize].width];

    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end

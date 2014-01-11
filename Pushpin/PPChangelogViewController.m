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

    [self calculateHeightsForWidth:CGRectGetWidth(self.tableView.frame)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)calculateHeightsForWidth:(CGFloat)w {
    [self.titles removeAllObjects];

    UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:15];

    NSInteger index = 0;
    CGFloat width = w - 2 * self.tableView.groupedCellMargin - 45;
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGFloat normalFontHeight = [@" " boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size.height;
    NSUInteger emptyLines;
    CGFloat descriptionHeight;
    NSArray *lines;

    for (NSArray *list in self.data) {
        [self.titles addObject:list[0]];
        for (NSArray *pair in list[1]) {
            NSString *description = pair[1];
            
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
                
                NSDictionary *attributes = @{NSFontAttributeName: font};
                CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
                descriptionHeight = [description boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size.height;
                descriptionHeight += emptyLines * normalFontHeight;
            }
            
            self.heights[description] = @(descriptionHeight);
        }
        index++;
    }
    
    [self.tableView reloadData];
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
        float width = CGRectGetWidth(tableView.bounds);

        NSUInteger fontSize = 17;
        NSUInteger padding = tableView.groupedCellMargin;
        UIFont *font = [UIFont fontWithName:[PPTheme boldFontName] size:fontSize];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 16, width - padding, fontSize)];
        label.text = title;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = font;
        NSDictionary *attributes = @{NSFontAttributeName: label.font};
        CGSize maxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
        CGSize textSize = [title boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = self.titles[section];
    if (![title isEqual:@""]) {
        UIFont *font = [UIFont fontWithName:[PPTheme boldFontName] size:17];
        NSUInteger padding = tableView.groupedCellMargin;
        return [self.titles[section] sizeWithFont:font constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.frame) - padding * 2, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height + 20;
    }
    return 0;
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
    cell.textLabel.font = [UIFont fontWithName:[PPTheme fontName] size:15];
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *info = self.data[indexPath.section][1];
    NSString *type = info[indexPath.row][0];
    
    if ([type isEqualToString:@"FIX"]) {
        cell.imageView.image = [UIImage imageNamed:@"IC-Wrench-65"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"IC-Star-5"];
    }
    
    NSString *description = info[indexPath.row][1];
    cell.textLabel.text = description;
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

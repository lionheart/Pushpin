//
//  PPChangelogViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/5/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "PPChangelogViewController.h"
#import "PPGroupedTableViewCell.h"
#import "AppDelegate.h"

@interface PPChangelogViewController ()

@end

@implementation PPChangelogViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"plist"];
        self.data = [NSArray arrayWithContentsOfFile:plistPath];
        self.title = @"Changelog";
        self.heights = [NSMutableDictionary dictionary];
        self.titles = [NSMutableArray array];
        UIFont *font = [UIFont fontWithName:[AppDelegate mediumFontName] size:15];
        NSInteger index = 0;
        for (NSArray *list in self.data) {
            [self.titles addObject:list[0]];
            for (NSArray *pair in list[1]) {
                NSString *description = pair[1];

                if ([description isEqualToString:@""]) {
                    self.heights[description] = @(0);
                }
                else {
                    self.heights[description] = @([description sizeWithFont:font constrainedToSize:CGSizeMake(255, CGFLOAT_MAX)].height);
                }
            }
            index++;
        }
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
        UIFont *font = [UIFont fontWithName:[AppDelegate heavyFontName] size:fontSize];
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
        UIFont *font = [UIFont fontWithName:[AppDelegate heavyFontName] size:17];
        return [self.titles[section] sizeWithFont:font constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)].height + 20;
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
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ChoiceCellIdentifier];
    }

    cell.accessoryView = nil;
    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:15];
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *info = self.data[indexPath.section][1];
    NSString *type = info[indexPath.row][0];
    
    if ([type isEqualToString:@"FIX"]) {
        cell.imageView.image = [UIImage imageNamed:@"caution-dash"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"star-table"];
    }
    
    NSString *description = info[indexPath.row][1];
    cell.textLabel.text = description;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

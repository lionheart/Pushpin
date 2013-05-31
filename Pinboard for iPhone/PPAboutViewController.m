//
//  PPAboutViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "PPAboutViewController.h"
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface PPAboutViewController ()

@end

@implementation PPAboutViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        NSArray *credits = @[@[@"Rachel", @"For always believing in me."], @[@"Dante and Isabelle", @"For inspiring me and for making me laugh."], @[@"Maciej Ceglowski", @"For making Pinboard."]];
        NSArray *beta = @[@[@"Michael Solis", [NSNull null]], @[@"Phil Havens", [NSNull null]], @[@"Carolina Bertazzo Currat", [NSNull null]]];
        NSArray *translations = @[@[@"Riccardo Mori", @"Italian"], @[@"James Lepthien", @"German"], @[@"Jérôme Tomasini", @"French"], @[@"Vítor Galvão", @"Portuguese"]];
        NSArray *licenses = @[@[@"TTTAttributedLabel", @"Copyright (c) 2011 Mattt Thompson (http://mattt.me/)"
                                "\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:"
                                "\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
                                "\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."]];
        self.data = @[credits, translations, beta, licenses];
        self.titles = @[@"Credits", @"Translations", @"Beta Testers", @"Licenses"];
        self.expandedIndexPaths = [NSMutableArray array];
        
        self.heights = [NSMutableDictionary dictionary];
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        for (NSArray *list in self.data) {
            for (NSArray *pair in list) {
                for (NSString *item in pair) {
                    if ([item isEqual:[NSNull null]]) {
                        self.heights[item] = @(0);
                    }
                    else {
                        self.heights[item] = @([item sizeWithFont:font constrainedToSize:CGSizeMake(280, CGFLOAT_MAX)].height);
                    }
                }
            }
        }
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    float width = tableView.bounds.size.width;
    
    int fontSize = 17;
    int padding = 15;
    UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 16, width - padding, fontSize)];
    label.text = self.titles[section];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = HEX(0x4C566CFF);
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0,1);
    label.font = font;
    CGSize textSize = [self.titles[section] sizeWithFont:label.font];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    return [self.titles[section] sizeWithFont:font constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)].height + 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat topHeight = [self.heights[self.data[indexPath.section][indexPath.row][0]] floatValue];
    CGFloat bottomHeight = [self.heights[self.data[indexPath.section][indexPath.row][1]] floatValue];
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
    cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    cell.detailTextLabel.numberOfLines = 0;
    
    NSString *title = self.data[indexPath.section][indexPath.row][0];
    NSString *detail = self.data[indexPath.section][indexPath.row][1];
    
    CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackgroundForHeight:height];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayerForHeight:height]];
    }
    
    if (indexPath.row < 2) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayerForHeight:height]];
    }
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer forHeight:height];

    cell.textLabel.text = title;
    if ([self.heights[detail] floatValue] > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        cell.detailTextLabel.text = @"Tap to expand.";
    }
    else {
        if (![detail isEqual:[NSNull null]]) {
            cell.detailTextLabel.text = detail;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

@end

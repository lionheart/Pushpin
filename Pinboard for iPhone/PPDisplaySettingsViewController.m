//
//  PPDisplaySettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "PPDisplaySettingsViewController.h"
#import "PPGroupedTableViewCell.h"

@interface PPDisplaySettingsViewController ()

@end

@implementation PPDisplaySettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Advanced Settings", nil);
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        switch (indexPath.section) {
            case 0:
                cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ChoiceCellIdentifier];
                break;
                
            case 1:
                cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ChoiceCellIdentifier];
                break;
                
            case 2:
                cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
                
            default:
                break;
        }
    }
    
    cell.accessoryView = nil;
    
    CGSize size;
    CGSize switchSize;
    
    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    cell.detailTextLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
    }
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row < 4) {
                [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
            }
            break;
            
        case 2:
            if (indexPath.row < 2) {
                [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
            }
            break;
            
        default:
            break;
    }
    
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Dim read bookmarks?", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            size = cell.frame.size;
            self.dimReadPostsSwitch = [[PPSwitch alloc] init];
            switchSize = self.dimReadPostsSwitch.frame.size;
            self.dimReadPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
            self.dimReadPostsSwitch.on = [AppDelegate sharedDelegate].dimReadPosts;
            [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.dimReadPostsSwitch;
            break;
            
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Double tap to edit?", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            size = cell.frame.size;
            self.doubleTapToEditSwitch = [[PPSwitch alloc] init];
            switchSize = self.doubleTapToEditSwitch.frame.size;
            self.doubleTapToEditSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
            self.doubleTapToEditSwitch.on = [AppDelegate sharedDelegate].doubleTapToEdit;
            [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.doubleTapToEditSwitch;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedString(@"Hide tags & descriptions?", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            size = cell.frame.size;
            self.compressPostsSwitch = [[PPSwitch alloc] init];
            switchSize = self.compressPostsSwitch.frame.size;
            self.compressPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
            self.compressPostsSwitch.on = [AppDelegate sharedDelegate].compressPosts;
            [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.compressPostsSwitch;
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"You can also toggle this by pinching in or out when viewing bookmarks.";
}

- (void)switchChangedValue:(id)sender {
    if (sender == self.compressPostsSwitch) {
        [[AppDelegate sharedDelegate] setCompressPosts:self.compressPostsSwitch.on];
    }
    else if (sender == self.doubleTapToEditSwitch) {
        [[AppDelegate sharedDelegate] setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    }
    else {
        [[AppDelegate sharedDelegate] setDimReadPosts:self.dimReadPostsSwitch.on];
    }
}

@end

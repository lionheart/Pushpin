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
#import "PPDefaultFeedViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"

@interface PPDisplaySettingsViewController ()

@end

@implementation PPDisplaySettingsViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Advanced Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;

        case 1:
            return 1;
    }
    return 0;
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
    
    cell.textLabel.font = [UIFont fontWithName:[PPTheme fontName] size:16];
    cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:16];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = NSLocalizedString(@"Dim read bookmarks", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.dimReadPostsSwitch = [[UISwitch alloc] init];
                switchSize = self.dimReadPostsSwitch.frame.size;
                self.dimReadPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.dimReadPostsSwitch.on = [AppDelegate sharedDelegate].dimReadPosts;
                [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.dimReadPostsSwitch;
                break;
                
            case 1:
                cell.textLabel.text = NSLocalizedString(@"Double tap to edit", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.doubleTapToEditSwitch = [[UISwitch alloc] init];
                switchSize = self.doubleTapToEditSwitch.frame.size;
                self.doubleTapToEditSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.doubleTapToEditSwitch.on = [AppDelegate sharedDelegate].doubleTapToEdit;
                [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.doubleTapToEditSwitch;
                break;
            case 2:
                cell.textLabel.text = NSLocalizedString(@"Auto mark as read", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.markReadSwitch = [[UISwitch alloc] init];
                switchSize = self.markReadSwitch.frame.size;
                self.markReadSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.markReadSwitch.on = [AppDelegate sharedDelegate].markReadPosts;
                [self.markReadSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.markReadSwitch;
                break;
            case 3:
                cell.textLabel.text = NSLocalizedString(@"Auto correct text", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.autoCorrectionSwitch = [[UISwitch alloc] init];
                switchSize = self.autoCorrectionSwitch.frame.size;
                self.autoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.autoCorrectionSwitch.on = [AppDelegate sharedDelegate].enableAutoCorrect;
                [self.autoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.autoCorrectionSwitch;
                break;
            case 4:
                cell.textLabel.text = NSLocalizedString(@"Auto capitalize text", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.autoCapitalizationSwitch = [[UISwitch alloc] init];
                switchSize = self.autoCapitalizationSwitch.frame.size;
                self.autoCapitalizationSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.autoCapitalizationSwitch.on = [AppDelegate sharedDelegate].enableAutoCapitalize;
                [self.autoCapitalizationSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.autoCapitalizationSwitch;
                break;
            case 5:
                cell.textLabel.text = NSLocalizedString(@"Compress bookmark list", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                size = cell.frame.size;
                self.compressPostsSwitch = [[UISwitch alloc] init];
                switchSize = self.compressPostsSwitch.frame.size;
                self.compressPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                self.compressPostsSwitch.on = [AppDelegate sharedDelegate].compressPosts;
                [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = self.compressPostsSwitch;
                break;
                
                
            default:
                break;
        }
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"Default feed", nil);
        cell.detailTextLabel.text = [AppDelegate sharedDelegate].defaultFeedDescription;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            // Show the default feed selection
            PPDefaultFeedViewController *vc = [[PPDefaultFeedViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"You can also toggle this by pinching in or out when viewing bookmarks.", nil);
    } else if (section == 1) {
        return NSLocalizedString(@"The selected default feed will be shown immediately after starting the app.", nil);
    }
    
    return @"";
}

- (void)switchChangedValue:(id)sender {
    if (sender == self.compressPostsSwitch) {
        [[AppDelegate sharedDelegate] setCompressPosts:self.compressPostsSwitch.on];
    }
    else if (sender == self.doubleTapToEditSwitch) {
        [[AppDelegate sharedDelegate] setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    }
    else if (sender == self.dimReadPostsSwitch) {
        [[AppDelegate sharedDelegate] setDimReadPosts:self.dimReadPostsSwitch.on];
    }
    else if (sender == self.markReadSwitch) {
        [[AppDelegate sharedDelegate] setMarkReadPosts:self.markReadSwitch.on];
    }
    else if (sender == self.autoCorrectionSwitch) {
        [[AppDelegate sharedDelegate] setEnableAutoCorrect:self.autoCorrectionSwitch.on];
    }
    else if (sender == self.autoCapitalizationSwitch) {
        [[AppDelegate sharedDelegate] setEnableAutoCapitalize:self.autoCapitalizationSwitch.on];
    }
}

@end

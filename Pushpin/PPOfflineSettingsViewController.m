//
//  PPOfflineSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 11/4/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPOfflineSettingsViewController.h"
#import "PPTheme.h"
#import <LHSTableViewCells/LHSTableViewCellValue1.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPOfflineSettingsViewController ()

@end

@implementation PPOfflineSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return PPOfflineSettingsRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    switch ((PPOfflineSettingsRowType)indexPath.row) {
        case PPOfflineSettingsRowToggle: {
            cell.textLabel.text = @"Enable Offline Reading";
            break;
        }
            
        case PPOfflineSettingsRowCellular: {
            cell.textLabel.text = @"Use Cellular Data";
            break;
        }
            
        case PPOfflineSettingsRowUsage: {
            cell.textLabel.text = @"Usage";
            break;
        }
            
        case PPOfflineSettingsRowLimit: {
            cell.textLabel.text = @"Usage Limit";
            cell.detailTextLabel.text = @"100mb";
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

@end

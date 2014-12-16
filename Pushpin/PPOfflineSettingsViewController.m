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
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";
static NSString *DefaultCellIdentifier = @"DefaultCellIdentifier";

@interface PPOfflineSettingsViewController ()

@property (nonatomic, retain) UISwitch *offlineReadingSwitch;
@property (nonatomic, retain) UISwitch *downloadFullWebpageForOfflineCacheSwitch;

- (void)switchChangedValue:(id)sender;
- (void)updateUsageLimitTo:(NSInteger)limit;
- (void)updateOfflineFetchCriteriaTo:(PPOfflineFetchCriteriaType)criteria;

@end

@implementation PPOfflineSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Offline Settings";
    
    PPSettings *settings = [PPSettings sharedSettings];
    
    self.offlineReadingSwitch = [[UISwitch alloc] init];
    self.offlineReadingSwitch.on = settings.offlineReadingEnabled;
    [self.offlineReadingSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.downloadFullWebpageForOfflineCacheSwitch = [[UISwitch alloc] init];
    self.downloadFullWebpageForOfflineCacheSwitch.on = settings.useCellularDataForOfflineCache;
    [self.downloadFullWebpageForOfflineCacheSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DefaultCellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPOfflineSettingsSectionType)section) {
        case PPOfflineSettingsSectionTop:
            return PPOfflineSettingsRowCount;
            
        case PPOfflineSettingsSectionClearCache:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    switch ((PPOfflineSettingsSectionType)indexPath.section) {
        case PPOfflineSettingsSectionTop: {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.detailTextLabel.text = nil;
            cell.textLabel.text = nil;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.offlineReadingSwitch.on) {
                cell.textLabel.textColor = [UIColor blackColor];
                cell.userInteractionEnabled = YES;
            }
            else {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.userInteractionEnabled = NO;
            }
            
            CGSize size;
            CGSize switchSize;

            switch ((PPOfflineSettingsRowType)indexPath.row) {
                case PPOfflineSettingsRowToggle: {
                    cell.textLabel.text = @"Enable Offline Mode";
                    cell.textLabel.textColor = [UIColor blackColor];
                    cell.userInteractionEnabled = YES;

                    size = cell.frame.size;
                    switchSize = self.offlineReadingSwitch.frame.size;
                    self.offlineReadingSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.offlineReadingSwitch;
                    break;
                }
                    
                case PPOfflineSettingsRowDownloadAll: {
                    cell.textLabel.text = @"Download Full Webpage";
                    
                    size = cell.frame.size;
                    switchSize = self.downloadFullWebpageForOfflineCacheSwitch.frame.size;
                    self.downloadFullWebpageForOfflineCacheSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.downloadFullWebpageForOfflineCacheSwitch;
                    break;
                }
                    
                case PPOfflineSettingsRowFetchCriteria: {
                    cell.textLabel.text = @"Fetch Criteria";
                    cell.detailTextLabel.text = PPOfflineFetchCriterias()[[PPSettings sharedSettings].offlineFetchCriteria];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
                    
                case PPOfflineSettingsRowUsage: {
                    cell.textLabel.text = @"Current Usage";
                    NSInteger diskUsage = [[NSURLCache sharedURLCache] currentDiskUsage];
                    cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:diskUsage countStyle:NSByteCountFormatterCountStyleFile];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                    
                case PPOfflineSettingsRowLimit: {
                    cell.textLabel.text = @"Usage Limit";
                    NSInteger diskUsage = [[NSURLCache sharedURLCache] diskCapacity];
                    cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:diskUsage countStyle:NSByteCountFormatterCountStyleFile];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
            }
            break;
        }
            
        case PPOfflineSettingsSectionClearCache: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = @"Clear Cache";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor redColor];
            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ((PPOfflineSettingsSectionType)indexPath.section) {
        case PPOfflineSettingsSectionTop: {
            switch ((PPOfflineSettingsRowType)indexPath.row) {
                case PPOfflineSettingsRowLimit: {
                    UIAlertController *actionSheet = [UIAlertController lhs_actionSheetWithTitle:@"Usage Limit"];
                    [actionSheet lhs_addActionWithTitle:@"100 MB"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateUsageLimitTo:100 * 1000 * 1000];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"500 MB"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateUsageLimitTo:500 * 1000 * 1000];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"1 GB"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateUsageLimitTo:1000 * 1000 * 1000];
                                                }];

                    [actionSheet lhs_addActionWithTitle:@"2 GB"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateUsageLimitTo:2 * 1000 * 1000 * 1000];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
                                                }];
                    
                    [self presentViewController:actionSheet
                                       animated:YES
                                     completion:nil];
                    break;
                }
                    
                case PPOfflineSettingsRowFetchCriteria: {
                    UIAlertController *actionSheet = [UIAlertController lhs_actionSheetWithTitle:@"Fetch Criteria"];
                    [actionSheet lhs_addActionWithTitle:@"Unread"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaUnread];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"Recent (last 30 days)"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaRecent];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"Unread and Recent"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaUnreadAndRecent];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"Everything"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaEverything];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil];
                    
                    [self presentViewController:actionSheet
                                       animated:YES
                                     completion:nil];
                    break;
                }
                    
                default:
                    break;
            }
            break;
        }
            
        case PPOfflineSettingsSectionClearCache: {
            UIAlertController *confirmation = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                message:@"Are you sure you'd like to clear the cache? There is no undo."];
            
            [confirmation lhs_addActionWithTitle:@"Delete"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                             NSURLCache *cache = [NSURLCache sharedURLCache];
                                             [cache removeAllCachedResponses];
                                             
                                             [tableView beginUpdates];
                                             [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOfflineSettingsRowUsage inSection:PPOfflineSettingsSectionTop]]
                                                                   withRowAnimation:UITableViewRowAnimationFade];
                                             [tableView endUpdates];
                                         }];
            
            [confirmation lhs_addActionWithTitle:@"Cancel"
                                           style:UIAlertActionStyleCancel
                                         handler:nil];
            
            [self presentViewController:confirmation animated:YES completion:nil];
            break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ((PPOfflineSettingsSectionType)section) {
        case PPOfflineSettingsSectionClearCache:
            return @"This will delete any stored articles on your device.";
            
        default:
            return nil;
    }
}

#pragma mark - Other

- (void)switchChangedValue:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];
    if (sender == self.offlineReadingSwitch) {
        [settings setOfflineReadingEnabled:self.offlineReadingSwitch.on];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else if (sender == self.downloadFullWebpageForOfflineCacheSwitch) {
        [settings setDownloadFullWebpageForOfflineCache:self.downloadFullWebpageForOfflineCacheSwitch.on];
    }
}

- (void)updateUsageLimitTo:(NSInteger)limit {
    NSURLCache *cache = [NSURLCache sharedURLCache];
    cache.diskCapacity = limit;

    PPSettings *settings = [PPSettings sharedSettings];
    settings.offlineUsageLimit = limit;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOfflineSettingsRowLimit inSection:PPOfflineSettingsSectionTop]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)updateOfflineFetchCriteriaTo:(PPOfflineFetchCriteriaType)criteria {
    PPSettings *settings = [PPSettings sharedSettings];
    settings.offlineFetchCriteria = criteria;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOfflineSettingsRowFetchCriteria inSection:PPOfflineSettingsSectionTop]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

@end

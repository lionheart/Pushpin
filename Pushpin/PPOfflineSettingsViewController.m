//
//  PPOfflineSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 11/4/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPOfflineSettingsViewController.h"
#import "PPOfflineDownloadViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPPinboardDataSource.h"
#import "PPPinboardMetadataCache.h"

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
    
    self.definesPresentationContext = YES;
    self.title = NSLocalizedString(@"Offline Settings", nil);
    
    PPSettings *settings = [PPSettings sharedSettings];
    
    self.offlineReadingSwitch = [[UISwitch alloc] init];
    self.offlineReadingSwitch.on = settings.offlineReadingEnabled;
    [self.offlineReadingSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.downloadFullWebpageForOfflineCacheSwitch = [[UISwitch alloc] init];
    self.downloadFullWebpageForOfflineCacheSwitch.on = settings.downloadFullWebpageForOfflineCache;
    [self.downloadFullWebpageForOfflineCacheSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DefaultCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOfflineSettingsRowUsage inSection:PPOfflineSettingsSectionTop]]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPOfflineSettingsSectionType)section) {
        case PPOfflineSettingsSectionTop:
            return PPOfflineSettingsRowCount;
            
        case PPOfflineSettingsSectionClearCache:
            return 1;

        case PPOfflineSettingsSectionManualDownload:
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
                    cell.textLabel.text = NSLocalizedString(@"Enable Offline Mode", nil);
                    cell.textLabel.textColor = [UIColor blackColor];
                    cell.userInteractionEnabled = YES;

                    size = cell.frame.size;
                    switchSize = self.offlineReadingSwitch.frame.size;
                    self.offlineReadingSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.offlineReadingSwitch;
                    break;
                }
                    
                case PPOfflineSettingsRowDownloadAll: {
                    cell.textLabel.text = NSLocalizedString(@"Download Full Webpage", nil);
                    
                    size = cell.frame.size;
                    switchSize = self.downloadFullWebpageForOfflineCacheSwitch.frame.size;
                    self.downloadFullWebpageForOfflineCacheSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.downloadFullWebpageForOfflineCacheSwitch;
                    break;
                }
                    
                case PPOfflineSettingsRowFetchCriteria: {
                    cell.textLabel.text = NSLocalizedString(@"Fetch Criteria", nil);
                    cell.detailTextLabel.text = NSLocalizedString(PPOfflineFetchCriterias()[[PPSettings sharedSettings].offlineFetchCriteria], nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
                    
                case PPOfflineSettingsRowUsage: {
                    cell.textLabel.text = NSLocalizedString(@"Current Usage", nil);
                    NSInteger diskUsage = [[PPAppDelegate sharedDelegate].urlCache currentDiskUsage];
                    cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:diskUsage countStyle:NSByteCountFormatterCountStyleFile];
                    cell.accessoryType = UITableViewCellAccessoryNone;

                    break;
                }
                    
                case PPOfflineSettingsRowLimit: {
                    cell.textLabel.text = NSLocalizedString(@"Usage Limit", nil);
                    NSInteger diskUsage = [[PPAppDelegate sharedDelegate].urlCache diskCapacity];
                    cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:diskUsage countStyle:NSByteCountFormatterCountStyleFile];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
            }
            break;
        }
            
        case PPOfflineSettingsSectionManualDownload: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Download Bookmarks", nil);
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            UIColor *color = [button titleColorForState:UIControlStateNormal];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;

            if (self.offlineReadingSwitch.on) {
                cell.textLabel.textColor = color;
                cell.userInteractionEnabled = YES;
            }
            else {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.userInteractionEnabled = NO;
            }
            break;
        }

        case PPOfflineSettingsSectionClearCache: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Clear Offline Cache", nil);
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
                    UIAlertController *actionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Usage Limit", nil)];
                    [actionSheet lhs_addActionWithTitle:@"10 MB"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateUsageLimitTo:10 * 1000 * 1000];
                                                }];

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
                    
                    actionSheet.modalPresentationStyle = UIModalPresentationPopover;

                    UIPopoverPresentationController *popPresenter = actionSheet.popoverPresentationController;

                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    popPresenter.sourceView = cell;
                    popPresenter.sourceRect = cell.bounds;

                    [self presentViewController:actionSheet
                                       animated:YES
                                     completion:nil];
                    break;
                }
                    
                case PPOfflineSettingsRowFetchCriteria: {
                    UIAlertController *actionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Fetch Criteria", nil)];
                    [actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Unread", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaUnread];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Recent (last 30 days)", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaRecent];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Unread and Recent", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaUnreadAndRecent];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Everything", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self updateOfflineFetchCriteriaTo:PPOfflineFetchCriteriaEverything];
                                                }];
                    
                    [actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil];

                    actionSheet.modalPresentationStyle = UIModalPresentationPopover;

                    UIPopoverPresentationController *popPresenter = actionSheet.popoverPresentationController;

                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    popPresenter.sourceView = cell;
                    popPresenter.sourceRect = cell.bounds;
                    
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
            
        case PPOfflineSettingsSectionManualDownload: {
            PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
            
            if (!delegate.connectionAvailable) {
                UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                             message:NSLocalizedString(@"You can't download anything without an internet connection.", nil)];
                
                [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                        style:UIAlertActionStyleDefault
                                      handler:nil];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            else {
                PPOfflineDownloadViewController *offlineDownloadViewController = [[PPOfflineDownloadViewController alloc] init];
                PPNavigationController *navigation = [[PPNavigationController alloc] initWithRootViewController:offlineDownloadViewController];
                navigation.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:navigation animated:YES completion:nil];
                break;
            }
        }

        case PPOfflineSettingsSectionClearCache: {
            UIAlertController *confirmation = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                message:NSLocalizedString(@"Are you sure you'd like to clear the cache? There is no undo.", nil)];
            
            [confirmation lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                 PPURLCache *cache = [PPAppDelegate sharedDelegate].urlCache;
                                                 [cache removeAllCachedResponses];
                                                 [[PPPinboardMetadataCache sharedCache] removeAllObjects];
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [tableView beginUpdates];
                                                     [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPOfflineSettingsRowUsage
                                                                                                            inSection:PPOfflineSettingsSectionTop]]
                                                                      withRowAnimation:UITableViewRowAnimationFade];
                                                     [tableView endUpdates];
                                                 });
                                             });
                                         }];
            
            [confirmation lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
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
            return NSLocalizedString(@"This will delete any stored articles on your device.", nil);

        case PPOfflineSettingsSectionManualDownload:
            return NSLocalizedString(@"By default, Pushpin will download bookmarks matching your fetch criteria in the background. If you don't want to wait, the button above will start a sync manually.", nil);
            
        default:
            return nil;
    }
}

#pragma mark - Other

- (void)switchChangedValue:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];
    if (sender == self.offlineReadingSwitch) {
        [settings setOfflineReadingEnabled:self.offlineReadingSwitch.on];
        
        PPSettings *settings = [PPSettings sharedSettings];
        if (settings.offlineReadingEnabled) {
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        }
        else {
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else if (sender == self.downloadFullWebpageForOfflineCacheSwitch) {
        [settings setDownloadFullWebpageForOfflineCache:self.downloadFullWebpageForOfflineCacheSwitch.on];
    }
}

- (void)updateUsageLimitTo:(NSInteger)limit {
    PPURLCache *cache = [PPAppDelegate sharedDelegate].urlCache;
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

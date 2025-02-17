// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PPDisplaySettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

@import QuartzCore;
@import LHSCategoryCollection;
@import FMDB;
@import LHSTableViewCells;

#import "PPAppDelegate.h"
#import "PPDisplaySettingsViewController.h"
#import "PPDefaultFeedViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"
#import "PPPinboardMetadataCache.h"
#import "PPUtilities.h"

#import "LHSFontSelectionViewController.h"

static NSString *CellIdentifier = @"Cell";
static NSString *ChoiceCellIdentifier = @"ChoiceCell";
static NSString *SubtitleCellIdentifier = @"SubtitleCell";

@interface PPDisplaySettingsViewController ()

@property (nonatomic, retain) UISwitch *privateByDefaultSwitch;
@property (nonatomic, retain) UISwitch *readByDefaultSwitch;
@property (nonatomic, retain) UISwitch *dimReadPostsSwitch;
@property (nonatomic, retain) UISwitch *compressPostsSwitch;
@property (nonatomic, retain) UISwitch *hidePrivateLockSwitch;
@property (nonatomic, retain) UISwitch *doubleTapToEditSwitch;
@property (nonatomic, retain) UISwitch *markReadSwitch;
@property (nonatomic, retain) UISwitch *autoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *tagAutoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *autoCapitalizationSwitch;
@property (nonatomic, retain) UISwitch *onlyPromptToAddOnceSwitch;
@property (nonatomic, retain) UISwitch *alwaysShowAlertSwitch;
@property (nonatomic, retain) UISwitch *enableBookmarkPromptSwitch;

@property (nonatomic, strong) UIAlertController *fontSizeAdjustmentActionSheet;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)switchChangedValue:(id)sender;

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

    self.title = NSLocalizedString(@"Advanced Settings", nil);

    self.fontSizeAdjustmentActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Font Adjustment", nil)];

    for (NSString *title in PPFontAdjustmentTypes()) {
        [self.fontSizeAdjustmentActionSheet lhs_addActionWithTitle:NSLocalizedString(title, nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
            NSInteger index = [PPFontAdjustmentTypes() indexOfObject:action.title];
            if (index < [PPFontAdjustmentTypes() count]) {
                PPFontAdjustmentType fontAdjustment = (PPFontAdjustmentType)index;
                PPSettings *settings = [PPSettings sharedSettings];
                settings.fontAdjustment = fontAdjustment;

                [self.tableView reloadData];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[PPPinboardMetadataCache sharedCache] reset];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
                    });
                });
            }
        }];
    }

    [self.fontSizeAdjustmentActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];

    PPSettings *settings = [PPSettings sharedSettings];
    self.enableBookmarkPromptSwitch = [[UISwitch alloc] init];
    self.enableBookmarkPromptSwitch.on = !settings.turnOffBookmarkPrompt;
    [self.enableBookmarkPromptSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.privateByDefaultSwitch = [[UISwitch alloc] init];
    self.privateByDefaultSwitch.on = settings.privateByDefault;
    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.readByDefaultSwitch = [[UISwitch alloc] init];
    self.readByDefaultSwitch.on = settings.readByDefault;
    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.autoCapitalizationSwitch = [[UISwitch alloc] init];
    self.autoCapitalizationSwitch.on = settings.enableAutoCapitalize;
    [self.autoCapitalizationSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.compressPostsSwitch = [[UISwitch alloc] init];
    self.compressPostsSwitch.on = settings.compressPosts;
    [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.hidePrivateLockSwitch = [[UISwitch alloc] init];
    self.hidePrivateLockSwitch.on = settings.hidePrivateLock;
    [self.hidePrivateLockSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.markReadSwitch = [[UISwitch alloc] init];
    self.markReadSwitch.on = settings.markReadPosts;
    [self.markReadSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.doubleTapToEditSwitch = [[UISwitch alloc] init];
    self.doubleTapToEditSwitch.on = settings.doubleTapToEdit;
    [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.autoCorrectionSwitch = [[UISwitch alloc] init];
    self.autoCorrectionSwitch.on = settings.enableAutoCorrect;
    [self.autoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.tagAutoCorrectionSwitch = [[UISwitch alloc] init];
    self.tagAutoCorrectionSwitch.on = settings.enableTagAutoCorrect;
    [self.tagAutoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.onlyPromptToAddOnceSwitch = [[UISwitch alloc] init];
    self.onlyPromptToAddOnceSwitch.on = !settings.onlyPromptToAddOnce;
    [self.onlyPromptToAddOnceSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.dimReadPostsSwitch = [[UISwitch alloc] init];
    self.dimReadPostsSwitch.on = settings.dimReadPosts;
    [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.alwaysShowAlertSwitch = [[UISwitch alloc] init];
    self.alwaysShowAlertSwitch.on = settings.alwaysShowClipboardNotification;
    [self.alwaysShowAlertSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:ChoiceCellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];

    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionDisplaySettings:
            return PPRowCountDisplaySettings;

        case PPSectionBrowseSettings:
            return PPRowCountBrowse;

        case PPSectionOtherDisplaySettings:
            if (self.enableBookmarkPromptSwitch.on) {
                if (self.onlyPromptToAddOnceSwitch.on) {
                    return PPRowCountOtherSettings - 2;
                } else {
                    return PPRowCountOtherSettings;
                }
            } else {
                return 1;
            }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionDisplaySettings:
            switch ((PPEditSettingsRowType)indexPath.row) {
                case PPEditAutoMarkAsReadRow:
                    return 56;

                default:
                    return 44;
            }

        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseCompressRow:
                    return 74;

                default:
                    return 44;
            }

        case PPSectionOtherDisplaySettings:
            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherTurnOffPrompt:
                    return 92;

                case PPOtherOnlyPromptToAddBookmarksOnce:
                    return 92;

                case PPOtherDisplayClearCache:
                    return 74;

                case PPOtherAlwaysShowAlert:
                    return 92;
            }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    CGSize size;
    CGSize switchSize;

    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionDisplaySettings:
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.text = nil;
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPEditSettingsRowType)indexPath.row) {
                case PPEditDefaultToPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private by default?", nil);
                    size = cell.frame.size;

                    switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.privateByDefaultSwitch;
                    break;

                case PPEditDefaultToRead:
                    cell.textLabel.text = NSLocalizedString(@"Read by default?", nil);
                    size = cell.frame.size;
                    switchSize = self.readByDefaultSwitch.frame.size;

                    self.readByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.readByDefaultSwitch;
                    break;

                case PPEditDoubleTapRow:
                    cell.textLabel.text = NSLocalizedString(@"Double tap to edit", nil);
                    size = cell.frame.size;
                    switchSize = self.doubleTapToEditSwitch.frame.size;
                    self.doubleTapToEditSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.doubleTapToEditSwitch;
                    break;

                case PPEditAutoMarkAsReadRow:
                    cell.textLabel.text = NSLocalizedString(@"Auto mark as read", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"When opening unread bookmarks.", nil);

                    size = cell.frame.size;
                    switchSize = self.markReadSwitch.frame.size;
                    self.markReadSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.markReadSwitch;
                    break;

                case PPEditAutocorrectTextRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect text", nil);
                    size = cell.frame.size;
                    switchSize = self.autoCorrectionSwitch.frame.size;
                    self.autoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.autoCorrectionSwitch;
                    break;

                case PPEditAutocorrectTagsRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect tags", nil);
                    size = cell.frame.size;
                    switchSize = self.tagAutoCorrectionSwitch.frame.size;
                    self.tagAutoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.tagAutoCorrectionSwitch;
                    break;

                case PPEditAutocapitalizeRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocapitalize text", nil);
                    size = cell.frame.size;
                    switchSize = self.autoCapitalizationSwitch.frame.size;
                    self.autoCapitalizationSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.autoCapitalizationSwitch;
                    break;
            }
            break;

        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseCompressRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Compress bookmark list", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Limit descriptions to two lines and tags to one line.", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.compressPostsSwitch.frame.size;
                    self.compressPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.compressPostsSwitch;
                    break;

                case PPBrowseDimReadRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Dim read bookmarks", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.dimReadPostsSwitch.frame.size;
                    self.dimReadPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.dimReadPostsSwitch;
                    break;

                case PPBrowseFontRow: {
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Font", nil);

                    UIFont *font = [PPTheme titleFont];

                    if ([font.fontName hasPrefix:@"."]) {
                        cell.detailTextLabel.text = [LHSFontSelectionViewController fontNameToDisplayName:font.fontName];
                    } else {
                        cell.detailTextLabel.text = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
                    }

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }

                case PPBrowseFontSizeRow: {
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Font size", nil);
                    cell.detailTextLabel.text = NSLocalizedString(PPFontAdjustmentTypes()[[[PPSettings sharedSettings] fontAdjustment]], nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }

                case PPBrowseHidePrivateLock: {
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Hide Private Lock", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.hidePrivateLockSwitch.frame.size;
                    self.hidePrivateLockSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.hidePrivateLockSwitch;
                    break;
                }

                case PPBrowseDefaultFeedRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Default Feed", nil);
                    cell.detailTextLabel.text = [PPSettings sharedSettings].defaultFeedDescription;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;

        case PPSectionOtherDisplaySettings:
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.text = nil;
            cell.detailTextLabel.numberOfLines = 0;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherTurnOffPrompt:
                    cell.textLabel.text = NSLocalizedString(@"Enable clipboard prompt", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Display a prompt when Pushpin detects a URL on the clipboard.", nil);

                    size = cell.frame.size;
                    switchSize = self.enableBookmarkPromptSwitch.frame.size;
                    self.enableBookmarkPromptSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.enableBookmarkPromptSwitch;
                    break;

                case PPOtherOnlyPromptToAddBookmarksOnce:
                    cell.textLabel.text = NSLocalizedString(@"Always display prompt", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Always show the add bookmark prompt, even for URLs that Pushpin has seen before.", nil);

                    size = cell.frame.size;
                    switchSize = self.onlyPromptToAddOnceSwitch.frame.size;
                    self.onlyPromptToAddOnceSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.onlyPromptToAddOnceSwitch;
                    break;

                case PPOtherDisplayClearCache:
                    cell.textLabel.text = NSLocalizedString(@"Reset the list of stored URLs", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Resets the list of URLs that you've decided not to add from the clipboard.", nil);
                    cell.isAccessibilityElement = YES;
                    cell.accessibilityLabel = NSLocalizedString(@"Reset URL", nil);
                    break;

                case PPOtherAlwaysShowAlert:
                    cell.textLabel.text = NSLocalizedString(@"Notify when a URL isn't added", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Display a notification when the URL currently on the clipboard is one that you've previously decided not to add.", nil);

                    size = cell.frame.size;
                    switchSize = self.alwaysShowAlertSwitch.frame.size;
                    self.alwaysShowAlertSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.alwaysShowAlertSwitch;
                    break;
            }
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseDefaultFeedRow: {
                    // Show the default feed selection
                    PPDefaultFeedViewController *vc = [[PPDefaultFeedViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                }

                case PPBrowseFontRow: {
                    NSArray *preferredFontNames = @[@"Flex-Regular", @"Brando-Regular", @"AvenirNext-Regular", @"LyonTextApp-Regular", [UIFont systemFontOfSize:10].fontName, [UIFont boldSystemFontOfSize:10].fontName];
                    LHSFontSelectionViewController *fontSelectionViewController = [[LHSFontSelectionViewController alloc] initWithPreferredFontNames:preferredFontNames
                                                                                                                              onlyShowPreferredFonts:NO];
                    fontSelectionViewController.delegate = self;
                    [self.navigationController pushViewController:fontSelectionViewController animated:YES];
                    break;
                }

                case PPBrowseFontSizeRow: {
                    if (!self.fontSizeAdjustmentActionSheet.presentingViewController) {
                        UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
                        self.fontSizeAdjustmentActionSheet.popoverPresentationController.sourceView = cell;
                        self.fontSizeAdjustmentActionSheet.popoverPresentationController.sourceRect = [cell lhs_centerRect];

                        [self presentViewController:self.fontSizeAdjustmentActionSheet animated:YES completion:nil];
                    }
                    break;
                }

                default: break;
            }
            break;

        case PPSectionOtherDisplaySettings: {
            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherDisplayClearCache: {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Please Wait", nil)
                                                                                 message:NSLocalizedString(@"Resetting stored URL list", nil)];

                    [self presentViewController:alert animated:YES completion:^{
                        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                            [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                        }];

                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [self dismissViewControllerAnimated:YES completion:^{
                                UIAlertController *successAlert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                                    message:NSLocalizedString(@"The URL list was cleared.", nil)];

                                [self presentViewController:successAlert animated:YES completion:^{
                                    double delayInSeconds = 1.0;
                                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    });
                                }];
                            }];
                        });
                    }];

                    break;
                }

                default: break;
            }
            break;
        }

        case PPSectionDisplaySettings:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionBrowseSettings:
            return NSLocalizedString(@"Browsing", nil);

        case PPSectionDisplaySettings:
            return NSLocalizedString(@"Editing", nil);

        case PPSectionOtherDisplaySettings:
            return NSLocalizedString(@"Clipboard URL detection", nil);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionDisplaySettings:
            return nil;

        case PPSectionBrowseSettings:
            return NSLocalizedString(@"The selected default feed will be shown immediately after starting the app.", nil);

        case PPSectionOtherDisplaySettings:
            return nil;
    }
}

- (void)switchChangedValue:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];
    if (sender == self.compressPostsSwitch) {
        [settings setCompressPosts:self.compressPostsSwitch.on];
    } else if (sender == self.doubleTapToEditSwitch) {
        [settings setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    } else if (sender == self.dimReadPostsSwitch) {
        [settings setDimReadPosts:self.dimReadPostsSwitch.on];

        // We clear the cache since posts now look differently.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PPPinboardMetadataCache sharedCache] removeAllObjects];
        });
    } else if (sender == self.markReadSwitch) {
        [settings setMarkReadPosts:self.markReadSwitch.on];
    } else if (sender == self.hidePrivateLockSwitch) {
        settings.hidePrivateLock = self.hidePrivateLockSwitch.on;

        // We clear the cache since posts now look differently.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PPPinboardMetadataCache sharedCache] removeAllObjects];
        });
    } else if (sender == self.autoCorrectionSwitch) {
        settings.enableAutoCorrect = self.autoCorrectionSwitch.on;
    } else if (sender == self.tagAutoCorrectionSwitch) {
        settings.enableTagAutoCorrect = self.tagAutoCorrectionSwitch.on;
    } else if (sender == self.autoCapitalizationSwitch) {
        settings.enableAutoCapitalize = self.autoCapitalizationSwitch.on;
    } else if (sender == self.alwaysShowAlertSwitch) {
        [settings setAlwaysShowClipboardNotification:self.alwaysShowAlertSwitch.on];
    } else if (sender == self.enableBookmarkPromptSwitch) {
        [settings setTurnOffBookmarkPrompt:!self.enableBookmarkPromptSwitch.on];

        [self.tableView reloadData];
    } else if (sender == self.onlyPromptToAddOnceSwitch) {
        [settings setOnlyPromptToAddOnce:!self.onlyPromptToAddOnceSwitch.on];

        [self.tableView reloadData];
    }

    if (sender == self.compressPostsSwitch) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkCompressSettingUpdate object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    }
}

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[PPSettings sharedSettings] setPrivateByDefault:self.privateByDefaultSwitch.on];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[PPSettings sharedSettings] setReadByDefault:self.readByDefaultSwitch.on];
}

#pragma mark - LHSFontSelecting

- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    [PPSettings sharedSettings].fontName = fontName;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PPPinboardMetadataCache sharedCache] reset];
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    });
}

- (NSString *)fontNameForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPSettings sharedSettings].fontName;
}

- (CGFloat)fontSizeForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPTheme fontSize];
}

@end


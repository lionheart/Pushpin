/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pushpin for Pinboard
 * Copyright (C) 2025 Lionheart Software LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

//
//  PPDisplaySettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import "PPTableViewController.h"
#import "LHSFontSelecting.h"

typedef NS_ENUM(NSInteger, PPDisplaySettingsSectionType) {
    PPSectionDisplaySettings,
    PPSectionBrowseSettings,
    
    // Where we put the clear cache button.
    PPSectionOtherDisplaySettings
};

typedef NS_ENUM(NSInteger, PPEditSettingsRowType) {
    PPEditDefaultToPrivate,
    PPEditDefaultToRead,
    PPEditAutocorrectTextRow,
    PPEditAutocorrectTagsRow,
    PPEditAutocapitalizeRow,
    PPEditAutoMarkAsReadRow,

    // Unused
    PPEditDoubleTapRow,
};

typedef NS_ENUM(NSInteger, PPBrowseSettingsRowType) {
    PPBrowseCompressRow,
    PPBrowseDimReadRow,
    PPBrowseHidePrivateLock,
    PPBrowseFontRow,
    PPBrowseFontSizeRow,
    PPBrowseDefaultFeedRow,
};

typedef NS_ENUM(NSInteger, PPOtherDisplaySettingsRowType) {
    PPOtherTurnOffPrompt,
    PPOtherOnlyPromptToAddBookmarksOnce,
    PPOtherAlwaysShowAlert,
    PPOtherDisplayClearCache
};

typedef NS_ENUM(NSInteger, PPTextExpanderRowType) {
    PPTextExpanderRowSwitch,
    PPTextExpanderRowUpdate,
};

enum : NSInteger {
    PPRowCountBrowse = PPBrowseDefaultFeedRow + 1,
    PPRowCountDisplaySettings = PPEditAutoMarkAsReadRow + 1,
    PPRowCountOtherSettings = PPOtherDisplayClearCache + 1
};

@interface PPDisplaySettingsViewController : PPTableViewController <LHSFontSelecting>

@end

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

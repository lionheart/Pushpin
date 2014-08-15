//
//  PPDisplaySettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import "PPTableViewController.h"

typedef enum : NSInteger {
    PPSectionDisplaySettings,
    PPSectionBrowseSettings,
    
    // Where we put the clear cache button.
    PPSectionOtherDisplaySettings,
    PPSectionTextExpanderSettings
} PPDisplaySettingsSectionType;

typedef enum : NSInteger {
    PPEditDefaultToPrivate,
    PPEditDefaultToRead,
    PPEditAutocorrecTextRow,
    PPEditAutocapitalizeRow,
    PPEditAutoMarkAsReadRow,

    // Unused
    PPEditDoubleTapRow,
} PPEditSettingsRowType;

typedef enum : NSInteger {
    PPBrowseCompressRow,
    PPBrowseDimReadRow,
    PPBrowseFontSizeRow,
    PPBrowseDefaultFeedRow,
} PPBrowseSettingsRowType;

typedef enum : NSInteger {
    PPOtherOnlyPromptToAddBookmarksOnce,
    PPOtherAlwaysShowAlert,
    PPOtherDisplayClearCache
} PPOtherDisplaySettingsRowType;

typedef NS_ENUM(NSInteger, PPTextExpanderRowType) {
    PPTextExpanderRowSwitch,
    PPTextExpanderRowUpdate,
};

enum : NSInteger {
    PPRowCountBrowse = PPBrowseDefaultFeedRow + 1,
    PPRowCountDisplaySettings = PPEditAutoMarkAsReadRow + 1,
    PPRowCountOtherSettings = PPOtherDisplayClearCache + 1
};

@interface PPDisplaySettingsViewController : PPTableViewController <UIAlertViewDelegate, UIActionSheetDelegate>

@end

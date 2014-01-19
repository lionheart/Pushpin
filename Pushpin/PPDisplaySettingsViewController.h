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
    PPBrowseDefaultFeedRow,
} PPBrowseSettingsRowType;

enum : NSInteger {
    PPRowCountBrowse = PPBrowseDefaultFeedRow + 1,
    PPRowCountDisplaySettings = PPEditAutoMarkAsReadRow + 1
};

@interface PPDisplaySettingsViewController : PPTableViewController

@end

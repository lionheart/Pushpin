//
//  PPMobilizerSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPTableViewController.h"
#import <LHSFontSelectionViewController/LHSFontSelecting.h>

#define PPREADER_USE_SLIDERS 1

typedef NS_ENUM(NSInteger, PPReaderSettingsSectionType) {
    PPReaderSettingsSectionMain,
    PPReaderSettingsSectionPreview
};

typedef NS_ENUM(NSInteger, PPReaderSettingsMainRowType) {
    PPReaderSettingsMainRowFontFamily,
    PPReaderSettingsMainRowFontSize,
    PPReaderSettingsMainRowFontLineSpacing,
    PPReaderSettingsMainRowMargin,
    PPReaderSettingsMainRowTextAlignment,
    PPReaderSettingsMainRowDisplayImages,
    PPReaderSettingsMainRowTheme,
    PPReaderSettingsMainRowPreview,

    // Unused
    PPReaderSettingsMainRowHeaderFontFamily,
};

typedef NS_ENUM(NSInteger, PPReaderSettingsPreviewRowType) {
    PPReaderSettingsPreviewRowTheme,
    
    // Unused
    PPReaderSettingsPreviewRowHeaderFontFamily,
};

enum : NSInteger {
    PPReaderSettingsMainRowCount = PPReaderSettingsMainRowDisplayImages + 1,
    PPReaderSettingsPreviewRowCount = 1,
    PPReaderSettingsSectionCount = PPReaderSettingsMainRowMargin + 1
};

@interface PPReaderSettingsViewController : PPTableViewController <LHSFontSelecting, UIActionSheetDelegate>

@end

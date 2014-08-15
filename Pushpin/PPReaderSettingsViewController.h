//
//  PPMobilizerSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPTableViewController.h"
#import <LHSFontSelectionViewController/LHSFontSelecting.h>

typedef NS_ENUM(NSInteger, PPReaderSettingsRowType) {
    PPReaderSettingsRowFontFamily,
    PPReaderSettingsRowFontSize,
    PPReaderSettingsRowFontLineSpacing,
    PPReaderSettingsRowFontImages,
};

enum : NSInteger {
    PPReaderSettingsRowCount = PPReaderSettingsRowFontImages + 1
};

@interface PPReaderSettingsViewController : PPTableViewController <LHSFontSelecting>

@end

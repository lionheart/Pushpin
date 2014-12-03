//
//  PPOfflineSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 11/4/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPTableViewController.h"

typedef NS_ENUM(NSInteger, PPOfflineSettingsRowType) {
    PPOfflineSettingsRowToggle,
    PPOfflineSettingsRowCellular,
    PPOfflineSettingsRowUsage,
    PPOfflineSettingsRowLimit,
};

enum : NSInteger {
    PPOfflineSettingsRowCount = PPOfflineSettingsRowLimit + 1,
};

@interface PPOfflineSettingsViewController : PPTableViewController

@end

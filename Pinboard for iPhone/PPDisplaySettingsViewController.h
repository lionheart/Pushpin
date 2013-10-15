//
//  PPDisplaySettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import "PPTableViewController.h"
#import "PPSwitch.h"

@interface PPDisplaySettingsViewController : PPTableViewController

@property (nonatomic, retain) UISwitch *dimReadPostsSwitch;
@property (nonatomic, retain) UISwitch *compressPostsSwitch;
@property (nonatomic, retain) UISwitch *doubleTapToEditSwitch;
@property (nonatomic, retain) UISwitch *markReadSwitch;
@property (nonatomic, retain) UISwitch *autoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *autoCapitalizationSwitch;

- (void)switchChangedValue:(id)sender;

@end

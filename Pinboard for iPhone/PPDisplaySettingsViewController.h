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

@property (nonatomic, retain) PPSwitch *dimReadPostsSwitch;
@property (nonatomic, retain) PPSwitch *compressPostsSwitch;
@property (nonatomic, retain) PPSwitch *doubleTapToEditSwitch;

- (void)switchChangedValue:(id)sender;

@end

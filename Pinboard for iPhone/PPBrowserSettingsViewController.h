//
//  PPBrowserSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPTableViewController.h"

@interface PPBrowserSettingsViewController : PPTableViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) UIActionSheet *browserActionSheet;
@property (nonatomic, retain) UIAlertView *installChromeAlertView;
@property (nonatomic, retain) UIAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) UISwitch *openLinksInAppSwitch;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

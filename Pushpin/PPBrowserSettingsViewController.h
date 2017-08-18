//
//  PPBrowserSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPTableViewController.h"

@interface PPBrowserSettingsViewController : PPTableViewController

@property (nonatomic, retain) UIAlertController *browserActionSheet;
@property (nonatomic, retain) UIAlertController *installChromeAlertView;
@property (nonatomic, retain) UIAlertController *installICabMobileAlertView;
@property (nonatomic, retain) UISwitch *openLinksInAppSwitch;
@property (nonatomic, retain) UISwitch *useSafariViewControllerSwitch;
@property (nonatomic, strong) UIAlertController *actionSheet;

@end

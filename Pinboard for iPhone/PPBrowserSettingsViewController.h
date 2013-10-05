//
//  PPBrowserSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPTableViewController.h"
#import "PPSwitch.h"
#import "RDActionSheet.h"

@interface PPBrowserSettingsViewController : PPTableViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) UIActionSheet *browserActionSheet;
@property (nonatomic, retain) UIAlertView *installChromeAlertView;
@property (nonatomic, retain) UIAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) UISwitch *openLinksInAppSwitch;
@property (nonatomic, strong) id actionSheet;

@end

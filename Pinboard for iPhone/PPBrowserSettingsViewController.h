//
//  PPBrowserSettingsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import "PPTableViewController.h"
#import "RDActionSheet.h"
#import "WCAlertView.h"
#import "PPSwitch.h"

@interface PPBrowserSettingsViewController : PPTableViewController <RDActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) RDActionSheet *browserActionSheet;
@property (nonatomic, retain) WCAlertView *installChromeAlertView;
@property (nonatomic, retain) WCAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) PPSwitch *openLinksInAppSwitch;

@end

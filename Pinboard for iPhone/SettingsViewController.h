//
//  SettingsViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "PPSwitch.h"
#import "RDActionSheet.h"
#import "WCAlertView.h"
#import "PPLoadingView.h"

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate, RDActionSheetDelegate>

@property (nonatomic, retain) WCAlertView *installChromeAlertView;
@property (nonatomic, retain) WCAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) WCAlertView *instapaperVerificationAlertView;
@property (nonatomic, retain) WCAlertView *readabilityVerificationAlertView;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, retain) WCAlertView *instapaperAlertView;
@property (nonatomic, retain) WCAlertView *readabilityAlertView;
@property (nonatomic, retain) WCAlertView *logOutAlertView;
@property (nonatomic, retain) RDActionSheet *browserActionSheet;
@property (nonatomic, retain) RDActionSheet *supportActionSheet;
@property (nonatomic, retain) RDActionSheet *readLaterActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;
@property (nonatomic, retain) PPSwitch *privateByDefaultSwitch;
@property (nonatomic, retain) PPSwitch *readByDefaultSwitch;
@property (nonatomic, retain) NSMutableArray *availableBrowsers;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)showAboutPage;
- (void)closeAboutPage;

@end

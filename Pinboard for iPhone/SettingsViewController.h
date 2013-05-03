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
#import "TTAlertView.h"

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate, RDActionSheetDelegate>

@property (nonatomic, retain) UIAlertView *installChromeAlertView;
@property (nonatomic, retain) UIAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) UIAlertView *instapaperVerificationAlertView;
@property (nonatomic, retain) UIAlertView *readabilityVerificationAlertView;
@property (nonatomic, retain) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, retain) UIAlertView *instapaperAlertView;
@property (nonatomic, retain) UIAlertView *readabilityAlertView;
@property (nonatomic, retain) TTAlertView *logOutAlertView;
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

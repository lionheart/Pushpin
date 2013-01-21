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

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, retain) UIAlertView *installChromeAlertView;
@property (nonatomic, retain) UIAlertView *installiCabMobileAlertView;
@property (nonatomic, retain) UIAlertView *instapaperVerificationAlertView;
@property (nonatomic, retain) UIAlertView *readabilityVerificationAlertView;
@property (nonatomic, retain) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, retain) UIAlertView *instapaperAlertView;
@property (nonatomic, retain) UIAlertView *readabilityAlertView;
@property (nonatomic, retain) UIAlertView *logOutAlertView;
@property (nonatomic, retain) UIActionSheet *browserActionSheet;
@property (nonatomic, retain) UIActionSheet *supportActionSheet;
@property (nonatomic, retain) UIActionSheet *readLaterActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;
@property (nonatomic, retain) UISwitch *privateByDefaultSwitch;
@property (nonatomic, retain) UISwitch *readByDefaultSwitch;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)showAboutPage;
- (void)closeAboutPage;

@end

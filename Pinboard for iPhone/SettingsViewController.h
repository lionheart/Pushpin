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
#import "PPTableViewController.h"

@interface SettingsViewController : PPTableViewController <UIAlertViewDelegate, UIWebViewDelegate, UITextFieldDelegate, RDActionSheetDelegate>

@property (nonatomic, retain) WCAlertView *instapaperVerificationAlertView;
@property (nonatomic, retain) WCAlertView *readabilityVerificationAlertView;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, retain) WCAlertView *instapaperAlertView;
@property (nonatomic, retain) WCAlertView *readabilityAlertView;
@property (nonatomic, retain) WCAlertView *logOutAlertView;

@property (nonatomic, retain) RDActionSheet *supportActionSheet;
@property (nonatomic, retain) RDActionSheet *readLaterActionSheet;
@property (nonatomic, strong) RDActionSheet *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;
@property (nonatomic, retain) PPSwitch *privateByDefaultSwitch;
@property (nonatomic, retain) PPSwitch *readByDefaultSwitch;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)showAboutPage;
- (void)closeAboutPage;
- (void)followScreenName:(NSString *)screenName;

@end

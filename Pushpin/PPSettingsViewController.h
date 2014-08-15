//
//  SettingsViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import UIKit;
@import MessageUI;
@import MessageUI.MFMessageComposeViewController;

#import "PPAppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"
#import "PocketAPI.h"

typedef enum : NSInteger {
    PPSectionMainSettings,
    PPSectionOtherSettings
} PPSectionType;

typedef enum : NSInteger {
    PPMainReadLater,
    PPMainReader,
    PPMainAdvanced,
    PPMainBrowser
} PPMainSettingsRowType;

typedef enum : NSInteger {
    PPOtherRatePushpin,
    PPOtherFollow,
    PPOtherFeedback,
    PPOtherLogout,

    // Unused
    PPOtherClearCache
} PPOtherSettingsRowType;

enum : NSInteger {
    PPRowCountMain = PPMainBrowser + 1,
    PPRowCountOther = PPOtherLogout + 1
};

@interface PPSettingsViewController : PPTableViewController <UIAlertViewDelegate, UIActionSheetDelegate, UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UIAlertView *instapaperVerificationAlertView;
@property (nonatomic, retain) UIAlertView *readabilityVerificationAlertView;
@property (nonatomic, strong) UIAlertView *pocketVerificationAlertView;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, retain) UIAlertView *instapaperAlertView;
@property (nonatomic, retain) UIAlertView *readabilityAlertView;
@property (nonatomic, retain) UIAlertView *logOutAlertView;

@property (nonatomic, retain) UIActionSheet *supportActionSheet;
@property (nonatomic, retain) UIActionSheet *readLaterActionSheet;
@property (nonatomic, strong) UIActionSheet *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;

@property (nonatomic, strong) id actionSheet;

- (void)showAboutPage;
- (void)closeAboutPage;

- (void)pocketFinishedLogin;
- (void)pocketStartedLogin;

@end

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

@interface PPSettingsViewController : PPTableViewController <UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UIAlertController *instapaperVerificationAlertView;
@property (nonatomic, retain) UIAlertController *readabilityVerificationAlertView;
@property (nonatomic, strong) UIAlertController *pocketVerificationAlertView;
@property (nonatomic, retain) UIAlertController *instapaperAlertView;
@property (nonatomic, retain) UIAlertController *readabilityAlertView;
@property (nonatomic, retain) UIAlertController *logOutAlertView;

@property (nonatomic, retain) UIAlertController *supportActionSheet;
@property (nonatomic, retain) UIAlertController *readLaterActionSheet;
@property (nonatomic, strong) UIAlertController *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;

@property (nonatomic, strong) id actionSheet;

- (void)showAboutPage;
- (void)closeAboutPage;

- (void)pocketFinishedLogin;
- (void)pocketStartedLogin;

@end

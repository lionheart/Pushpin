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

typedef NS_ENUM(NSInteger, PPSectionType) {
    PPSectionMainSettings,
    PPSectionOtherSettings,
    PPSectionCacheSettings
};

typedef NS_ENUM(NSInteger, PPMainSettingsRowType) {
    PPMainReadLater,
    PPMainReader,
    PPMainOffline,
    PPMainBrowser,
    PPMainAdvanced,
};

typedef NS_ENUM(NSInteger, PPOtherSettingsRowType) {
    PPOtherRatePushpin,
    PPOtherFollow,
    PPOtherFeedback,
    PPOtherLogout,
};

enum : NSInteger {
    PPRowCountMain = PPMainAdvanced + 1,
    PPRowCountOther = PPOtherLogout + 1,
    PPRowCountCache = 1,
};

@interface PPSettingsViewController : PPTableViewController <UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UIAlertController *supportActionSheet;
@property (nonatomic, retain) UIAlertController *readLaterActionSheet;
@property (nonatomic, strong) UIAlertController *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;

- (void)showAboutPage;
- (void)closeAboutPage;

- (void)pocketFinishedLogin;
- (void)pocketStartedLogin;

@end

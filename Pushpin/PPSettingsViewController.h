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

@protocol HSBeaconDelegate;

#import "PPAppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"

typedef NS_ENUM(NSInteger, PPSectionType) {
    PPSectionMainSettings,
    PPSectionOtherSettings,
    PPSectionCacheSettings
};

typedef NS_ENUM(NSInteger, PPMainSettingsRowType) {
    PPMainReader,
    PPMainOffline,
    PPMainBrowser,
    PPMainAdvanced,
};

typedef NS_ENUM(NSInteger, PPOtherSettingsRowType) {
    PPOtherRatePushpin,
    PPOtherTipJar,
    PPOtherFollow,
    PPOtherFeedback,
    PPOtherLogout,
};

enum : NSInteger {
    PPRowCountMain = PPMainAdvanced + 1,
    PPRowCountOther = PPOtherLogout + 1,
    PPRowCountCache = 1,
};

@interface PPSettingsViewController : PPTableViewController <UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate, HSBeaconDelegate>

@property (nonatomic, strong) UIAlertController *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;

- (void)showAboutPage;

@end

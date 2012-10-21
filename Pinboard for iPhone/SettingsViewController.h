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

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UIAlertView *logOutAlertView;
@property (nonatomic, retain) UIActionSheet *browserActionSheet;
@property (nonatomic, retain) UIActionSheet *supportActionSheet;

- (void)showAboutPage;
- (void)closeAboutPage;

@end

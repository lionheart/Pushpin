//
//  SettingsViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate, UIWebViewDelegate>

- (void)showAboutPage;
- (void)closeAboutPage;

@end

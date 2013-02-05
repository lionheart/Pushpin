//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import <UIKit/UIKit.h>

@interface FeedListViewController : UITableViewController

@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic, retain) UINavigationController *navigationController;

- (void)connectionStatusDidChange:(NSNotification *)notification;

@end

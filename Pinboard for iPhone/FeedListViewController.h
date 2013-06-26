//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import <UIKit/UIKit.h>
#import "PPTableViewController.h"

enum PINBOARD_FEED_ITEMS {
    PinboardFeedAllBookmarks,
    PinboardFeedPrivateBookmarks,
    PinboardFeedPublicBookmarks,
    PinboardFeedUnreadBookmarks,
    PinboardFeedUntaggedBookmarks,
    PinboardFeedStarredBookmarks
};

@interface FeedListViewController : PPTableViewController

@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSMutableArray *bookmarkCounts;

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback;
- (void)connectionStatusDidChange:(NSNotification *)notification;
- (void)openSettings;
- (void)openTags;
- (void)dismissViewController;

- (void)hideNetworkDependentFeeds;
- (void)showAllFeeds;

@end

//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import <UIKit/UIKit.h>

enum PINBOARD_FEED_ITEMS {
    PinboardFeedAllBookmarks,
    PinboardFeedPrivateBookmarks,
    PinboardFeedPublicBookmarks,
    PinboardFeedUnreadBookmarks,
    PinboardFeedUntaggedBookmarks,
    PinboardFeedStarredBookmarks
};

@interface FeedListViewController : UITableViewController

@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSMutableArray *bookmarkCounts;
@property (nonatomic) BOOL timerPaused;

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback;
- (void)checkForPostUpdates;
- (void)connectionStatusDidChange:(NSNotification *)notification;
- (void)openSettings;
- (void)openTags;

@end

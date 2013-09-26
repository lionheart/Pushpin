//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import <UIKit/UIKit.h>
#import "PPTableViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PinboardFeedDataSource.h"

enum PINBOARD_FEED_ITEMS {
    PinboardFeedAllBookmarks,
    PinboardFeedPrivateBookmarks,
    PinboardFeedPublicBookmarks,
    PinboardFeedUnreadBookmarks,
    PinboardFeedUntaggedBookmarks,
    PinboardFeedStarredBookmarks
};

@interface FeedListViewController : PPTableViewController <ModalDelegate> {
    NSString *postViewTitle;
}

@property (nonatomic, strong) NSObject <GenericPostDataSource> *postDataSource;
@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic, strong) UIBarButtonItem *notesBarButtonItem;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSMutableArray *bookmarkCounts;

@property (nonatomic) CGFloat textSize;
@property (nonatomic) CGFloat detailTextSize;
@property (nonatomic) CGFloat rowHeight;

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback;
- (void)connectionStatusDidChange:(NSNotification *)notification;
- (void)openNotes;
- (void)openSettings;
- (void)openTags;
- (void)dismissViewController;

- (void)hideNetworkDependentFeeds;
- (void)showAllFeeds;

- (void)preferredContentSizeChanged:(NSNotification *)aNotification;

@end

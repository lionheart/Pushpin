//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

@import UIKit;

#import "PPTableViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PinboardFeedDataSource.h"

typedef NS_ENUM(NSInteger, FeedListToolbarOrientationType) {
    FeedListToolbarOrientationRight,
    FeedListToolbarOrientationLeft,
    FeedListToolbarOrientationCenter,
};

@interface FeedListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIToolbarDelegate, PPTitleButtonDelegate> {
    NSString *postViewTitle;
}

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSObject <GenericPostDataSource> *postDataSource;
@property (nonatomic, strong) UIBarButtonItem *notesBarButtonItem;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSMutableArray *bookmarkCounts;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) CGFloat textSize;
@property (nonatomic) CGFloat detailTextSize;
@property (nonatomic) CGFloat rowHeight;

- (void)dismissViewController;

- (void)preferredContentSizeChanged:(NSNotification *)aNotification;

@end

//
//  PPDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 3/25/14.
//
//

#import <UIKit/UIKit.h>

static dispatch_queue_t PPBookmarkUpdateQueue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.BookmarkUpdateQueue", 0);
    });
    return queue;
}

static dispatch_queue_t PPBookmarkReloadQueue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.BookmarkReloadQueue", 0);
    });
    return queue;
}

@protocol PPDataSource <NSObject>

- (NSInteger)numberOfPosts;
- (BOOL)searchSupported;

- (NSAttributedString *)titleForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)descriptionForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)linkForPostAtIndex:(NSInteger)index;

- (CGFloat)heightForPostAtIndex:(NSInteger)index;
- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index;

- (BOOL)isPostAtIndexPrivate:(NSInteger)index;
- (BOOL)supportsTagDrilldown;

- (NSDictionary *)postAtIndex:(NSInteger)index;
- (NSString *)urlForPostAtIndex:(NSInteger)index;

// Retrieves bookmarks from remote server and inserts them into database.
- (void)syncBookmarksWithCompletion:(void (^)(NSError *error))completion
                           progress:(void (^)(NSInteger, NSInteger))progress;

// Refreshes local cache.
- (void)reloadBookmarksWithCompletion:(void (^)(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete, NSError *error))completion
                               cancel:(BOOL (^)())cancel
                                width:(CGFloat)width;

- (PPPostActionType)actionsForPost:(NSDictionary *)post;

@optional

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic) NSInteger totalNumberOfPosts;

- (BOOL)isPostAtIndexStarred:(NSInteger)index;

- (NSString *)searchPlaceholder;

- (NSArray *)badgesForPostAtIndex:(NSInteger)index;

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index callback:(void (^)())callback;
- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index;
- (id <PPDataSource>)searchDataSource;
- (void)filterWithQuery:(NSString *)query;
- (void)addDataSource:(void (^)())callback;
- (void)removeDataSource:(void (^)())callback;

// A data source may alternatively provide a UIViewController to push
- (NSInteger)sourceForPostAtIndex:(NSInteger)index;
- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index;
- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback;

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index;
- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback;
- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(NSArray *, NSArray *, NSArray *))callback;

/**
 * Called when post at a specific index path is called
 */
- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback;

/**
 * The navigation bar color.
 */
- (UIColor *)barTintColor;

/**
 * The title to display.
 */
- (NSString *)title;

/**
 * The title view to display (overrides title).
 */
- (UIView *)titleView;

/**
 * Set up the title view with a specific object as the delegate
 */
- (UIView *)titleViewWithDelegate:(id<PPTitleButtonDelegate>)delegate;

@end

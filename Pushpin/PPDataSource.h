//
//  PPDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 3/25/14.
//
//

#import <UIKit/UIKit.h>

@protocol PPDataSource <NSObject>

- (PPPostActionType)actionsForPost:(NSDictionary *)post;
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

@optional

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic) NSInteger totalNumberOfPosts;

- (BOOL)isPostAtIndexStarred:(NSInteger)index;

- (NSString *)searchPlaceholder;

- (void)updateBookmarksWithSuccess:(void (^)())success
                           failure:(void (^)(NSError *))failure
                          progress:(void (^)(NSInteger, NSInteger))progress
                           options:(NSDictionary *)options;

- (void)bookmarksWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success
                     failure:(void (^)(NSError *))failure
                       width:(CGFloat)width;

- (void)bookmarksWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success
                     failure:(void (^)(NSError *))failure
                      cancel:(void (^)(BOOL *))cancel
                       width:(CGFloat)width;

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

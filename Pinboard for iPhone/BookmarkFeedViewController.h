//
//  BookmarkFeedViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 12/8/12.
//
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface BookmarkFeedViewController : UITableViewController <UIWebViewDelegate, TTTAttributedLabelDelegate> {
    NSInteger failureCount;
}

@property (nonatomic, retain) UIViewController *bookmarkDetailViewController;
@property (nonatomic, retain) NSDictionary *bookmark;
@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *heights;
@property (nonatomic, retain) NSDateFormatter *date_formatter;
@property (nonatomic, retain) NSURL *sourceURL;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic) BOOL shouldShowContextMenu;

+ (NSNumber *)heightForBookmark:(NSDictionary *)bookmark;
+ (NSMutableAttributedString *)attributedStringForBookmark:(NSDictionary *)bookmark;
- (id)initWithURL:(NSString *)aURL;

- (void)processBookmarks;
- (void)copyURL:(id)sender;
- (void)copyTitle:(id)sender;
- (void)readLater:(id)sender;
- (void)share:(id)sender;
- (void)copyToMine:(id)sender;
- (void)handleSwipeRight:(UIGestureRecognizer *)gestureRecognizer;

@end

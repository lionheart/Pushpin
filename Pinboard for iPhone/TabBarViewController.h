//
//  TabBarViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/30/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class BookmarkViewController;

@interface TabBarViewController : UITabBarController <UITabBarControllerDelegate, ModalDelegate, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    BOOL _sessionChecked;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *bookmarkURL;
@property (nonatomic, retain) NSString *bookmarkTitle;
@property (nonatomic, retain) NSTimer *bookmarkRefreshTimer;
@property (nonatomic, retain) NSTimer *reloadDataTimer;
@property (nonatomic, retain) BookmarkViewController *allBookmarkViewController;

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)promptUserToAddBookmark;
- (void)pauseRefreshTimer;
- (void)resumeRefreshTimer;
- (void)executeTimer;

@end

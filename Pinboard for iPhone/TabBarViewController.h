//
//  TabBarViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/30/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface TabBarViewController : UITabBarController <UITabBarControllerDelegate, ModalDelegate, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    BOOL _sessionChecked;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *bookmarkURL;
@property (nonatomic, retain) NSString *bookmarkTitle;
@property (nonatomic, retain) NSTimer *bookmarkRefreshTimer;

- (void)showAddBookmarkViewController;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title andTags:(NSString *)someTags;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title andTags:(NSString *)someTags andDescription:(NSString *)aDescription;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle andTags:(NSString *)someTags andDescription:(NSString *)aDescription andPrivate:(NSNumber *)isPrivate andRead:(NSNumber *)isRead;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate;
- (void)promptUserToAddBookmark;
- (void)pauseRefreshTimer;
- (void)resumeRefreshTimer;
- (void)executeTimer;

@end

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

@interface TabBarViewController : UITabBarController <UITabBarControllerDelegate, ModalDelegate, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, retain) UIAlertView *addBookmarkFromClipboardAlertView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *bookmarkURL;
@property (nonatomic, retain) NSString *bookmarkTitle;
@property (nonatomic, retain) NSTimer *bookmarkRefreshTimer;
@property (nonatomic, retain) NSTimer *reloadDataTimer;
@property (nonatomic, retain) BookmarkViewController *allBookmarkViewController;

- (void)closeModal:(UIViewController *)sender;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)promptUserToAddBookmark;

@end

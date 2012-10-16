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
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *bookmarkURL;
@property (nonatomic, retain) NSString *bookmarkTitle;
@property (nonatomic, retain) NSTimer *bookmarkRefreshTimer;

- (void)showAddBookmarkViewController;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)url andTitle:(NSString *)title;
- (void)promptUserToAddBookmark;

@end

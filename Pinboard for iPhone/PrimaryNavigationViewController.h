//
//  PrimaryNavigationViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/3/13.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface PrimaryNavigationViewController : UINavigationController <ModalDelegate, UIAlertViewDelegate, UIWebViewDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, retain) UIAlertView *addBookmarkFromClipboardAlertView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *bookmarkURL;
@property (nonatomic, retain) NSString *bookmarkTitle;
@property (nonatomic, retain) NSTimer *bookmarkRefreshTimer;
@property (nonatomic, retain) NSTimer *reloadDataTimer;

- (void)closeModal:(UIViewController *)sender;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)promptUserToAddBookmark;

@end

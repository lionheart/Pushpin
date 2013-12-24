//
//  PPWebViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "AppDelegate.h"
#import "PPToolbar.h"

@interface PPWebViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, ModalDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) UIView *statusBarBackgroundView;
@property (nonatomic, strong) UIView *webViewContainer;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;

@property (nonatomic, strong) UIView *showToolbarAndTitleBarHiddenView;
@property (nonatomic, strong) UIView *toolbarBackgroundView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *markAsReadButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *viewMobilizeButton;
@property (nonatomic, strong) UIButton *viewRawButton;
@property (nonatomic, strong) UIActivityIndicatorView *bottomActivityIndicator;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *bottomTapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *backButtonLongPressGestureRecognizer;

@property (nonatomic) BOOL actionSheetIsVisible;
@property (nonatomic) BOOL alreadyLoaded;
@property (nonatomic) BOOL isFullscreen;
@property (nonatomic) BOOL selectedActionSheetIsVisible;
@property (nonatomic) BOOL shouldMobilize;
@property (nonatomic) BOOL stopped;
@property (nonatomic) BOOL prefersStatusBarHidden;
@property (nonatomic) UIStatusBarStyle preferredStatusBarStyle;

@property (nonatomic) CGFloat yOffsetToStartShowingTitleView;
@property (nonatomic) NSInteger numberOfRequests;
@property (nonatomic) NSInteger numberOfRequestsCompleted;
@property (nonatomic) NSInteger numberOfRequestsInProgress;

@property (nonatomic, strong) NSURL *urlToOpenExternally;
@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, strong) NSLayoutConstraint *topLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *titleHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *toolbarConstraint;
@property (nonatomic, strong) NSMutableArray *navigationHistory;
@property (nonatomic, strong) NSDictionary *selectedLink;
@property (nonatomic, strong) UIActionSheet *backActionSheet;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIActionSheet *selectedActionSheet;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) UIAlertView *openLinkExternallyAlertView;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) NSTimer *webViewTimeoutTimer;

- (void)showToolbarAnimated:(BOOL)animated;
- (void)hideToolbarAnimated:(BOOL)animated;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)actionButtonTouchUp:(id)sender;
- (void)backButtonTouchUp:(id)sender;
- (void)copyURL;
- (void)copyURL:(NSURL *)url;
- (void)emailURL;
- (void)showEditViewController;
- (void)showAddViewController;
- (void)showAddViewController:(NSDictionary *)data;
- (BOOL)isMobilized;
- (BOOL)isURLStringMobilized:(NSString *)url;
- (void)toggleMobilizer;
- (void)enableOrDisableButtons;
- (void)sendToReadLater;
- (void)sendToReadLater:(NSNumber *)service;
- (void)loadURL;
- (void)stopLoading;
- (NSURL *)url;
- (NSString *)urlStringForDemobilizedURL:(NSURL *)url;
- (NSInteger)numberOfRequestsInProgress;
- (void)webViewLoadTimedOut;
- (void)updateInterfaceWithComputedWebPageBackgroundColor;

- (BOOL)canMobilizeURL:(NSURL *)url;
- (BOOL)canMobilizeCurrentURL;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;
+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url;

@end

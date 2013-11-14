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

@interface PPWebViewController : UIViewController <UIActionSheetDelegate, UIActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, ModalDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;

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
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic) NSInteger numberOfRequestsInProgress;
@property (nonatomic) BOOL alreadyLoaded;
@property (nonatomic) BOOL stopped;
@property (nonatomic) BOOL shouldMobilize;
@property (nonatomic) CGFloat lastContentOffset;
@property (nonatomic) BOOL actionSheetIsVisible;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic) BOOL isFullscreen;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic) CGRect toolbarFrame;
@property (nonatomic) NSInteger numberOfRequestsCompleted;
@property (nonatomic) NSInteger numberOfRequests;
@property (nonatomic, strong) NSDictionary *selectedLink;
@property (nonatomic) BOOL selectedActionSheetIsVisible;
@property (nonatomic, strong) UIActionSheet *selectedActionSheet;
@property (nonatomic, retain) NSMutableArray *navigationHistory;

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)singleTapInWebview;
- (void)socialActionButtonTouchUp:(id)sender;
- (void)actionButtonTouchUp:(id)sender;
- (void)backButtonTouchUp:(id)sender;
- (void)forwardButtonTouchUp:(id)sender;
- (void)copyURL;
- (void)copyURL:(NSURL *)url;
- (void)emailURL;
- (void)showEditViewController;
- (void)showAddViewController;
- (void)showAddViewController:(NSDictionary *)data;
- (void)popViewController;
- (BOOL)isMobilized;
- (BOOL)isURLStringMobilized:(NSString *)url;
- (void)toggleMobilizer;
- (void)enableOrDisableButtons;
- (void)sendToReadLater;
- (void)sendToReadLater:(NSNumber *)service;
- (void)loadURL;
- (void)stopLoading;
- (BOOL)isWebViewExpanded;
- (CGPoint)adjustedPuckPositionWithPoint:(CGPoint)point;
- (void)toggleFullScreen;
- (void)setFullscreen:(BOOL)fullscreen;
- (void)disableFullscreen:(id)sender;
- (NSURL *)url;
- (NSString *)urlStringForDemobilizedURL:(NSURL *)url;
- (void)expandWebViewToFullScreen;
- (NSInteger)numberOfRequestsInProgress;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;
+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url;

@end

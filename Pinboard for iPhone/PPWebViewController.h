//
//  PPWebViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "RDActionSheet.h"
#import "AppDelegate.h"
#import "PPToolbar.h"

@interface PPWebViewController : UIViewController <RDActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, ModalDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *readerBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *socialBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *readerButton;
@property (nonatomic, strong) UIButton *enterReaderModeButton;
@property (nonatomic, strong) UIButton *exitReaderModeButton;
@property (nonatomic, strong) CALayer *fullScreenImageLayer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerForReaderMode;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerForNormalMode;
@property (nonatomic, strong) NSTimer *stoppedScrollingTimer;
@property (nonatomic, strong) PPToolbar *toolbar;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic) NSInteger numberOfRequestsInProgress;
@property (nonatomic) BOOL alreadyLoaded;
@property (nonatomic) BOOL stopped;
@property (nonatomic) CGFloat lastContentOffset;

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)singleTapInWebview;
- (void)socialActionButtonTouchUp:(id)sender;
- (void)actionButtonTouchUp:(id)sender;
- (void)backButtonTouchUp:(id)sender;
- (void)forwardButtonTouchUp:(id)sender;
- (void)copyURL;
- (void)emailURL;
- (void)showEditViewController;
- (void)showAddViewController;
- (void)popViewController;
- (BOOL)isMobilized;
- (BOOL)isURLStringMobilized:(NSString *)url;
- (void)toggleMobilizer;
- (void)enableOrDisableButtons;
- (void)sendToReadLater;
- (void)loadURL;
- (void)stopLoading;
- (BOOL)isWebViewExpanded;
- (CGPoint)adjustedPuckPositionWithPoint:(CGPoint)point;
- (void)toggleFullScreen;
- (NSURL *)url;
- (NSString *)urlStringForDemobilizedURL:(NSURL *)url;
- (void)expandWebViewToFullScreen;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;
+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url;

@end

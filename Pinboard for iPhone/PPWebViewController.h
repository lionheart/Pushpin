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

@interface PPWebViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, ModalDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *readerBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *socialBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *readerButton;
@property (nonatomic, strong) UIButton *enterReaderModeButton;
@property (nonatomic, strong) UIButton *exitReaderModeButton;
@property (nonatomic, strong) CALayer *fullScreenImageLayer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerForReaderMode;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerForNormalMode;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureForFullscreenMode;
@property (nonatomic, strong) IBOutlet UIView *tapView;
@property (nonatomic, strong) NSTimer *stoppedScrollingTimer;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic) NSInteger numberOfRequestsInProgress;
@property (nonatomic) BOOL alreadyLoaded;
@property (nonatomic) BOOL stopped;
@property (nonatomic) BOOL shouldMobilize;
@property (nonatomic) CGFloat lastContentOffset;
@property (nonatomic) BOOL actionSheetIsVisible;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic) CGRect toolbarFrame;

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)singleTapInWebview;
- (void)socialActionButtonTouchUp:(id)sender;
- (IBAction)actionButtonTouchUp:(id)sender;
- (IBAction)backButtonTouchUp:(id)sender;
- (IBAction)forwardButtonTouchUp:(id)sender;
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
- (IBAction)stopLoading:(id)sender;
- (BOOL)isWebViewExpanded;
- (CGPoint)adjustedPuckPositionWithPoint:(CGPoint)point;
- (void)toggleFullScreen;
- (void)setFullscreen:(BOOL)fullscreen;
- (void)disableFullscreen:(id)sender;
- (NSURL *)url;
- (NSString *)urlStringForDemobilizedURL:(NSURL *)url;
- (void)expandWebViewToFullScreen;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;
+ (PPWebViewController *)mobilizedWebViewControllerWithURL:(NSString *)url;

@end

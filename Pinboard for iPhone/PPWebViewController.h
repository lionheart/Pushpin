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

@interface PPWebViewController : UIViewController <RDActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, ModalDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *readerBarButtonItem;

- (void)actionButtonTouchUp:(id)sender;
- (void)backButtonTouchUp:(id)sender;
- (void)forwardButtonTouchUp:(id)sender;
- (void)copyURL;
- (void)emailURL;
- (void)showEditViewController;
- (void)showAddViewController;
- (BOOL)isMobilized;
- (void)toggleMobilizer;
- (NSURL *)url;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;

@end

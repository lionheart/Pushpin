#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"
#import "HSBeaconConversation.h"
#import "HSBeaconConversationDetailsWebView.h"
#import "HSCardStackViewController.h"

@protocol HSBeaconConversationDetailsControllerDelegate

- (void)conversationUpdated:(HSBeaconConversation *)conversation;

- (void)conversationDismissed:(HSBeaconConversation *)conversation;

@end

@interface HSBeaconConversationDetailsController : UIViewController <HSCardStackEmbeddable>

@property (nonatomic) HSBeaconConversation *conversation;

@property (nonatomic) HSBeaconContext *beaconContext;

@property (weak, nonatomic) id<HSBeaconConversationDetailsControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet HSBeaconConversationDetailsWebView *webView;

@property (weak, nonatomic) IBOutlet UIButton *replyButton;

@property (weak, nonatomic) IBOutlet UIView *loadingContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loadingContainerHeight;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

+ (instancetype)instantiateViewController;

@end

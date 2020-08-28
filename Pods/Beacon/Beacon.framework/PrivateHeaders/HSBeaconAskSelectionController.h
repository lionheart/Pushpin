#import <UIKit/UIKit.h>
#import "HSViewController.h"
#import "HSBeaconContext.h"
#import "HSBeaconPreviousMessagesEnabler.h"
#import "HSBeaconPreviousMessagesPresenter.h"

@class HSBeaconAgentsView;
@class HSBeaconAskSelectionCardView;
@class HSBeaconPreviousConversationsButton;

@interface HSBeaconAskSelectionController: HSViewController <HSBeaconPreviousMessagesEnabler, HSBeaconPreviousMessagesPresenter>

@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property (weak, nonatomic) IBOutlet UIView *agentsViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agentsViewContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet HSBeaconAgentsView *agentsView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageSubtitle;
@property (weak, nonatomic) IBOutlet HSBeaconAskSelectionCardView *emailCardView;
@property (weak, nonatomic) IBOutlet HSBeaconAskSelectionCardView *chatCardView;
@property (weak, nonatomic) IBOutlet HSBeaconPreviousConversationsButton *previousConversationsButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

@property (nonatomic, assign) BOOL routeToChat;

- (void)enablePreviousMessages;
- (void)showPreviousMessages;
- (void)presentChat;

@end

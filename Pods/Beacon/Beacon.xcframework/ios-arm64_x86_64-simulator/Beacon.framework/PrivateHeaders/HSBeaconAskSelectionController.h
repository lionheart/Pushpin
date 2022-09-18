#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>
#import <Beacon/HSBeaconPreviousMessagesEnabler.h>
#import <Beacon/HSBeaconPreviousMessagesPresenter.h>
#import <Beacon/HSBeaconRoutingFulfilling.h>

@class HSBeaconContext, HSBeaconAgentsView, HSBeaconAskSelectionCardView, HSBeaconPreviousConversationsButton;

@interface HSBeaconAskSelectionController: HSViewController <HSBeaconPreviousMessagesEnabler, HSBeaconPreviousMessagesPresenter, HSBeaconRoutingFulfilling>

@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property (weak, nonatomic) IBOutlet UIView *agentsViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agentsViewContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet HSBeaconAgentsView *agentsView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageSubtitle;
@property (weak, nonatomic) IBOutlet HSBeaconAskSelectionCardView *emailCardView;
@property (weak, nonatomic) IBOutlet HSBeaconAskSelectionCardView *chatCardView;
@property (weak, nonatomic) IBOutlet HSBeaconPreviousConversationsButton *previousConversationsButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailCardCentered;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *emailCardLeadingAndTrailing;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *emailCardCompactHeightLeadingAndTrailing;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

/// If set to to YES then subviews will only be transitioned after calling `animateForAppearance`
/// Defaults to NO
@property (nonatomic, assign) BOOL shouldDelayTransitionForAppearance;

- (void)enablePreviousMessages;
- (void)animateForAppearance;
- (void)resetForm;

@end

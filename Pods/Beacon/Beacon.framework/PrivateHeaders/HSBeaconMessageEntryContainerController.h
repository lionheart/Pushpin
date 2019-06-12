#import <UIKit/UIKit.h>

#import "HSBeaconAgentsView.h"
#import "HSBeaconContext.h"
#import "HSBeaconCustomFieldsEntryController.h"
#import "HSBeaconErrorView.h"
#import "HSBeaconSubmitButton.h"

@class HSBeaconMessageEntryContainerController;

@protocol HSBeaconMessageEntryContainerControllerDelegate

- (void)messageEntryComplete:(HSBeaconMessageEntryContainerController *)controller;
- (void)messageCountRefreshRequired:(HSBeaconMessageEntryContainerController *)controller;
- (void)showPreviousMessages:(HSBeaconMessageEntryContainerController *)controller;
- (void)reloadEntryController:(HSBeaconMessageEntryContainerController *)controller;

@end

#pragma mark -

@interface HSBeaconMessageEntryContainerController: UIViewController

@property(strong, nonatomic) HSBeaconContext *beaconContext;
@property (nonatomic, weak) id<HSBeaconMessageEntryContainerControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerHeight;

@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property(weak, nonatomic) IBOutlet UIView *agentsViewContainer;
@property(weak, nonatomic) IBOutlet HSBeaconAgentsView *agentsView;

@property(weak, nonatomic) IBOutlet HSBeaconSubmitButton *sendButton;
@property(weak, nonatomic) IBOutlet UIButton *attachmentButton;

@property(weak, nonatomic) IBOutlet UILabel *responseTimeText;
@property(weak, nonatomic) IBOutlet UILabel *helpText;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *footerBottomConstraint;

@property(weak, nonatomic) IBOutlet HSBeaconErrorView *errorContainer;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *errorContainerHeight;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

- (void)sendMessage;

- (void)showPreviousMessages;

- (void)resetForm;

@end

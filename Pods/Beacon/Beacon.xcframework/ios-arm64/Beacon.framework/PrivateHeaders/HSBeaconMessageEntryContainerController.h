#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>
#import <Beacon/HSBeaconAgentsView.h>

@class HSBeaconContext, HSBeaconCustomFieldsEntryController, HSBeaconErrorView, HSBeaconSubmitButton, HSBeaconMessageEntryContainerController;

@protocol HSBeaconMessageEntryContainerControllerDelegate <NSObject>

- (void)messageEntryComplete:(HSBeaconMessageEntryContainerController *)controller;
- (void)messageCountRefreshRequired:(HSBeaconMessageEntryContainerController *)controller;
- (void)showPreviousMessages:(HSBeaconMessageEntryContainerController *)controller;
- (void)reloadEntryController:(HSBeaconMessageEntryContainerController *)controller;

@optional

- (void)beaconDismissRequested;

@end

//MARK: -

@interface HSBeaconMessageEntryContainerController: HSViewController

@property(strong, nonatomic) HSBeaconContext *beaconContext;
@property(nonatomic) BOOL showNoAgentsAvailabilityMessage;
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

- (void)showHeader;

@end

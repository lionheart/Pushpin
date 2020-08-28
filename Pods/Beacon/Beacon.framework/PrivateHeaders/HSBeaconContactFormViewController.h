#import <UIKit/UIKit.h>
#import "HSViewController.h"
#import "HSBeaconContext.h"

@class HSBeaconAttachmentsTableView;
@class HSBeaconContactFormViewController;
@class HSBeaconContactFormField;
@class HSBeaconEmailMessage;

@protocol HSBeaconContactFormControllerDelegate
@required
- (void)showErrorMessage:(NSString *)errorMessage;
- (void)clearErrorMessage;
@end

#pragma mark -

@interface HSBeaconContactFormViewController: HSViewController

@property (nonatomic, weak) id<HSBeaconContactFormControllerDelegate> delegate;
@property (strong, nonatomic) HSBeaconContext *beaconContext;
@property (nonatomic) BOOL sendQueued;
@property (nonatomic) HSBeaconContactForm *prefilledForm;
@property (nonatomic, strong) NSDictionary<NSString*, NSString*> *sessionAttributes;
@property(nonatomic) BOOL showNoAgentsAvailabilityMessage;

@property (weak, nonatomic) IBOutlet UILabel *chatAvailabilityLabel;
@property (weak, nonatomic) IBOutlet UIView *chatAvailabilityMessageView;
@property (weak, nonatomic) IBOutlet HSBeaconContactFormField *nameField;
@property (weak, nonatomic) IBOutlet HSBeaconContactFormField *subjectField;
@property (weak, nonatomic) IBOutlet HSBeaconContactFormField *emailField;
@property (weak, nonatomic) IBOutlet UITextView *bodyField;

@property (weak, nonatomic) IBOutlet UIView *attachmentsContainer;
@property (weak, nonatomic) IBOutlet UILabel *attachmentsLabel;
@property (weak, nonatomic) IBOutlet UILabel *attachmentsToggleLabel;
@property (weak, nonatomic) IBOutlet HSBeaconAttachmentsTableView *attachmentsTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentsContainerHeight;
@property (weak, nonatomic) IBOutlet UIImageView *messageBodyErrorIcon;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatAvailabilityMessageHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailHeight;

+ (instancetype)instantiateViewController;

- (BOOL)canAddAttachment;

- (void)addAttachment:(HSBeaconAttachment *)attachment;

/*!
 @brief Check if we have a valid message to send
 
 @return YES if validation passes, NO if there are errors
 */
- (BOOL)validateFieldsWithErrorsDisplayed:(BOOL)showErrors;

/*!
 @brief Upload any pending attachments
 
 @return YES if attachments are pending, NO if it's okay to send the email message
 */
- (BOOL)queueAttachments;

- (HSBeaconEmailMessage *)constructMessage;

- (void)clearForm:(BOOL) forReset;

- (void)populateSecurityInfo;

- (void)setCustomFieldDefinitions:(NSArray<HSBeaconCustomFieldDefinition *> *)fieldDefinitions;

@end

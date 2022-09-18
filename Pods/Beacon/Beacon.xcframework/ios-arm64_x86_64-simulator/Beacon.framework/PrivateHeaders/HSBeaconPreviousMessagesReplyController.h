#import <UIKit/UIKit.h>
#import "HSViewController.h"
#import "HSBeaconAttachmentsTableView.h"
#import "HSBeaconContext.h"
#import "HSBeaconErrorView.h"
#import "HSBeaconReplyMessage.h"
#import "HSBeaconSubmitButton.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HSBeaconPreviousMessagesReplyDelegate

-(void)dismissWindow:(BOOL)reload draft:(nullable HSBeaconReplyMessage *)draft;

@end

@interface HSBeaconPreviousMessagesReplyController : HSViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet HSBeaconAttachmentsTableView *attachmentsTable;
@property (weak, nonatomic) IBOutlet UITextView *textArea;
@property (weak, nonatomic) IBOutlet HSBeaconSubmitButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *attachButton;

@property (weak, nonatomic) IBOutlet HSBeaconErrorView *errorContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentsTableHeightConstraint;

@property (nonatomic) long conversationId;
@property (nonatomic) HSBeaconContext *beaconContext;
@property (nonatomic, weak) id<HSBeaconPreviousMessagesReplyDelegate> delegate;

@property (nonatomic) HSBeaconReplyMessage *draft;

-(void)startEditing;

@end

NS_ASSUME_NONNULL_END

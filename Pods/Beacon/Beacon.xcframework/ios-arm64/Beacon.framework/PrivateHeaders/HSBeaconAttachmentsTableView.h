#import <UIKit/UIKit.h>
#import <Beacon/HSTableView.h>
#import <Beacon/HSBeaconAttachment.h>
#import <Beacon/HSBeaconContext.h>

@class HSBeaconAttachmentTableViewCell;

@protocol HSBeaconAttachmentsTableViewDelegate

- (void)attachmentsTableShowError:(NSString *)error;
- (void)attachmentUploadComplete;
- (void)attachmentsTableLayoutChanged:(CGFloat)newHeight;

@end

@interface HSBeaconAttachmentsTableView : HSTableView

@property (nonatomic) HSBeaconContext *beaconContext;
@property (nonatomic) NSMutableArray<HSBeaconAttachment *> *attachments;
@property (weak) id<HSBeaconAttachmentsTableViewDelegate> attachmentsTableDelegate;

- (void)addAttachment:(HSBeaconAttachment *)attachment;

- (BOOL)canAddAttachment;

- (BOOL)hasPendingUpload;

- (BOOL)sendPendingUploads;

/* this is for resetting the form */
- (void)deleteAttachments;

/* this is for post-send */
- (void)clearAttachments;

@end

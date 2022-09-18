#import <UIKit/UIKit.h>
#import "HSTableViewCell.h"
#import "HSBeaconAttachment.h"

@protocol HSBeaconRemoveAttachmentDelegate

-(void)removeAttachment: (nonnull HSBeaconAttachment *)attachment;

@end

@interface HSBeaconAttachmentTableViewCell: HSTableViewCell

@property(weak, nonatomic, nullable) IBOutlet UILabel *filenameLabel;
@property(weak, nonatomic, nullable) IBOutlet UILabel *statusLabel;
@property(weak, nonatomic, nullable) IBOutlet UIImageView *attachmentImage;
@property(weak, nonatomic, nullable) IBOutlet UIProgressView *attachmentProgress;
@property (weak, nonatomic, nullable) IBOutlet UIButton *removeButton;

@property(weak, nonatomic, nullable) id<HSBeaconRemoveAttachmentDelegate> removeAttachmentDelegate;

-(void)setAttachment: (nonnull HSBeaconAttachment *)attachment;

@end

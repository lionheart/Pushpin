#import <UIKit/UIKit.h>

#import "HSBeaconAttachment.h"

@protocol HSBeaconRemoveAttachmentDelegate

-(void)removeAttachment: (HSBeaconAttachment *)attachment;

@end

@interface HSBeaconAttachmentTableViewCell: UITableViewCell

@property(weak, nonatomic) IBOutlet UILabel *filenameLabel;
@property(weak, nonatomic) IBOutlet UILabel *statusLabel;
@property(weak, nonatomic) IBOutlet UIImageView *attachmentImage;
@property(weak, nonatomic) IBOutlet UIProgressView *attachmentProgress;
@property (weak, nonatomic) IBOutlet UIButton *removeLabel;

@property(weak, nonatomic) id<HSBeaconRemoveAttachmentDelegate> removeAttachmentDelegate;

-(void)setAttachment: (HSBeaconAttachment *)attachment;

@end

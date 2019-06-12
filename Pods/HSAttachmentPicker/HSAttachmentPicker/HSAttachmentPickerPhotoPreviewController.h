#import <UIKit/UIKit.h>

@class HSAttachmentPickerPhotoPreviewController;

@protocol HSAttachmentPickerPhotoPreviewControllerDelegate

-(void)photoPreview:(HSAttachmentPickerPhotoPreviewController *_Nonnull)photoPreview usePhoto:( NSDictionary<NSString *,id> *_Nonnull)info;

@end

@interface HSAttachmentPickerPhotoPreviewController : UIViewController

@property (nonatomic, weak, nullable) id<HSAttachmentPickerPhotoPreviewControllerDelegate> delegate;

@property (nonatomic, strong, nonnull) NSDictionary<NSString *,id> *info;

@end

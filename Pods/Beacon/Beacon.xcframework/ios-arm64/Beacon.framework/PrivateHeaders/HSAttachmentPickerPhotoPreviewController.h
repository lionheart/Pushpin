#import <UIKit/UIKit.h>

@class HSAttachmentPickerPhotoPreviewController;

@protocol HSAttachmentPickerPhotoPreviewControllerDelegate

- (void)photoPreview:(HSAttachmentPickerPhotoPreviewController *_Nonnull)photoPreview usePhoto:( NSDictionary<UIImagePickerControllerInfoKey, id> *_Nonnull)info;

@end

@interface HSAttachmentPickerPhotoPreviewController : UIViewController

@property (nonatomic, weak, nullable) id<HSAttachmentPickerPhotoPreviewControllerDelegate> delegate;

@property (nonatomic, strong, nonnull) NSDictionary<UIImagePickerControllerInfoKey, id> *info;

/// The bundle to use when accessing localizations.  If translationsBundle is nil or unset [NSBundle mainBundle] will be used.
@property (nonatomic, nullable) NSBundle *translationsBundle;

/// The name of the strings translation table to search. If translationTable is nil or is an empty string, translations will use the table in Localizable.strings.
@property (nonatomic, nullable) NSString *translationTable;

@end

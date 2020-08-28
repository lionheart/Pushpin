#import <UIKit/UIKit.h>

@class HSAttachmentPicker;

@protocol HSAttachmentPickerDelegate<NSObject>

- (void)attachmentPickerMenu:(HSAttachmentPicker *_Nonnull)menu showController:(UIViewController *_Nonnull)controller completion:(void (^_Nullable)(void))completion;

- (void)attachmentPickerMenu:(HSAttachmentPicker *_Nonnull)menu showErrorMessage:(NSString *_Nonnull)errorMessage;

- (void)attachmentPickerMenu:(HSAttachmentPicker *_Nonnull)menu upload:(NSData *_Nonnull)data filename:(NSString *_Nonnull)filename image:(UIImage *_Nullable)image;

@optional
- (void)attachmentPickerMenuDismissed:(HSAttachmentPicker *_Nonnull)menu;

@end

@interface HSAttachmentPicker : NSObject

@property (nonatomic, weak, nullable) id<HSAttachmentPickerDelegate> delegate;


/// The desired video quality to return selected movies in, defaults to UIImagePickerControllerQualityTypeMedium
@property (nonatomic) UIImagePickerControllerQualityType preferredVideoQuality;

/// The bundle to use when accessing localizations.  If translationsBundle is nil or unset [NSBundle mainBundle] will be used.
@property (nonatomic, nullable) NSBundle *translationsBundle;

/// The name of the strings translation table to search. If translationTable is nil or is an empty string, translations will use the table in Localizable.strings.
@property (nonatomic, nullable) NSString *translationTable;

- (void)showAttachmentMenu;

@end

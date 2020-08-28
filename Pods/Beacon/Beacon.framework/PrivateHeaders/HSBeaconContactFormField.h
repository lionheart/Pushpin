#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconContactFormValidator.h"

@class HSBeaconContactFormField;

@protocol HSBeaconContactFormFieldDelegate <NSObject>

- (void)contactFormFieldTextChanged:(HSBeaconContactFormField * _Nonnull)field;
- (void)contactFormField:(HSBeaconContactFormField * _Nonnull)field didReachMaximumLength:(BOOL)reachedMaximumLength;

@optional

- (BOOL)contactFormFieldTypeShouldReturn:(HSContactFieldType)fieldType field:(UITextField * _Nonnull)textField;

@end

@interface HSBeaconContactFormField : HSView

@property (weak, nonatomic, nullable) IBOutlet UITextField *inputField;
@property (weak, nonatomic, nullable) IBOutlet UIView *bottomErrorBar;
@property (weak, nonatomic, nullable) IBOutlet UIImageView *errorIcon;
@property (weak, nonatomic, nullable) id<HSBeaconContactFormFieldDelegate> delegate;
@property (strong, nonatomic, nullable) IBOutlet UIView *contentView;
@property (nonatomic) HSContactFieldType fieldType;

- (void)showError;

- (void)hideError;

- (NSString * _Nullable)text;

- (void)setText:(NSString * _Nullable)text;

- (void)resetValue;

- (void)setPlaceholder:(NSString * _Nullable)placeholder;

- (HSContactFieldValidationResult)validate:(BOOL)errorsDisplayed;

@end

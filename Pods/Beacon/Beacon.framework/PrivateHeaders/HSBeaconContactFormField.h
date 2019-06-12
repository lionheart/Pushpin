#import <UIKit/UIKit.h>
#import "HSBeaconContactFormValidator.h"

@class HSBeaconContactFormField;

@protocol HSBeaconContactFormFieldDelegate

- (void)contactFormFieldTextChanged:(HSBeaconContactFormField *)field;
- (void)contactFormField:(HSBeaconContactFormField *)field didReachMaximumLength:(BOOL)reachedMaximumLength;

@end

@interface HSBeaconContactFormField : UIView

@property (weak, nonatomic) IBOutlet UITextField *inputField;
@property (weak, nonatomic) IBOutlet UIView *topErrorBar;
@property (weak, nonatomic) IBOutlet UIView *bottomErrorBar;
@property (weak, nonatomic) IBOutlet UIImageView *errorIcon;
@property (weak, nonatomic) id<HSBeaconContactFormFieldDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic) HSContactFieldType fieldType;

- (void)showError;

- (void)hideError;

- (NSString *)text;

- (void)setText:(NSString *)text;

- (void)resetValue;

- (void)setPlaceholder:(NSString *)placeholder;

- (HSContactFieldValidationResult)validate:(BOOL)errorsDisplayed;

@end

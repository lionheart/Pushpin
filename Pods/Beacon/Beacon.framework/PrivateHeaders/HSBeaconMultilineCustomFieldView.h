#import "HSBeaconCustomFieldEntryView.h"

@interface HSBeaconMultilineCustomFieldView : HSBeaconCustomFieldEntryView <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *overflowErrorHeight;
@property (weak, nonatomic) IBOutlet UILabel *overflowErrorLabel;

@end

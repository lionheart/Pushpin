#import "HSBeaconCustomFieldEntryView.h"

@interface HSBeaconDropdownCustomFieldView : HSBeaconCustomFieldEntryView

@property (weak, nonatomic) IBOutlet UITextView *textInput;
@property (weak, nonatomic) IBOutlet UIButton *caretButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *caretTrailingConstraint;

@end

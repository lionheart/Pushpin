#import <Beacon/HSBeaconCustomFieldEntryView.h>

@interface HSBeaconNumberCustomFieldView : HSBeaconCustomFieldEntryView <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textInput;

@end

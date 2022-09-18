#import <Beacon/HSBeaconCustomFieldEntryView.h>

@interface HSBeaconSinglelineCustomFieldView : HSBeaconCustomFieldEntryView <UITextViewDelegate> 

@property (weak, nonatomic) IBOutlet UITextView *textInput;

@end

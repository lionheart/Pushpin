#import <UIKit/UIKit.h>

#import "HSBeaconFormInputStatus.h"
#import "HSBeaconPickerView.h"

@interface HSBeaconDropdownPickerView : HSBeaconPickerView

@property (nonatomic) long inputIndex;
@property (weak, nonatomic) HSBeaconFormInputStatus *inputStatus;

@property (weak, nonatomic) IBOutlet UIPickerView *picker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@end

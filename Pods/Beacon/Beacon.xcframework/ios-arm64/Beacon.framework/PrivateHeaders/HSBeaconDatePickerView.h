#import <Beacon/HSBeaconPickerView.h>

#import <Beacon/HSBeaconFormInputStatus.h>

@protocol HSBeaconDatePickerViewDelegate

- (void)dateChanged:(NSDate *)date;

@end

@interface HSBeaconDatePickerView : HSBeaconPickerView

+ (instancetype)instantiate;

@property (nonatomic) long inputIndex;
@property (weak, nonatomic) HSBeaconFormInputStatus *inputStatus;

@property (weak) id<HSBeaconDatePickerViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;

- (void)updateButtons:(UIColor *)tintColor;

@end

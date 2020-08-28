#import <UIKit/UIKit.h>
#import "HSToolBar.h"
#import "HSBeaconFormInputStatus.h"

@interface HSBeaconInputNavigationToolbar : HSToolBar

@property (nonatomic) HSBeaconFormInputStatus *inputStatus;

+ (void)addToolbarsToInputs:(NSArray *)inputs parentView:(UIView *)view tintColor:(UIColor *)color;

- (void)prevInput:(UIButton *)sender;

- (void)nextInput:(UIButton *)sender;

@end

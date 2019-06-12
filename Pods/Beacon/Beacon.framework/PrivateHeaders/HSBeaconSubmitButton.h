#import <UIKit/UIKit.h>

#import "HSBeaconTintColor.h"

@interface HSBeaconSubmitButton : UIButton

-(void)inactiveState;

-(void)activeState:(HSBeaconTintColor *)tintColor;

-(void)showSpinner:(HSBeaconTintColor *)tintColor;

-(void)hideSpinner;

@end

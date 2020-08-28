#import <UIKit/UIKit.h>
#import "HSButton.h"
#import "HSBeaconTintColor.h"

@interface HSBeaconSubmitButton : HSButton

-(void)inactiveState;

-(void)activeState:(HSBeaconTintColor *)tintColor;

-(void)showSpinner:(HSBeaconTintColor *)tintColor;

-(void)hideSpinner;

@end

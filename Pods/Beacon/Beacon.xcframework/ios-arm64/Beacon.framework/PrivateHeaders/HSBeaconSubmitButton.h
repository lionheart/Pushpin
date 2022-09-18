#import <UIKit/UIKit.h>
#import <Beacon/HSButton.h>
#import <Beacon/HSBeaconTintColor.h>

@interface HSBeaconSubmitButton : HSButton

-(void)configureWithTintColor:(HSBeaconTintColor *)tintColor;

-(void)showSpinner;

-(void)hideSpinner;

@end

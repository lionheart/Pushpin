#import <UIKit/UIKit.h>
#import <Beacon/HSView.h>

@interface HSBeaconErrorView : HSView

-(void)showError:(NSString *)errorMessage;

-(void)hideError;

@end

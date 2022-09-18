#import <UIKit/UIKit.h>
#import <Beacon/HSView.h>
#import <Beacon/HSBeaconContext.h>

@interface HSBeaconPickerView : HSView

@property (nonatomic, strong) HSBeaconContext *beaconContext;

- (void)show;
- (void)dismiss;

@end

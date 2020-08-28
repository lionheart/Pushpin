#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconContext.h"

@interface HSBeaconPickerView : HSView

@property (nonatomic, strong) HSBeaconContext *beaconContext;

- (void)show;
- (void)dismiss;

@end

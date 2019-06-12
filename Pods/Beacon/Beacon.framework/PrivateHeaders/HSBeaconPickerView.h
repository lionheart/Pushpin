#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"

@interface HSBeaconPickerView : UIView

@property (nonatomic, strong) HSBeaconContext *beaconContext;

- (void)show;
- (void)dismiss;

@end

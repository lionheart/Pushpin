#import <UIKit/UIKit.h>
#import "HSView.h"
@class HSBeaconContext;
@class HSBorderedButton;

@interface HSBeaconSearchFooterView : HSView

@property (weak, nonatomic) HSBeaconContext *beaconContext;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet HSBorderedButton *actionButton;

@end

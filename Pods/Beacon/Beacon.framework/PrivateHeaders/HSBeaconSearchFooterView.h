#import <UIKit/UIKit.h>

@class HSBeaconContext;
@class HSBorderedButton;

@interface HSBeaconSearchFooterView : UIView

@property (weak, nonatomic) HSBeaconContext *beaconContext;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet HSBorderedButton *actionButton;

@end

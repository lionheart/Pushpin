#import <UIKit/UIKit.h>
#import "HSBorderedButton.h"

@protocol HSBeaconArticlesFooterCellDelegate
- (void)didTapGetInTouch;
@end

@interface HSBeaconArticlesFooterCell : UITableViewCell

extern NSString * const HSBeaconArticlesFooterCellIdentifier;

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet HSBorderedButton *actionButton;
@property (weak, nonatomic) id<HSBeaconArticlesFooterCellDelegate> delegate;

@end

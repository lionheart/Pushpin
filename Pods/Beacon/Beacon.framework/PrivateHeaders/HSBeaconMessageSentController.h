#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"

@interface HSBeaconMessageSentController: UIViewController

@property(weak, nonatomic) IBOutlet UIImageView *messageSentImageView;
@property(weak, nonatomic) IBOutlet UILabel *messageSentHeaderLabel;
@property(weak, nonatomic) IBOutlet UILabel *messageSentBodyLabel;
@property (weak, nonatomic) IBOutlet UIButton *previousMessagesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

@property(strong, nonatomic) HSBeaconContext *context;

@end

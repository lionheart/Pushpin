#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconMessageEntryContainerController.h>

@interface HSBeaconMessageSentController: HSViewController

@property(weak, nonatomic) IBOutlet UIImageView *messageSentImageView;
@property(weak, nonatomic) IBOutlet UILabel *messageSentHeaderLabel;
@property(weak, nonatomic) IBOutlet UILabel *messageSentBodyLabel;
@property (weak, nonatomic) IBOutlet UIButton *previousMessagesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

@property (nonatomic, weak) id<HSBeaconMessageEntryContainerControllerDelegate> delegate;

@property(strong, nonatomic) HSBeaconContext *context;

@end

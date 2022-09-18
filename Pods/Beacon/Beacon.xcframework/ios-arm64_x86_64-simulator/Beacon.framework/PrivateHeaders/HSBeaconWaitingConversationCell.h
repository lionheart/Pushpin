#import <UIKit/UIKit.h>
#import <HSTableViewCell.h>
#import <HSBeaconConversation.h>
#import <HSBeaconPaddingLabel.h>
#import <HSBeaconContext.h>

@interface HSBeaconWaitingConversationCell : HSTableViewCell

@property (weak, nonatomic) IBOutlet UIView *multiThreadHeader;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *multiThreadHeaderHeight;
@property (weak, nonatomic) IBOutlet UILabel *timeagoLabel;
@property (weak, nonatomic) IBOutlet HSBeaconPaddingLabel *threadCount;

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *recievedLabel;
@property (weak, nonatomic) IBOutlet UIView *convoContainer;

@property (strong, nonatomic) HSBeaconContext *beaconContext;

-(void)setConversation: (HSBeaconConversation *)conversation;

@end

#import <UIKit/UIKit.h>

#import "HSBeaconAgentsView.h"
#import "HSBeaconContext.h"
#import "HSBeaconConversation.h"

@interface HSBeaconAgentsViewConversationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *multiThreadHeader;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *multiThreadHeaderHeight;
@property (weak, nonatomic) IBOutlet UILabel *timeagoLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadCount;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastThreadPreviewLabel;
@property (weak, nonatomic) IBOutlet HSBeaconAgentsView *agentsView;
@property (weak, nonatomic) IBOutlet UIView *convoContainer;

-(void)setConversation: (HSBeaconConversation *)conversation context:(HSBeaconContext *)beaconContext;

@end

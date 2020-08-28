#import <UIKit/UIKit.h>
#import "HSTableViewCell.h"
#import "HSBeaconContext.h"
#import "HSBeaconConversation.h"

@interface HSBeaconSubjectOnlyConversationCell : HSTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UIView *convoContainer;

-(void)setConversation: (HSBeaconConversation *)conversation context:(HSBeaconContext *)beaconContext;;

@end

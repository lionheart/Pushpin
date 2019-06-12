#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"
#import "HSBeaconConversation.h"

@interface HSBeaconSubjectOnlyConversationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UIView *convoContainer;

-(void)setConversation: (HSBeaconConversation *)conversation context:(HSBeaconContext *)beaconContext;;

@end

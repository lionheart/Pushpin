#import <UIKit/UIKit.h>

#import "HSBeaconArticleCell.h"
#import "HSBeaconContext.h"
#import "HSBeaconSuggestion.h"

@interface HSBeaconSuggestionCell: UITableViewCell <HSBeaconArticleCell>

@property(strong, nonatomic) HSBeaconSuggestion *suggestion;
@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property(weak, nonatomic) IBOutlet UIImageView *image;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;



@end

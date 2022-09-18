#import <UIKit/UIKit.h>
#import <Beacon/HSTableViewCell.h>
#import <Beacon/HSBeaconArticleCell.h>
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconSuggestion.h>

@interface HSBeaconSuggestionCell: HSTableViewCell <HSBeaconArticleCell>

@property(strong, nonatomic) HSBeaconSuggestion *suggestion;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleToImageTrailing;
@property (weak, nonatomic) IBOutlet UIView *suggestionContainer;
@property (weak, nonatomic) IBOutlet UIView *previewContainer;
@property(weak, nonatomic) IBOutlet UIImageView *image;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *previewLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameToSuperviewBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameToSuperviewTop;

@end

#import <UIKit/UIKit.h>
#import "HSTableViewCell.h"
#import "HSBeaconArticleCell.h"
#import "HSBeaconArticleSearchResult.h"
#import "HSBeaconContext.h"

@interface HSBeaconSearchResultsCell: HSTableViewCell <HSBeaconArticleCell>

@property(strong, nonatomic) HSBeaconArticleSearchResult *searchResult;
@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property (weak, nonatomic) IBOutlet UIView *resultContainer;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *previewLabel;

-(void)setPreviewText:(NSString *)previewText;

@end

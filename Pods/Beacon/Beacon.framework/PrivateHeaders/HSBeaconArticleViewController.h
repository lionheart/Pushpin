#import <UIKit/UIKit.h>
#import "HSViewController.h"
#import "HSBeaconContext.h"
#import "HSBeaconSuggestion.h"
#import "HSBeaconRelatedArticlesTableView.h"
#import "HSCardStackViewController.h"

@interface HSBeaconArticleViewController : HSViewController <HSCardStackEmbeddable>

@property (nonatomic, strong) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet HSBeaconRelatedArticlesTableView *relatedArticlesTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *relatedArticlesHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *relatedArticlesLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;

- (void)updateWithArticleID:(NSString *)articleID context:(HSBeaconContext *)context;

@end

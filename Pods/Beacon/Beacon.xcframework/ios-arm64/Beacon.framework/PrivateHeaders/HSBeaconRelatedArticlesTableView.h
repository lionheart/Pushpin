#import <UIKit/UIKit.h>
#import <Beacon/HSTableView.h>
#import <Beacon/HSBeaconContext.h>

@class HSBeaconArticleDetails;

@protocol HSBeaconRelatedArticlesTableProtocol
- (void)relatedArticlesTableViewDidSelectArticleDetails:(HSBeaconArticleDetails *)articleDetails;
@end

@interface HSBeaconRelatedArticlesTableView : HSTableView

@property (nonatomic, strong) HSBeaconContext *beaconContext;
@property (nonatomic, weak) id<HSBeaconRelatedArticlesTableProtocol> relatedArticlesDelegate;

@property (nonatomic) HSBeaconArticleDetails *articleDetails;

@end

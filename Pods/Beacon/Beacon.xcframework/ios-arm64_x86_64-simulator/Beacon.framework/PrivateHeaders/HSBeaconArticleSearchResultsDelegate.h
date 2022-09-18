#import <UIKit/UIKit.h>

#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconPaging.h>

@protocol HSBeaconArticleSearchResultsFooterDelegate
- (void)footerViewDidTapGetInTouch;
@end

@interface HSBeaconArticleSearchResultsDelegate : NSObject <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) HSBeaconContext *beaconContext;
@property (weak, nonatomic) UITableViewController *parentController;
@property (weak, nonatomic) id<HSBeaconArticleSearchResultsFooterDelegate> delegate;

- (BOOL)hasSearchResults;

- (HSBeaconArticleSearchResultsDelegate *)initWithParentController:(UITableViewController *)parentController;

- (void)updateSearchResults:(NSString *)searchText;

- (void)runSearch;
- (void)clearResults;

@end

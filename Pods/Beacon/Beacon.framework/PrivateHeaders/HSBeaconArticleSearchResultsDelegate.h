#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"
#import "HSBeaconPaging.h"

@protocol HSBeaconArticleSearchResultsFooterDelegate
- (void)footerViewDidTapGetInTouch;
@end

@interface HSBeaconArticleSearchResultsDelegate : NSObject <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) HSBeaconContext *beaconContext;
@property (weak, nonatomic) UITableViewController *parentController;
@property (weak, nonatomic) id<HSBeaconArticleSearchResultsFooterDelegate> delegate;

@property NSArray *searchResults;
@property (nonatomic, assign) BOOL hasSearchResults;
@property HSBeaconPaging *currentPage;
@property int previousBeginLoadOffset;
@property NSURLSessionDataTask *currentSearch;
@property NSString *currentSearchText;

- (HSBeaconArticleSearchResultsDelegate *)initWithParentController:(UITableViewController *)parentController;

- (void)updateSearchResults:(NSString *)searchText;

- (void)runSearch;
- (void)clearResults;

@end

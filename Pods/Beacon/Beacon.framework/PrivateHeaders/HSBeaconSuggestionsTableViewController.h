#import <UIKit/UIKit.h>
#import "HSTableViewController.h"
#import "HSBeaconContext.h"
#import "HSBeaconArticleSearchResultsDelegate.h"

@interface HSBeaconSuggestionsTableViewController: HSTableViewController

@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property(strong, nonatomic) NSArray *suggestions;

- (void)setupSuggestions;

- (void)setupSearch:(HSBeaconArticleSearchResultsDelegate *)searchDelegate;

- (void)enablePreviousMessages;

@end

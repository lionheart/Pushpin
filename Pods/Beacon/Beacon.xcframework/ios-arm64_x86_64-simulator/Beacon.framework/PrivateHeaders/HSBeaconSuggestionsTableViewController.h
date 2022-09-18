#import <UIKit/UIKit.h>
#import <Beacon/HSTableViewController.h>
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconArticleSearchResultsDelegate.h>

@interface HSBeaconSuggestionsTableViewController: HSTableViewController

@property(strong, nonatomic) HSBeaconContext *beaconContext;

@property(strong, nonatomic) NSArray *suggestions;

- (void)setupSuggestions;

- (void)setupSearch:(HSBeaconArticleSearchResultsDelegate *)searchDelegate;

@end

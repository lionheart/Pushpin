#import <UIKit/UIKit.h>

#import "HSBeaconContext.h"
#import "HSBeaconSuggestion.h"
#import "HSBeaconSuggestionItem.h"

#pragma mark - HSBeaconSuggestionsControllerDelegate

@protocol HSBeaconSuggestionsContainerControllerDelegate

- (void)displayContactFlow;

@end

#pragma mark - HSBeaconSuggestionsContainerController

typedef NS_ENUM (NSInteger, HSMessagingItem) {
    HSGetInTouchItem, HSPreviousMessagesItem
};

@interface HSBeaconSuggestionsContainerController : UIViewController

@property (nonatomic, weak) id<HSBeaconSuggestionsContainerControllerDelegate> delegate;
@property (nonatomic, strong) HSBeaconContext *beaconContext;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarBottom;
@property (nonatomic) NSArray<HSBeaconSuggestion *> *suggestions;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *searchBarSeparator;

- (void)openLink:(HSBeaconSuggestion *)suggestion;

- (void)enablePreviousMessages;

- (void)showPreviousMessages;

- (void)showAsk;

- (void)runSearch:(NSString *)searchText;

- (void)loadDefaultSuggestions;

- (void)loadCustomSuggestions:(NSArray<id<HSBeaconSuggestionItem>> *)articleIds;

@end

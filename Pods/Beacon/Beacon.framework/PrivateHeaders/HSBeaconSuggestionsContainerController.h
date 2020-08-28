#import <UIKit/UIKit.h>
#import "HSViewController.h"
#import "HSBeaconContext.h"
#import "HSBeaconSuggestion.h"
#import "HSBeaconSuggestionItem.h"
#import "HSBeaconMessageEntryContainerController.h"
#import "HSBeaconPreviousMessagesEnabler.h"

#pragma mark - HSBeaconSuggestionsControllerDelegate

@protocol HSBeaconSuggestionsContainerControllerDelegate

- (void)displayContactFlow;
- (void)displayChatFlow;

@end

#pragma mark - HSBeaconSuggestionsContainerController

typedef NS_ENUM (NSInteger, HSMessagingItem) {
    HSGetInTouchItem, HSPreviousMessagesItem
};

@interface HSBeaconSuggestionsContainerController : HSViewController<HSBeaconMessageEntryContainerControllerDelegate, HSBeaconPreviousMessagesEnabler>

@property (nonatomic, weak) id<HSBeaconSuggestionsContainerControllerDelegate> delegate;
@property (nonatomic, strong) HSBeaconContext *beaconContext;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarBottom;
@property (nonatomic) NSArray<HSBeaconSuggestion *> *suggestions;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *searchBarSeparator;

- (void)openLink:(HSBeaconSuggestion *)suggestion;

- (void)enablePreviousMessages;

- (void)showPreviousMessages;

- (void)showGetInTouch;

- (void)runSearch:(NSString *)searchText;

- (void)loadDefaultSuggestions;

- (void)loadCustomSuggestions:(NSArray<id<HSBeaconSuggestionItem>> *)articleIds;

@end

#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconSuggestion.h>
#import "HSBeaconSuggestionItem.h"
#import <Beacon/HSBeaconMessageEntryContainerController.h>
#import <Beacon/HSBeaconPreviousMessagesEnabler.h>
#import <Beacon/HSBeaconAnswersSearchBar.h>
#import <Beacon/HSBeaconPreviousMessagesPresenter.h>
#import <Beacon/HSBeaconRoutingFulfilling.h>

//MARK: - HSBeaconSuggestionsContainerController

@interface HSBeaconSuggestionsContainerController : HSViewController<HSBeaconMessageEntryContainerControllerDelegate, HSBeaconPreviousMessagesEnabler, HSBeaconPreviousMessagesPresenter, UISearchBarDelegate, HSBeaconRoutingFulfilling>

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *suggestionsFirstConstraints;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *askFirstConstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactContainerLeadingContraint;

@property (nonatomic, strong) HSBeaconContext *beaconContext;
@property (weak, nonatomic) IBOutlet UIView *searchBarSpacer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sugestionsContainerViewBottom;
@property (nonatomic) NSArray<HSBeaconSuggestion *> *suggestions;
@property (weak, nonatomic) IBOutlet HSBeaconAnswersSearchBar *searchBar;

+ (instancetype)instantiateViewController;

- (void)openLink:(HSBeaconSuggestion *)suggestion;

- (void)enablePreviousMessages;

- (void)runSearch:(NSString *)searchText;

- (void)loadDefaultSuggestions;

- (void)loadCustomSuggestions:(NSArray<id<HSBeaconSuggestionItem>> *)articleIds;

- (void)resetForm;

@end

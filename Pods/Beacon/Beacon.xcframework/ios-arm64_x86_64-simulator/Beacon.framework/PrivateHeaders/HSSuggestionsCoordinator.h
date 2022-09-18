#import <Beacon/HSBeaconContext.h>
#import "HSBeaconSuggestionItem.h"
#import <Beacon/HSBeaconSuggestionsContainerController.h>
#import <Beacon/HSContactCoordinator.h>

NS_ASSUME_NONNULL_BEGIN

@class HSSuggestionsCoordinator;

//MARK: - HSSuggestionsCoordinatorDelegate

@protocol HSSuggestionsCoordinatorDelegate

- (void)suggestionsCoordinatorRequestsDismissal:(HSSuggestionsCoordinator *)suggestionsCoordinator;

@end

//MARK: - HSSuggestionsCoordinator

@interface HSSuggestionsCoordinator : NSObject <HSBeaconCoordinator>

@property (nonatomic, weak) id<HSSuggestionsCoordinatorDelegate> delegate;
@property (nonatomic, readonly) UINavigationController *navigationController;
@property (readonly) HSBeaconContext *beaconContext;
@property (nonatomic) BOOL navigateWithAnimation;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController beaconContext:(HSBeaconContext *)context;

- (void)start;

- (void)updateSuggestions:(NSArray<id<HSBeaconSuggestionItem>> *)suggestions;

- (void)resetForm;

@end

NS_ASSUME_NONNULL_END

#import <Beacon/HSBeaconCoordinator.h>
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconMessageEntryContainerController.h>

NS_ASSUME_NONNULL_BEGIN

@class HSContactCoordinator;

//MARK: - HSContactCoordinator

@interface HSContactCoordinator : NSObject <HSBeaconCoordinator, HSBeaconMessageEntryContainerControllerDelegate>

@property (nonatomic, readonly) UINavigationController *navigationController;
@property (readonly) HSBeaconContext *beaconContext;
@property (nonatomic) BOOL navigateWithAnimation;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController beaconContext:(HSBeaconContext *)context;

- (void)resetForm;

@end

NS_ASSUME_NONNULL_END

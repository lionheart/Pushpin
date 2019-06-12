#import <Foundation/Foundation.h>

#import "HSBeaconContactForm.h"
#import "HSBeaconMessagingSettings.h"
#import "HSBeaconSettings.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `HSBeaconDelegate` can optionally be set on your `HSBeaconSettings` object to customize
 the runtime behavior of the Beacon SDK.
 */
@protocol HSBeaconDelegate <NSObject>


@optional
/**
 The `prefill` method is called before showing the new conversation contact form. Any values
 set on the `form` object will be prepopulated for the customer.
 */
- (void)prefill:(HSBeaconContactForm *)form;


@optional
/**
 This method is called the first time the Beacon is displayed, after the configuration
 has been successfully loaded over the network.
 */
- (void)onBeaconInitialOpen:(HSBeaconSettings *)beaconSettings;


@optional
/**
 This method is called anytime the Beacon modal is displayed.
 */
- (void)onBeaconOpen:(HSBeaconSettings *)beaconSettings;


@optional
/**
 This method is called the first time the Beacon is dismissed each session.
 */
- (void)onBeaconInitialClose:(HSBeaconSettings *)beaconSettings;


@optional
/**
 This method is called every time the Beacon modal is dismissed.
 */
- (void)onBeaconClose:(HSBeaconSettings *)beaconSettings;

@end


/**
 `HSBeaconSettings` allows you to customize the Beacon SDK and provide the
 Beacon identifier to use.

 ### Initialization

     HSBeaconSettings *settings = [[HSBeaconSettings alloc] initWithBeaconId:@"beacon-id"];
     settings.useNavigationBarAppearance = NO;
 */
@interface HSBeaconSettings: NSObject

/**
 The Beacon ID to use.

 @note This can be found during Beacon creation.
 */
@property(strong, nonatomic) NSString *beaconId;

/**
 The title used in the main Beacon interface. This is `Support` by default.
 */
@property(strong, nonatomic) NSString *beaconTitle;

/**
 * Display strings from BeaconLocalizable.strings instead of those setup in the Beacon Web UI
 */
@property BOOL useLocalTranslationOverrides;

/**
 Allows the Beacon SDK to use the `UIAppearance` settings for `UINavigationController`.
 This is false by default, and will instead use the Beacon color defined in the Beacon Builder.
 */
@property BOOL useNavigationBarAppearance;

/**
 Disable the contact options manually if it's enabled in the Beacon config.

 This will not enable the contact options if it's disabled in the config.
 */
@property BOOL messagingEnabled;

/**
 Disable the Docs integration manually if it's enabled in the Beacon config.

 This will not enable Docs if it's disabled in the config.
 */
@property BOOL docsEnabled;

/**
 This replaces the default blue color used for clickable text throughout Beacon. For example,
 you may want to set this to the tintColor of your window to match the look and feel of the
 rest of your app.
 */
@property UIColor *tintColorOverride;

/**
 Used for customizing the runtime behavior of the Beacon SDK
 */
@property (weak, nonatomic, nullable) id<HSBeaconDelegate> delegate;

/**
 Override the color from the Beacon Builder. The `useNavigationBarAppearance` option
 will override this value.
 */
@property (strong, nonatomic, nullable) UIColor *color;

/**
 Set different display options for messaging.
 */
@property (nonatomic, nonnull, readonly) HSBeaconMessagingSettings *messagingSettings;

// also use translations from the API or local translation strings (maybe)

/**
 Initialize Beacon settings with a given Beacon ID.
 */
- (instancetype)initWithBeaconId:(NSString *)beaconId;

@end

NS_ASSUME_NONNULL_END

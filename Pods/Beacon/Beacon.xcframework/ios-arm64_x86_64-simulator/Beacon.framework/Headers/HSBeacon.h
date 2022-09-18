#import <UIKit/UIKit.h>
@import UserNotifications;

@protocol HSBeaconSuggestionItem;
@class HSBeaconUser;
@class HSBeaconSettings;

NS_ASSUME_NONNULL_BEGIN

/**
 `HSBeacon` provides the APIs necessary to display the Beacon SDK. It allows you
 to open the Beacon from the current view controller on screen, or a specific
 view controller of your choice.

 ### Opening the Beacon From The Current View Controller

 The Beacon SDK requires an `HSBeaconSettings` object, which can be initialized
 using your Beacon ID.

     HSBeaconSettings *settings = [[HSBeaconSettings alloc] initWithBeaconId:@"beacon-id"];
     [HSBeacon openBeacon:settings];

 ### Authenticating Users

 Authenticating with Beacon is optional, but if you have information you'd like
 to associate with users, you can do so using `HSBeaconUser` and the `login:`
 method before showing the Beacon.

     HSBeaconUser *user = [[HSBeaconUser alloc] init];
     user.email = self.emailTextField.text;
     user.name = self.nameTextField.text;

     [HSBeacon login:user];

     HSBeaconSettings *settings = [[HSBeaconSettings alloc] initWithBeaconId:@"beacon-id"];
     [HSBeacon openBeacon:settings];
 */
@interface HSBeacon : NSObject

/**
 Opens the Beacon SDK from the current view controller.

 @param settings The Beacon settings from which to load Beacon.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)openBeacon:(HSBeaconSettings *)settings;

/**
 Opens the Beacon SDK from the current view controller, using a signature.

 @param settings The Beacon settings from which to load Beacon.
 @param signature The signature to provide, if you are using secure mode.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)openBeacon:(HSBeaconSettings *)settings signature:(NSString *)signature;

/**
 Opens the Beacon SDK from a specific view controller. The Beacon view controller
 will be presented as a modal.

 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 */
+ (void)openBeacon:(HSBeaconSettings *)settings fromViewController:(UIViewController *)viewController;

/**
 Opens the Beacon SDK from a specific view controller. The Beacon view controller
 will be presented as a modal.

 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 @param signature The signature to provide, if you are using secure mode.
 */
+ (void)openBeacon:(HSBeaconSettings *)settings fromViewController:(UIViewController *)viewController signature:(NSString *)signature;

/**
 Hides the SDK modal window if present. Useful for when the app is returning from the background.
 */
+ (void)dismissBeacon:(void (^ _Nullable)(void))completion;

/**
 Signs in with a Beacon user. This gives Beacon access to the user's name, email
 address, and signature.

 @param user The Beacon user to login
 */
+ (instancetype)login:(HSBeaconUser *)user DEPRECATED_MSG_ATTRIBUTE("Please use HSBeacon.identify instead");;

/**
 Signs in with a Beacon user. This gives Beacon access to the user's name, email
 address, and signature.

 @param user The Beacon user to identify
 */
+ (void)identify:(HSBeaconUser *)user;

/**
 Returns the current user, providing they are signed in.
 */
+ (HSBeaconUser * _Nullable)currentUser;

/**
 Logs the current Beacon user out and clears out their information from local
 storage.
 */
+ (void)logout;

//MARK: - Suggestions

/**
 Programmatically change the suggestted articles displayed. If the Beacon is visible,
 the change will take place right away. Otherwise, the article data will change on the
 next open.
 
 Passing in an empty array will restore the default list.
 
 @param articleIds An array of article ids to override suggestions
 */
+ (void)suggest:(NSArray <NSString *> *)articleIds;

/**
 Programmatically change the suggestted items displayed. This implementation accepts
 either `HSBeaconArticleSuggestion` or `HSBeaconLinkSuggestion` objects in the array.

 If the Beacon is visible the change will take place right away. Otherwise, the article
 data will change on the next open.

 Passing in an empty array will restore the default list.

 @param suggestions An array of HSBeaconArticleSuggestion or HSBeaconLinkSuggestion objects
 */
+ (void)suggestWithItems:(NSArray<id<HSBeaconSuggestionItem>> *)suggestions;

//MARK: - Push Notifications

/**
 Initializes push notifications for the Beacon SDK. This should be called if you
 intend to receive push notifications with a manual setup.
 */
+ (void)initializeBeaconPushNotificationSupport;

/**
 Initializes automatic push notification handling for the Beacon SDK.
 
 This will wrap the following methods on UIApplicationDelegage with method swizzling:
 
 application:didReceiveRemoteNotification:
 application:didRegisterForRemoteNotificationsWithDeviceToken:
 application:didFailToRegisterForRemoteNotificationsWithError:
 
 In addition, this wraps all of methods on UNUserNotificationCenterDelegate.
 
 @param methodSwizzling Whether to override push notification methods on the
 App Delegate.
 @param overrideDelegate Whether to override `UNUserNotificationCenter`'s delegate
 method for automatic handling of push notifications.
 */
+ (void)initializeAutomaticPushNotificationHandlingWithMethodSwizzling:(BOOL)methodSwizzling overrideUserNotificationCenterDelegate:(BOOL)overrideDelegate;

/**
 This lets Beacon know about the user's notification token, so the Beacon backend can
 send push notifications on behalf of the app. You only need to call this for manual
 push notification handling.
 */
+ (void)setDeviceToken:(NSData *)deviceToken;

/**
 This lets Beacon know that a potential device token is not forthcoming, so dependent processes can continue.
 You only need to call this for manual push notification handling.
*/
+ (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 Checks whether a given push notification came from Help Scout. You should call
 this method before calling `handlePushNotification:`.
 */
+ (BOOL)isBeaconPushNotification:(NSDictionary *)userInfo;

/**
 Handles a Beacon push notification. If the user info dictionary does not match
 the expected format, this method does nothing.

 @param userInfo The user info payload from the notification.
 @param settings The Beacon settings from which to load Beacon.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)handlePushNotification:(NSDictionary *)userInfo beaconSettings:(HSBeaconSettings *)settings;

/**
 Handles a Beacon push notification. If the user info dictionary does not match
 the expected format, this method does nothing.

 @param userInfo The user info payload from the notification.
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 */
+ (void)handlePushNotification:(NSDictionary *)userInfo beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController;

/**
 Handles a Beacon push notification. If the user info dictionary does not match
 the expected format, this method does nothing.

 @param userInfo The user info payload from the notification.
 @param settings The Beacon settings from which to load Beacon.
 @param signature The signature to provide, if you are using secure mode.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)handlePushNotification:(NSDictionary *)userInfo beaconSettings:(HSBeaconSettings *)settings signature:(NSString * _Nullable)signature;

/**
 Handles a Beacon push notification. If the user info dictionary does not match
 the expected format, this method does nothing.

 @param userInfo The user info payload from the notification.
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 @param signature The signature to provide, if you are using secure mode.
 */
+ (void)handlePushNotification:(NSDictionary *)userInfo beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController signature:(NSString * _Nullable)signature;

/**
 Determines whether or not a push notification should be shown to the user. The `completionHandler
 will only be called in the case that `UNNotfication` is a Beacon notification.

@param notification The UNNotification received by the UNUserNotificationCenterDelegate
@param completionHandler The completion block passed to the UNUnserNotificationCenterDelegate
@return A BOOL indicating if the completionHandler was called by Beacon. This will only return `true` if the push notification was a Beacon notification, otherwise `false`.
*/
+ (BOOL)handleWillPresentNotification:(UNNotification *)notification withCompletionHandler:(void(^)(UNNotificationPresentationOptions options))completionHandler;

//MARK: - Search
/**
 Opens the Beacon window to search results for the provided string.

 @param text The text to search with
 @param settings The Beacon settings from which to load Beacon.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)search:(NSString *)text beaconSettings:(HSBeaconSettings *)settings;

/**
 Opens the Beacon window to search results for the provided string.

 @param text The text to search with
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 */
+ (void)search:(NSString *)text beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController;

/**
 Opens the Beacon window to search results for the provided string.

 @param text The text to search with
 @param settings The Beacon settings from which to load Beacon.
 @param signature The signature to provide, if you are using secure mode.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)search:(NSString *)text beaconSettings:(HSBeaconSettings *)settings signature:(NSString * _Nullable)signature;

/**
 Opens the Beacon window to search results for the provided string.

 @param text The text to search with
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 @param signature The signature to provide, if you are using secure mode.
 */
+ (void)search:(NSString *)text  beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController signature:(NSString * _Nullable)signature;

//MARK: - Navigation
/**
 Navigates to a specific screen. Available routes are:
 "/" - welcome screen
 "/ask/message/" - message screen
 "/docs/search?query=help" - this is the same as the HSBeacon search method

 @param route The screen to navigate to - "/", "/ask/message", "/previous-messages", or "/docs/search?query=help"
 @param settings The Beacon settings from which to load Beacon.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)navigate:(NSString *)route beaconSettings:(HSBeaconSettings *)settings;

/**
 Navigates to a specific screen. Available routes are:
 "/" - welcome screen
 "/ask/message/" - message screen
 "/docs/search?query=help" - this is the same as the HSBeacon search method

 @param route The screen to navigate to - "/", "/ask/message", "/previous-messages", or "/docs/search?query=help"
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 */
+ (void)navigate:(NSString *)route beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController;

/**
 Navigates to a specific screen. Available routes are:
 "/" - welcome screen
 "/ask/message/" - message screen
 "/docs/search?query=help" - this is the same as the HSBeacon search method

 @param route The screen to navigate to - "/", "/ask/message", "/previous-messages", or "/docs/search?query=help"
 @param settings The Beacon settings from which to load Beacon.
 @param signature The signature to provide, if you are using secure mode.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)navigate:(NSString *)route beaconSettings:(HSBeaconSettings *)settings signature:(NSString * _Nullable)signature;

/**
 Navigates to a specific screen. Available routes are:
 "/" - welcome screen
 "/ask/message/" - message screen
 "/docs/search?query=help" - this is the same as the HSBeacon search method

 @param route The screen to navigate to - "/", "/ask/message", "/previous-messages", or "/docs/search?query=help"
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 @param signature The signature to provide, if you are using secure mode.
 */
+ (void)navigate:(NSString *)route beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController signature:(NSString * _Nullable)signature;


//MARK: - Open article
/**
You can use this method to open a specific Docs Article within Beacon, using the Article’s ID.

 @param articleId The id of the article to open up
 @param settings The Beacon settings from which to load Beacon.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)openArticle:(NSString *)articleId beaconSettings:(HSBeaconSettings *)settings;

/**
 You can use this method to open a specific Docs Article within Beacon, using the Article’s ID.

 @param articleId The id of the article to open up
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 */
+ (void)openArticle:(NSString *)articleId beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController;

/**
 You can use this method to open a specific Docs Article within Beacon, using the Article’s ID.

 @param articleId The id of the article to open up
 @param settings The Beacon settings from which to load Beacon.
 @param signature The signature to provide, if you are using secure mode.

 @note Displays Beacon from the application delegate's window root view controller.
 */
+ (void)openArticle:(NSString *)articleId beaconSettings:(HSBeaconSettings *)settings signature:(NSString * _Nullable)signature;

/**
 You can use this method to open a specific Docs Article within Beacon, using the Article’s ID.

 @param articleId The id of the article to open up
 @param settings The Beacon settings from which to load Beacon.
 @param viewController The view controller to display Beacon from.
 @param signature The signature to provide, if you are using secure mode.
 */
+ (void)openArticle:(NSString *)articleId beaconSettings:(HSBeaconSettings *)settings viewController:(UIViewController *)viewController signature:(NSString * _Nullable)signature;

/**
 Resets the contact form by clearing all of its fields, custom fields and attachments. If your Beacon is in Normal Mode, calling reset will clear all contact form fields, including name and email address.

 If your Beacon is in Secure Mode, calling reset will not clear the customer’s name or email address. Those inputs will remain hidden.
 */
+ (void)reset;

//MARK: - Unavailable Methods

/**
 `-[HSBeacon init]` is not available because `HSBeacon` cannot be created directly.
 Use the `openBeacon:` methods to display the Beacon SDK.
 */
- (instancetype)init __attribute__((unavailable("HSBeacon cannot be created directly")));

@end

NS_ASSUME_NONNULL_END

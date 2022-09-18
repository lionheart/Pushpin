#import <Foundation/Foundation.h>
@import UserNotifications;

typedef void(^VoidBlock)(void);

@class HSBeacon;
@class HSBeaconContext;
@class HSBeaconSettings;

@interface HSBeaconPushNotificationSupport : NSObject

@property (nonatomic, weak, nullable) HSBeaconContext *context;
@property (nonatomic, strong, nullable) NSData *token;
@property (nonatomic, assign, readonly) BOOL isSubscribedToBeaconNotifications;
@property (nonatomic, assign) BOOL shouldPresentChatNotifications;

- (void)initializeBeaconPushNotificationSupport;

- (void)registerForPushNotifications;
- (void)failedToRegisterForRemoteNotificationsWithError:(nullable NSError *)error;

- (void)configurePushNotificationHandlingWithSwizzling:(BOOL)swizzling overrideUserNotificationDelegate:(BOOL)overrideDelegate;

- (BOOL)handleWillPresentNotification:(UNNotification *_Nonnull)notification withCompletionHandler:(void(^_Nonnull)(UNNotificationPresentationOptions options))completionHandler;

/**
 When we need to subscribe to a conversation for the first time, we need to ask
 the user for permission to send push notifications. However, because of the
 delegate method approach for receiving the push notification, we can't simply
 call our subscribe method inside of a completion block once the user has made a
 decision.

 Instead, we hang on to the conversation ID to which we wish to subscribe, and
 wait for the user to make a decision on push notifications.
 */
- (void)subscribeToPushNotificationsForConversationWithID:(NSString *_Nonnull)conversationID;

- (void)subscribeToPushNotificationsForChatWithEmail:(NSString *_Nonnull)email withCompletionHandler:(nullable VoidBlock)completion;

@end

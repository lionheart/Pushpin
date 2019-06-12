#import <Foundation/Foundation.h>

@class HSBeacon;
@class HSBeaconContext;
@class HSBeaconSettings;

@interface HSBeaconPushNotificationSupport : NSObject

@property (nonatomic, weak) HSBeaconContext *context;
@property (nonatomic, strong) NSData *token;

- (void)initializeBeaconPushNotificationSupport;

- (void)registerForPushNotifications;

- (void)configurePushNotificationHandlingWithSwizzling:(BOOL)swizzling overrideUserNotificationDelegate:(BOOL)overrideDelegate;

/**
 When we need to subscribe to a conversation for the first time, we need to ask
 the user for permission to send push notifications. However, because of the
 delegate method approach for receiving the push notification, we can't simply
 call our subscribe method inside of a completion block once the user has made a
 decision.

 Instead, we hang on to the conversation ID to which we wish to subscribe, and
 wait for the user to make a decision on push notifications.
 */
- (void)subscribeToPushNotificationsForConversationWithID:(NSString *)conversationID;

@end

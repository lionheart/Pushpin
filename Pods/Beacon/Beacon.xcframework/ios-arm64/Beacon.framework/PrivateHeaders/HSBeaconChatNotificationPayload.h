#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HSBeaconChatNotificationType) {
    HSBeaconChatNotificationTypeUnknown,
    HSBeaconChatNotificationTypeChatAgentReply,
    HSBeaconChatNotificationTypeChatInactivity,
    HSBeaconChatNotificationTypeChatEnded
};

@interface HSBeaconChatNotificationPayload : NSObject

@property (nonatomic, strong, nonnull) NSString *chatID;
@property (nonatomic, assign) HSBeaconChatNotificationType notificationType;

- (nullable instancetype)initWithUserInfo:(NSDictionary *_Nullable)userInfo;

@end

#import <Foundation/Foundation.h>

#import "HSBeaconReplyNotificationPayload.h"
#import "HSBeaconChatNotificationPayload.h"
#import "HSBeaconConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconNotificationPayload : NSObject

@property (nonatomic, strong, nullable) NSString *action;
@property (nonatomic, strong, nullable) HSBeaconReplyNotificationPayload *replyPayload;
@property (nonatomic, strong, nullable) HSBeaconChatNotificationPayload *chatPayload;

- (nullable instancetype)initWithUserInfo:(NSDictionary *)userInfo;

- (HSBeaconConversation *_Nullable)toConversation;

@end

NS_ASSUME_NONNULL_END

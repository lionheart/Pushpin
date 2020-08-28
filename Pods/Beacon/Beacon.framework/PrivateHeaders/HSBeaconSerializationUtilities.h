#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconSerializationUtilities : NSObject

+ (void)saveConversationID:(NSString *)conversationID mappedToBeaconID:(NSString *)beaconID;
+ (void)saveChatID:(NSUUID *)chatId mappedToBeaconID:(NSString *)beaconID;

+ (nullable NSString *)beaconIDForConversationID:(nullable NSNumber *)conversationID;
+ (nullable NSString *)beaconIDForChatID:(nullable NSString *)chatID;

+ (BOOL)isBeaconInitialized;

+ (void)setBeaconInitialized;

@end

NS_ASSUME_NONNULL_END

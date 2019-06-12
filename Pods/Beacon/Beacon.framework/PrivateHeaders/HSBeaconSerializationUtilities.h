#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconSerializationUtilities : NSObject

+ (void)saveConversationID:(NSString *)conversationID mappedToBeaconID:(NSString *)beaconID;

+ (nullable NSString *)beaconIDForConversationID:(NSNumber *)conversationID;

+ (BOOL)isBeaconInitialized;

+ (void)setBeaconInitialized;

@end

NS_ASSUME_NONNULL_END

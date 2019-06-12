#import <Foundation/Foundation.h>
#import "HSBeaconAgent.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconChatTranscriptEvent : NSObject

@property (readonly, nonatomic) NSDate *createdAt;

@property (readonly, nonatomic) NSString *body;

@property (readonly, nonatomic, nullable) NSArray *attachments;

@property (readonly, nonatomic, nullable) HSBeaconAgent *agent;

@property (readonly, nonatomic) NSString *createdByType;

- (_Nonnull instancetype)initWithDictionary:(NSDictionary *)dictionary agent:(HSBeaconAgent * _Nullable)agent;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

#import <Beacon/HSBeaconChatTranscriptEvent.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconChatTranscript : NSObject

@property NSArray<HSBeaconChatTranscriptEvent *> *events;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END

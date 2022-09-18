#import <UIKit/UIKit.h>

#import <Beacon/HSBeaconAgent.h>

@class HSBeaconConversationThread;

typedef NS_ENUM (NSInteger, HSBeaconConversationThreadCreatorType) {
    HSBeaconConversationThreadCreatorUser,
    HSBeaconConversationThreadCreatorCustomer,
    HSBeaconConversationThreadCreatorSelf
};

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconConversation : NSObject

@property (readonly, nonatomic) long conversationId;

@property (readonly, nonatomic) NSString *subject;

@property (readonly, nonatomic) int threadCount;

@property (readonly, nonatomic) NSDate *lastUpdated;

@property (readonly, nonatomic, nullable) NSString *lastThreadPreview;

@property (nonatomic, assign, readonly) BOOL customerViewed;

@property (nonatomic, assign, readonly) HSBeaconConversationThreadCreatorType lastThreadCreatorType;

@property (readonly, nonatomic) BOOL waitingForReply;

@property (readonly, nonatomic) NSArray<HSBeaconAgent *> *agents;

@property (readonly, nonatomic, nullable) NSDictionary *linkedArticleIds;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

-(BOOL)hasMultipleThreads;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

#import "HSBeaconAgent.h"
#import "HSBeaconChatTranscript.h"
#import "HSBeaconChatTranscriptEvent.h"
#import "HSBeaconLocalizedStrings.h"

typedef NS_ENUM (NSInteger, HSBeaconTheadType) {
    HSBeaconThreadMessage, HSBeaconThreadChat
};

@interface HSBeaconConversationThread : NSObject

@property (readonly, nonatomic) long threadId;

@property (readonly, nonatomic) NSDate *createdAt;

@property (readonly, nonatomic) NSString *body;

@property (readonly, nonatomic) NSArray *attachments;

@property (readonly, nonatomic) NSString *createdByType;

@property (readonly, nonatomic) HSBeaconTheadType threadType;

@property (readonly, nonatomic) HSBeaconAgent *agent;

@property (readonly, nonatomic, getter=isNewThread) BOOL newThread;

@property (readonly, nonatomic) HSBeaconChatTranscript *chatTranscript;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

-(instancetype)initWithChatTranscriptEvent:(HSBeaconChatTranscriptEvent *)event;

-(NSArray<HSBeaconConversationThread *> *)chatTranscriptAsThreads;

-(NSString *)timeago:(id<HSBeaconStringLocalizer>)localizedStrings;

@end

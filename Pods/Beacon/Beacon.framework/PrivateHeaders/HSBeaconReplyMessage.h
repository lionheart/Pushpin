#import <Foundation/Foundation.h>

#import "HSBeaconAttachment.h"

@interface HSBeaconReplyMessage : NSObject

@property(readonly, nonatomic) long conversationId;
@property(strong, nonatomic) NSString *text;
@property(strong, nonatomic) NSArray<HSBeaconAttachment *> *attachments;

-(instancetype)initWithConversationId:(long)conversationId;

-(NSDictionary *)toDictionary;

@end

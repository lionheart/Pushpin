#import <Foundation/Foundation.h>

#import "HSBeaconConversation.h"
#import "HSBeaconPaging.h"

@interface HSBeaconPreviousMessagesResponse : NSObject

@property(readonly, nonatomic) NSArray<HSBeaconConversation *> *results;
@property(readonly, nonatomic) HSBeaconPaging *paging;

-(instancetype)initWithResults: (NSArray<HSBeaconConversation *> *)results paging: (HSBeaconPaging *)paging;

@end

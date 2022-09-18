#import <Foundation/Foundation.h>

#import "HSBeaconConversationThread.h"
#import "HSBeaconPaging.h"

@interface HSBeaconConversationThreadsResponse : NSObject

@property(readonly, nonatomic) NSArray<HSBeaconConversationThread *> *results;
@property(readonly, nonatomic) HSBeaconPaging *paging;

-(instancetype)initWithResults: (NSArray<HSBeaconConversationThread *> *)results paging: (HSBeaconPaging *)paging;

@end

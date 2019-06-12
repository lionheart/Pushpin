#import <Foundation/Foundation.h>

#import "HSBeaconPaging.h"

@interface HSBeaconPaginatedResponse: NSObject

@property(readonly, nonatomic) NSArray *results;
@property(readonly, nonatomic) HSBeaconPaging *paging;

-(instancetype)initWithResults: (NSArray *)results paging: (HSBeaconPaging *)paging;

@end

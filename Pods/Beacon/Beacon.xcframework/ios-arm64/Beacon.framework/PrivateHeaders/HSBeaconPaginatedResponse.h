#import <Foundation/Foundation.h>

#import <Beacon/HSBeaconPaging.h>

@interface HSBeaconPaginatedResponse: NSObject

@property(readonly, nonatomic) NSArray *results;
@property(readonly, nonatomic) HSBeaconPaging *paging;

-(instancetype)initWithResults: (NSArray *)results paging: (HSBeaconPaging *)paging;

@end

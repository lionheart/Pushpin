#import <Foundation/Foundation.h>

@interface HSBeaconPaging: NSObject

@property (readonly, nonatomic) int page;
@property (readonly, nonatomic) int pageSize;
@property (readonly, nonatomic) int numberOfPages;
@property (readonly, nonatomic, getter=isLastPage) BOOL lastPage;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

-(instancetype)initFirstPageWithTotalCount:(int)count pageSize:(int)pageSize;

- (BOOL)shouldLoadOldestThread;

@end

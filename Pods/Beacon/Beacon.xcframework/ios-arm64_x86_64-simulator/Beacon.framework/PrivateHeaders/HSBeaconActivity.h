#import <Foundation/Foundation.h>

@interface HSBeaconActivity: NSObject

@property(readonly, nonatomic) NSString *type;
@property(readonly, nonatomic) NSDate *timestamp;
@property(readonly, nonatomic) NSDictionary *attributes;

-(instancetype)initWithType: (NSString *)type attributes: (NSDictionary *)attributes;

-(NSDictionary *)asDictionary;

@end

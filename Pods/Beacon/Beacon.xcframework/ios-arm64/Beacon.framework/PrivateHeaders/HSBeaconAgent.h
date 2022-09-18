#import <Foundation/Foundation.h>

@interface HSBeaconAgent: NSObject

@property (readonly, nonatomic) long agentId;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *initials;
@property (readonly, nonatomic) NSURL *imageUrl;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

@end

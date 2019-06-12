#import <Foundation/Foundation.h>

@interface HSBeaconExpiryCache : NSObject

-(instancetype)initWithExpiryTime:(NSTimeInterval)expiryTime;

-(void)setObject:(id)object forKey:(id)key;

-(id)objectForKey:(id)key;

@end

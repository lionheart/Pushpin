#import <Foundation/Foundation.h>

#import "HSBeaconContext.h"

@protocol HSBeaconContextSupport <NSObject>

-(void)setBeaconContext:(HSBeaconContext *)context;

@end


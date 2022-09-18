#import <Foundation/Foundation.h>

@class HSBeaconRouting;

typedef void(^FinishedBlock)(BOOL finished);

NS_ASSUME_NONNULL_BEGIN

@protocol HSBeaconRoutingFulfilling <NSObject>

- (void)fulfillRouting:(HSBeaconRouting *)routing completion:(nullable FinishedBlock)completion;

@end

NS_ASSUME_NONNULL_END

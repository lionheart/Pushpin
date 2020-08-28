#import <UIKit/UIKit.h>
#import "HSViewController.h"

@class HSCardStackViewController;

@protocol HSCardStackEmbeddable
@property (nonatomic, weak) HSCardStackViewController * _Nullable cardViewController;
@end

NS_ASSUME_NONNULL_BEGIN

@interface HSCardStackViewController : HSViewController

- (instancetype)initWithCard:(UIViewController<HSCardStackEmbeddable> *)card;

- (void)presentCard:(UIViewController<HSCardStackEmbeddable> *)card;

@end

NS_ASSUME_NONNULL_END

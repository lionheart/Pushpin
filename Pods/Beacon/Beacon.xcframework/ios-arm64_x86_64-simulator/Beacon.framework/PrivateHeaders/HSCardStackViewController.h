#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>
#import <Beacon/HSCardStackEmbeddable.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSCardStackViewController : HSViewController

- (instancetype)initWithCard:(UIViewController<HSCardStackEmbeddable> *)card;

@property (nonatomic, assign) BOOL animateCardPresentation;

- (void)presentCard:(UIViewController<HSCardStackEmbeddable> *)card animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

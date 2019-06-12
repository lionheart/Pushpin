#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconLoadingViewController : UIViewController

@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

+ (instancetype)instantiateViewController;

- (void)displayLoadingViewInsideViewController:(UIViewController *)hostingViewController visible:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END

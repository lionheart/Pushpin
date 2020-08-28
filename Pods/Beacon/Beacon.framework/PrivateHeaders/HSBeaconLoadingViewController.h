#import <UIKit/UIKit.h>
#import "HSViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconLoadingViewController : HSViewController

@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

+ (instancetype)instantiateViewController;

- (void)displayLoadingViewInsideViewController:(UIViewController *)hostingViewController visible:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END

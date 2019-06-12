#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HSBorderedButton;

@interface HSStatusMessageViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *viewTopConstraint; // For assigning to a Safe Area layout guide
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleTopConstraint;
@property (nonatomic, weak) IBOutlet HSBorderedButton *actionButton;

- (instancetype)initWithMessage:(NSString *)errorString;

- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message;

- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message image:(nullable UIImage *)image;

- (void)showStatusInViewController:(UIViewController *)viewController;

- (void)removeStatus;

@end

NS_ASSUME_NONNULL_END

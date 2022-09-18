#import <UIKit/UIKit.h>
#import <Beacon/HSViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class HSBorderedButton;
@class HSBeaconContext;

typedef void(^VoidBlock)(void);

@interface HSStatus : NSObject

@property (nonatomic, readonly, nullable) NSString *title;
@property (nonatomic, readonly, nonnull) NSString *message;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly, nullable) NSString *actionTitle;
@property (nonatomic, readonly, nullable) VoidBlock action;

- (instancetype)initWithMessage:(NSString *)errorString;
- (instancetype)initWithMessage:(NSString *)message image:(UIImage *)image;
- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message;
- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message image:(nullable UIImage *)image;
- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message image:(nullable UIImage *)image actionTitle:(nullable NSString *)actionTitle action:(nullable VoidBlock)action;

@end

@interface HSStatusMessageViewController : HSViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleTopConstraint;
@property (nonatomic, weak) IBOutlet HSBorderedButton *actionButton;
@property (nonatomic) BOOL shouldSuppressCloseButton;

- (instancetype)initWithStatus:(HSStatus *)status context:(HSBeaconContext *)context;

- (void)showStatusInViewController:(UIViewController *)viewController;

- (void)removeStatus;
- (void)updateForStatus:(HSStatus *)status;

@end

NS_ASSUME_NONNULL_END

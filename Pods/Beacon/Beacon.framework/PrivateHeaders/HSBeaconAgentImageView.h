#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconAgent.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconAgentImageView: HSView

@property (nonatomic, assign) BOOL dropShadow;

- (void)setAgent:(HSBeaconAgent *)agent backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor initialsColor:(UIColor *)initialsColor;
- (void)setAgentAvatar:(NSURL *_Nullable)avatarURL initials:(NSString *)initials backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor initialsColor:(UIColor *)initialsColor;

@end

NS_ASSUME_NONNULL_END

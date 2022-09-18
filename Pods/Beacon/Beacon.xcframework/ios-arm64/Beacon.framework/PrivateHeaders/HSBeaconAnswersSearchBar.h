#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconAnswersSearchBar : UISearchBar

@property (nonatomic, strong) UIColor *beaconColor;

-(void)setCenteredPlaceholder:(NSString *)placeholder;

@end

NS_ASSUME_NONNULL_END

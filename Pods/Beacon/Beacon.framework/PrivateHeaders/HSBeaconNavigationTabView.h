#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconFontIcons.h"

@class HSBeaconNavigationTabView;

@protocol HSBeaconNavigationTabViewDelegate <NSObject>

- (void)beaconNavigationTabView:(HSBeaconNavigationTabView *)tabView didSelectTabAtIndex:(NSUInteger)index;

@end

@interface HSBeaconNavigationTabView : HSView

@property (nonatomic, assign, readonly) NSUInteger selectedIndex;
@property (nonatomic, weak) id<HSBeaconNavigationTabViewDelegate> delegate;

- (void)addTab:(HSIcon)icon text:(NSString *)text pressed:(BOOL)pressed tabColor:(UIColor *)color;

@end

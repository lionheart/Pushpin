#import <UIKit/UIKit.h>
#import <Beacon/HSView.h>

@class HSBeaconNavigationTabView;

@protocol HSBeaconNavigationTabViewDelegate <NSObject>

- (void)beaconNavigationTabView:(HSBeaconNavigationTabView *)tabView didSelectTabAtIndex:(NSUInteger)index;

@end

@interface HSBeaconNavigationTabView : HSView

@property (nonatomic, assign, readonly) NSUInteger selectedIndex;
@property (nonatomic, weak) id<HSBeaconNavigationTabViewDelegate> delegate;

- (void)addImageTab:(UIImage *)icon text:(NSString *)text pressed:(BOOL)pressed tabColor:(UIColor *)color;
- (void)reflectActiveIndex:(NSUInteger)index;

@end

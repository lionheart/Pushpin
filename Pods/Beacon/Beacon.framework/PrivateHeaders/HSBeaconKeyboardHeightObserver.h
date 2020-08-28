#import <UIKit/UIKit.h>

@protocol HSBeaconKeyboardHeightObserverDelegate

-(void)keyboardHeightChanged:(CGFloat)keyboardHeight;

@end


@interface HSBeaconKeyboardHeightObserver : NSObject

@property(nonatomic, readonly) BOOL observing;

@property(nonatomic, readonly, weak) UIView *view;

@property(nonatomic, weak) id<HSBeaconKeyboardHeightObserverDelegate> delegate;

-(instancetype)initWithView:(UIView *)view;

-(void)startObserving;

-(void)stopObserving;

@end

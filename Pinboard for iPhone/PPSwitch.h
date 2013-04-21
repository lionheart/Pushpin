//
//  PPSwitch.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 4/21/13.
//
//

#import <UIKit/UIKit.h>

@interface PPSwitch : UIControl

@property (nonatomic, strong) UIImageView *onImageView;
@property (nonatomic, strong) UIImageView *offImageView;
@property (nonatomic) BOOL on;

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event;

@end

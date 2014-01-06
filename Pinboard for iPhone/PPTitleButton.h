//
//  PPTitleButton.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

#import <UIKit/UIKit.h>

@class PPTitleButton;

@protocol PPTitleButtonDelegate <NSObject>

@required

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton;

@end

@interface PPTitleButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, weak) id<PPTitleButtonDelegate> delegate;

+ (instancetype)button;
+ (instancetype)buttonWithDelegate:(id<PPTitleButtonDelegate>)delegate;
- (void)setTitle:(NSString *)title imageName:(NSString *)imageName;

@end

//
//  PPTitleButton.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

@import UIKit;

@class PPTitleButton;

@protocol PPTitleButtonDelegate <NSObject>

@required

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton;
- (void)titleButtonLongPress:(PPTitleButton *)titleButton;

@end

@interface PPTitleButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, weak) id<PPTitleButtonDelegate> delegate;

+ (instancetype)button;
+ (instancetype)buttonWithDelegate:(id<PPTitleButtonDelegate>)delegate;
- (void)setTitle:(NSString *)title imageName:(NSString *)imageName;
- (void)setImageNames:(NSArray *)imageNames;
- (void)setImageNames:(NSArray *)imageNames title:(NSString *)title;

@end

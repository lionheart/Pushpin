//
//  PPBadgeView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>

@interface PPBadgeView : UIView

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *textLabel;

- (id)initWithImage:(UIImage *)image;
- (id)initWithText:(NSString *)text;

@end

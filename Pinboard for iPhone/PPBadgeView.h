//
//  PPBadgeView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>

static const NSString *PPBadgeFontSize = @"fontSize";
static const NSString *PPBadgeBackgroundColor = @"backgrounColor";

@interface PPBadgeView : UIView

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *textLabel;

- (id)initWithImage:(UIImage *)image;
- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text options:(NSDictionary *)options;

@end

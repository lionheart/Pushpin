//
//  PPGroupedTableViewCell.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import <UIKit/UIKit.h>

@interface PPGroupedTableViewCell : UITableViewCell

+ (CALayer *)topRectangleLayer;
+ (CALayer *)bottomRectangleLayer;
+ (CALayer *)baseLayerForSelectedBackground;
+ (CALayer *)topRectangleLayerForHeight:(CGFloat)height;
+ (CALayer *)bottomRectangleLayerForHeight:(CGFloat)height;
+ (CALayer *)baseLayerForSelectedBackgroundForHeight:(CGFloat)height;
+ (CALayer *)layerForNonGroupedBackground;
- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer;
- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer forHeight:(CGFloat)height;

@end

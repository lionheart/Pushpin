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
- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer;

@end

//
//  PPGroupedTableViewCell.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "UIApplication+AppDimensions.h"

@implementation PPGroupedTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = nil;
        self.textLabel.highlightedTextColor = HEX(0x33353BFF);
        self.textLabel.textColor = HEX(0x33353BFF);
        self.textLabel.font = [UIFont fontWithName:[PPTheme heavyFontName] size:17];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

+ (CALayer *)baseLayerForSelectedBackgroundForHeight:(CGFloat)height {
    CALayer *selectedBackgroundLayer = [CALayer layer];
    selectedBackgroundLayer.frame = CGRectMake(0, 0, [UIApplication currentSize].width - 18, height);
    selectedBackgroundLayer.cornerRadius = 10;
    selectedBackgroundLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return selectedBackgroundLayer;
}

+ (CALayer *)bottomRectangleLayerForHeight:(CGFloat)height {
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, height - 10, [UIApplication currentSize].width - 18, 10);
    layer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return layer;
}

+ (CALayer *)topRectangleLayerForHeight:(CGFloat)height {
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, [UIApplication currentSize].width - 18, 10);
    layer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return layer;
}

- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer forHeight:(CGFloat)height {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width, height)];
    [selectedBackgroundView.layer addSublayer:layer];
    selectedBackgroundView.layer.masksToBounds = YES;
    self.selectedBackgroundView = selectedBackgroundView;
}

- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer {
    [self setSelectedBackgroundViewWithLayer:layer forHeight:44];
}

+ (CALayer *)topRectangleLayer {
    return [PPGroupedTableViewCell topRectangleLayerForHeight:44];
}

+ (CALayer *)bottomRectangleLayer {
    return [PPGroupedTableViewCell bottomRectangleLayerForHeight:44];
}

+ (CALayer *)baseLayerForSelectedBackground {
    return [PPGroupedTableViewCell baseLayerForSelectedBackgroundForHeight:44];
}

+ (CALayer *)layerForNonGroupedBackground {
    CALayer *selectedBackgroundLayer = [CALayer layer];
    selectedBackgroundLayer.frame = CGRectMake(0, 0, [UIApplication currentSize].width, 44);
    selectedBackgroundLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return selectedBackgroundLayer;
}

@end

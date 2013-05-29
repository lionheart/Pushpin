//
//  PPGroupedTableViewCell.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation PPGroupedTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = nil;
        self.textLabel.highlightedTextColor = HEX(0x33353BFF);
        self.textLabel.textColor = HEX(0x33353BFF);
        self.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setSelectedBackgroundViewWithLayer:(CALayer *)layer {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [selectedBackgroundView.layer addSublayer:layer];
    selectedBackgroundView.layer.masksToBounds = YES;
    self.selectedBackgroundView = selectedBackgroundView;
}

+ (CALayer *)topRectangleLayer {
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 302, 10);
    layer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return layer;
}

+ (CALayer *)bottomRectangleLayer {
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 34, 302, 10);
    layer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return layer;
}

+ (CALayer *)baseLayerForSelectedBackground {
    CALayer *selectedBackgroundLayer = [CALayer layer];
    selectedBackgroundLayer.frame = CGRectMake(0, 0, 302, 44);
    selectedBackgroundLayer.cornerRadius = 10;
    selectedBackgroundLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    return selectedBackgroundLayer;
}

@end

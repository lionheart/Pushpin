//
//  PPBrowseCell.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/12/13.
//
//

#import "PPBrowseCell.h"

@implementation PPBrowseCell

@synthesize badgeText;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.badgeText) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGSize badgeTextSize = [self.badgeText sizeWithFont:[UIFont boldSystemFontOfSize:13.]];
        CGRect badgeViewFrame = CGRectIntegral(CGRectMake(rect.size.width - badgeTextSize.width - 24, (rect.size.height - badgeTextSize.height - 4) / 2, badgeTextSize.width + 14, badgeTextSize.height + 4));

        [self.badgeText drawInRect:CGRectMake(0, 0, 40, 40) withFont:[UIFont boldSystemFontOfSize:13.]];
    }
}

@end

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
        [self.badgeText drawInRect:CGRectMake(0, 0, 40, 40) withFont:[UIFont boldSystemFontOfSize:13.]];
    }
}

@end

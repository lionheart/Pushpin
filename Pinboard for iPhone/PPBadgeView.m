//
//  PPBadgeView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeView.h"
#import <QuartzCore/QuartzCore.h>

@implementation PPBadgeView

static const CGFloat PADDING_X = 4.0f;
static const CGFloat PADDING_Y = 2.0f;

@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithImage:image];
        
        // Calculate our frame
        [self addSubview:self.imageView];
        self.frame = CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height);
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        self.layer.cornerRadius = 1.0f;
        self.layer.backgroundColor = HEX(0x73c5ffff).CGColor;
        
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.text = [text lowercaseString];
        self.textLabel.font = [UIFont systemFontOfSize:10.0f];
        self.textLabel.textColor = [UIColor whiteColor];
        
        // Calculate our frame
        CGSize size = [text sizeWithAttributes:@{ NSFontAttributeName: self.textLabel.font }];
        self.frame = CGRectMake(0, 0, size.width + (PADDING_X * 2), size.height + (PADDING_Y * 2));
        self.textLabel.frame = CGRectMake(PADDING_X, PADDING_Y, size.width, size.height);
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (!self.imageView.image) {
        [super setBackgroundColor:HEX(0x73c5ffff)];
    } else {
        [super setBackgroundColor:backgroundColor];
    }
}

@end

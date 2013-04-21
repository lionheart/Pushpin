//
//  PPSwitch.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 4/21/13.
//
//

#import "PPSwitch.h"
#import "PPCoreGraphics.h"

@implementation PPSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 62, 40)];
    if (self) {
        self.onImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SwitchOn"]];
        self.offImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SwitchOff"]];
        self.onImageView.frame = CGRectMake(0, 8, 60, 23);
        self.offImageView.frame = CGRectMake(32, 8, 60, 23);
        self.onImageView.alpha = 1;
        self.offImageView.alpha = 0;
        
        [self addSubview:self.onImageView];
        [self addSubview:self.offImageView];

        UIGraphicsBeginImageContext(self.frame.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextAddRect(context, self.frame);
        CGContextClosePath(context);

        CGContextAddRoundedRect(context, CGRectMake(0, 8, 60, 23), 11.5);
        CGContextSetFillColorWithColor(context, HEX(0xF7F7F7FF).CGColor);
        CGContextEOFillPath(context);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        [self addSubview:[[UIImageView alloc] initWithImage:image]];
        
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (BOOL)on {
    return self.onImageView.frame.origin.x >= -16;
}

- (void)setOn:(BOOL)on {
    if (!on) {
        self.offImageView.frame = CGRectMake(32, 8, 60, 23);
        self.onImageView.frame = CGRectMake(0, 8, 60, 23);
        self.onImageView.alpha = 1;
        self.offImageView.alpha = 0;
    }
    else {
        self.offImageView.frame = CGRectMake(0, 8, 60, 23);
        self.onImageView.frame = CGRectMake(-32, 8, 60, 23);
        self.onImageView.alpha = 0;
        self.offImageView.alpha = 1;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.on) {
        [UIView animateWithDuration:0.2 animations:^{
            self.offImageView.frame = CGRectMake(32, 8, 60, 23);
            self.onImageView.frame = CGRectMake(0, 8, 60, 23);
            self.onImageView.alpha = 1;
            self.offImageView.alpha = 0;
        }];
    }
    else {
        [UIView animateWithDuration:0.2 animations:^{
            self.offImageView.frame = CGRectMake(0, 8, 60, 23);
            self.onImageView.frame = CGRectMake(-32, 8, 60, 23);
            self.onImageView.alpha = 0;
            self.offImageView.alpha = 1;
        }];
    }
}

@end

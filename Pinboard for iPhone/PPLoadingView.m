//
//  PPLoadingView.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/17/13.
//
//

#import "PPLoadingView.h"

@implementation PPLoadingView

- (void)startAnimating {
    NSMutableArray *images = [NSMutableArray array];
    for (int i=1; i<81; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading_%02d", i]]];
    }

    self.animationImages = images;
    self.animationDuration = 3;
    [super startAnimating];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(40, 40);
}

@end

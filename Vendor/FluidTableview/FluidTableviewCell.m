//
//  FluidTableviewCell.m
//  FluidTableview
//
//  Created by Andy Muldowney on 9/30/13.
//  Copyright (c) 2013 Andy Muldowney. All rights reserved.
//

#import "FluidTableviewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation FluidTableviewCell

- (void)drawRect:(CGRect)rect
{
    self.layer.cornerRadius = 5.0f;
}

@end

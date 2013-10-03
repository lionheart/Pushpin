//
//  FluidTableviewFlowLayout.h
//  FluidTableview
//
//  Created by Andy Muldowney on 9/30/13.
//  Copyright (c) 2013 Andy Muldowney. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluidTableviewBehaviorManager.h"

@interface FluidTableviewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) FluidTableviewBehaviorManager *behaviorManager;
@property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;
@property (nonatomic, assign) CGFloat latestDelta;

- (id)initWithItemSize:(CGSize)size;

@end

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

@property (nonatomic) CGSize itemSize;
@property (nonatomic, retain) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, retain) FluidTableviewBehaviorManager *behaviorManager;

- (id)initWithItemSize:(CGSize)size;

@end

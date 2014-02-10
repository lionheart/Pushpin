//
//  FluidTableviewBehaviorManager.h
//  FluidTableview
//
//  Created by Andy Muldowney on 9/30/13.
//  Copyright (c) 2013 Andy Muldowney. All rights reserved.
//

@import Foundation;

@import UIKit;

@interface FluidTableviewBehaviorManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *attachmentBehaviors;
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
@property (nonatomic, strong) UIDynamicAnimator *animator;

- (instancetype)initWithAnimator:(UIDynamicAnimator *)animator;

- (void)addItem:(UICollectionViewLayoutAttributes *)item anchor:(CGPoint)anchor;
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateItemCollection:(NSArray*)items;

- (NSArray *)currentlyManagedItemIndexPaths;

@end

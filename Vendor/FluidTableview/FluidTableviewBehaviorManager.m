//
//  FluidTableviewBehaviorManager.m
//  FluidTableview
//
//  Created by Andy Muldowney on 9/30/13.
//  Copyright (c) 2013 Andy Muldowney. All rights reserved.
//
//  Portions of this code are derived from samples at:
//      http://www.shinobicontrols.com/blog/posts/2013/09/26/ios7-day-by-day-day-5-uidynamics-with-collection-views/
//

#import "FluidTableviewBehaviorManager.h"

@implementation FluidTableviewBehaviorManager

@synthesize attachmentBehaviors = _attachmentBehaviors;
@synthesize gravityBehavior = _gravityBehavior;
@synthesize collisionBehavior = _collisionBehavior;
@synthesize animator = _animator;

- (instancetype)initWithAnimator:(UIDynamicAnimator *)animator
{
    self = [super init];
    if(self) {
        _animator = animator;
        _attachmentBehaviors = [NSMutableDictionary dictionary];
        [self createGravityBehavior];
        [self createCollisionBehavior];
        //
        [self.animator addBehavior:self.gravityBehavior];
        [self.animator addBehavior:self.collisionBehavior];
    }
    return self;
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove the attachment behavior from the animator
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[indexPath];
    [self.animator removeBehavior:attachmentBehavior];
    
    // Remove the item from the behaviors
    for(UICollectionViewLayoutAttributes *attr in [self.gravityBehavior.items copy]) {
        if([attr.indexPath isEqual:indexPath]) {
            [self.gravityBehavior removeItem:attr];
        }
    }
    
    for (UICollectionViewLayoutAttributes *attr in [self.collisionBehavior.items copy]) {
        if([attr.indexPath isEqual:indexPath]) {
            [self.collisionBehavior removeItem:attr];
        }
    }
    
    // Clean up the master dictionary of attachment behaviors
    [_attachmentBehaviors removeObjectForKey:indexPath];
}

- (void)updateItemCollection:(NSArray *)items
{
    // Find items to remove
    NSMutableSet *toRemove = [NSMutableSet setWithArray:[self.attachmentBehaviors allKeys]];
    [toRemove minusSet:[NSSet setWithArray:[items valueForKeyPath:@"indexPath"]]];
    
    // Remove items we no longer need
    for (NSIndexPath *indexPath in toRemove) {
        [self removeItemAtIndexPath:indexPath];
    }
    
    // Find the items we need to add springs to
    NSArray *existingIndexPaths = [self currentlyManagedItemIndexPaths];
    for(UICollectionViewLayoutAttributes *attr in items) {
        // Find whether this item matches an existing index path
        BOOL alreadyExists = NO;
        for(NSIndexPath *indexPath in existingIndexPaths) {
            if ([indexPath isEqual:attr.indexPath]) {
                alreadyExists = YES;
            }
        }
        
        // No existing indexPath match
        if(!alreadyExists) {
            [self addItem:attr anchor:attr.center];
        }
    }
}

- (NSArray *)currentlyManagedItemIndexPaths
{
    return [[_attachmentBehaviors allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if([(NSIndexPath*)obj1 item] < [(NSIndexPath*)obj2 item]) {
            return NSOrderedAscending;
        } else if ([(NSIndexPath*)obj1 item] > [(NSIndexPath*)obj2 item]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

#pragma mark - API Methods
- (void)addItem:(UICollectionViewLayoutAttributes *)item anchor:(CGPoint)anchor
{
    UIAttachmentBehavior *attachmentBehavior = [self createAttachmentBehaviorForItem:item anchor:anchor];
    
    // Add the attachment behavior to the animator
    [self.animator addBehavior:attachmentBehavior];
    [_attachmentBehaviors setObject:attachmentBehavior forKey:item.indexPath];
    
    // Add to animation behaviors
    [self.gravityBehavior addItem:item];
    [self.collisionBehavior addItem:item];
}

#pragma mark - Utility methods
- (void)createGravityBehavior
{
    _gravityBehavior = [[UIGravityBehavior alloc] init];
    _gravityBehavior.magnitude = 1.0;
}

- (void)createCollisionBehavior
{
    _collisionBehavior = [[UICollisionBehavior alloc] init];
    _collisionBehavior.collisionMode = UICollisionBehaviorModeBoundaries;
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] init];
    itemBehavior.elasticity = 1;
    [_collisionBehavior addChildBehavior:itemBehavior];
}

- (UIAttachmentBehavior *)createAttachmentBehaviorForItem:(id<UIDynamicItem>)item anchor:(CGPoint)anchor
{
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:anchor];
    attachmentBehavior.damping = 0.9;
    attachmentBehavior.frequency = 0.9;
    attachmentBehavior.length = 0;
    return attachmentBehavior;
}

@end

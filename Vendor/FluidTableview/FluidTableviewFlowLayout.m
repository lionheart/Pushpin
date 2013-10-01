    // And remove the entry from our dictionary//
//  FluidTableviewFlowLayout.m
//  FluidTableview
//
//  Created by Andy Muldowney on 9/30/13.
//  Copyright (c) 2013 Andy Muldowney. All rights reserved.
//
//  Portions of this code are derived from samples at:
//      http://www.shinobicontrols.com/blog/posts/2013/09/26/ios7-day-by-day-day-5-uidynamics-with-collection-views/
//

#import "FluidTableviewFlowLayout.h"

@implementation FluidTableviewFlowLayout

@synthesize itemSize = _itemSize;
@synthesize dynamicAnimator = _dynamicAnimator;
@synthesize behaviorManager = _behaviorManager;

- (id)initWithItemSize:(CGSize)size {
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.minimumLineSpacing = 10;
        self.minimumInteritemSpacing = 10;

        _itemSize = size;
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        _behaviorManager = [[FluidTableviewBehaviorManager alloc] initWithAnimator:_dynamicAnimator];
    }
    return self;
}

#pragma mark - Overridden methods
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // Calculate how much we've scrolled, and where the touch is in relation to the anchor points
    CGFloat scrollDelta = newBounds.origin.y - self.collectionView.bounds.origin.y;
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    for (UIAttachmentBehavior *behavior in [_behaviorManager.attachmentBehaviors allValues]) {
        CGPoint anchorPoint = behavior.anchorPoint;
        CGFloat distFromTouch = ABS(anchorPoint.y - touchLocation.y);
        
        UICollectionViewLayoutAttributes *attr = [behavior.items firstObject];
        CGPoint center = attr.center;
        CGFloat scrollFactor = MIN(1, distFromTouch / 500);
        
        center.y += scrollDelta * scrollFactor;
        attr.center = center;
        
        [_dynamicAnimator updateItemUsingCurrentState:attr];
    }
    
    return NO;
}

- (void)prepareLayout
{
    [UIView setAnimationsEnabled:NO];
    // Update the new section inset so all objects appear correctly
    // TODO: This isn't working right
    self.sectionInset = UIEdgeInsetsMake(-1 * (_itemSize.height / 2), 0, _itemSize.height + 10, 0);
    [super prepareLayout];
    
    // Create an expanded view port and get objects around the current item
    CGRect expandedViewPort = self.collectionView.bounds;
    expandedViewPort.origin.y -= 2 * _itemSize.height;
    expandedViewPort.size.height += 4 * _itemSize.height;
    NSArray *currentItems = [super layoutAttributesForElementsInRect:expandedViewPort];
    
    // Only show visible or nearly visible items in the collection
    [_behaviorManager updateItemCollection:currentItems];
    
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_dynamicAnimator itemsInRect:rect];
}

/*
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attr = [_dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
    return attr;
}
*/

#pragma mark - Item insertion methods
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        if(updateItem.updateAction == UICollectionUpdateActionInsert) {
            // Reset existing springs
            [self resetItemSpringsForInsertAtIndexPath:updateItem.indexPathAfterUpdate];
            
            // Location of the newly inserted cell
            UICollectionViewLayoutAttributes *attr = [super initialLayoutAttributesForAppearingItemAtIndexPath:updateItem.indexPathAfterUpdate];
            CGPoint center = attr.center;
            center.y -= 10; // Adds a slight animation
            
            // Reset the center point
            UICollectionViewLayoutAttributes *insertionPointAttr = [self layoutAttributesForItemAtIndexPath:updateItem.indexPathAfterUpdate];
            insertionPointAttr.center = center;
            [_dynamicAnimator updateItemUsingCurrentState:insertionPointAttr];
        }
    }
}


- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    return [_dynamicAnimator layoutAttributesForCellAtIndexPath:itemIndexPath];
}


#pragma mark - Utility Methods
- (void)resetItemSpringsForInsertAtIndexPath:(NSIndexPath *)indexPath
{
    // Get a list of items, sorted by their indexPath
    NSArray *items = [_behaviorManager currentlyManagedItemIndexPaths];
    // Now loop backwards, updating centers appropriately.
    // We need to get 2 enumerators - copy from one to the other
    NSEnumerator *fromEnumerator = [items reverseObjectEnumerator];
    // We want to skip the lastmost object in the array as we're copying left to right
    [fromEnumerator nextObject];
    // Now enumarate the array - through the 'to' positions
    [items enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *toIndex = (NSIndexPath*)obj;
        NSIndexPath *fromIndex = (NSIndexPath *)[fromEnumerator nextObject];
        
        // If the 'from' cell is after the insert then need to reset the springs
        if(fromIndex && fromIndex.item >= indexPath.item) {
            UICollectionViewLayoutAttributes *toItem = [self layoutAttributesForItemAtIndexPath:toIndex];
            UICollectionViewLayoutAttributes *fromItem = [self layoutAttributesForItemAtIndexPath:fromIndex];
            toItem.center = fromItem.center;
            [_dynamicAnimator updateItemUsingCurrentState:toItem];
        }
    }];
}

@end
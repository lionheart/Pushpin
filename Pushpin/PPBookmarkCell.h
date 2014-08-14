//
//  PPBookmarkCell.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/13.
//
//

@import UIKit;

@protocol PPDataSource;
@protocol PPBadgeWrapperDelegate;

@class PPBookmarkCell;
@class TTTAttributedLabel;

@protocol PPBookmarkCellDelegate <NSObject>

- (CGFloat)bookmarkCellMaxHorizontalOffset;
- (void)bookmarkCellDidScroll:(CGPoint)offset;
- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell
                                    forPost:(NSDictionary *)post;
- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell
                                  forPost:(NSDictionary *)post;
- (BOOL)bookmarkCellCanSwipe:(PPBookmarkCell *)cell;

@end

@interface PPBookmarkCell : UITableViewCell <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<PPBookmarkCellDelegate> delegate;

- (void)prepareCellWithDataSource:(id<PPDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                             post:(NSDictionary *)post
                       compressed:(BOOL)compressed;

@end

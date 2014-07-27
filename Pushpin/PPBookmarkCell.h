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

- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell
                                    forPost:(NSDictionary *)post
                                  indexPath:(NSIndexPath *)indexPath;
- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell
                                  forPost:(NSDictionary *)post
                                indexPath:(NSIndexPath *)indexPath;
- (BOOL)bookmarkCellCanSwipe:(PPBookmarkCell *)cell;

@end

@interface PPBookmarkCell : UITableViewCell <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<PPBookmarkCellDelegate> delegate;

- (void)prepareCellWithDataSource:(id<PPDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                            index:(NSInteger)index
                       compressed:(BOOL)compressed;

@end

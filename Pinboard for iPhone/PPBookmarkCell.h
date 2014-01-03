//
//  PPBookmarkCell.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/13.
//
//

#import <UIKit/UIKit.h>

@protocol GenericPostDataSource;
@protocol PPBadgeWrapperDelegate;

@class PPBookmarkCell;

@protocol PPBookmarkCellDelegate <NSObject>

- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell forIndex:(NSInteger)index;
- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell forIndex:(NSInteger)index;

@end

@interface PPBookmarkCell : UITableViewCell <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<PPBookmarkCellDelegate> delegate;

- (void)prepareCellWithDataSource:(id<GenericPostDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                            index:(NSInteger)index
                       compressed:(BOOL)compressed;

@end

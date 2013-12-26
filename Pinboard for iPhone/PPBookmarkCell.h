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

@interface PPBookmarkCell : UITableViewCell

- (void)prepareCellWithDataSource:(id<GenericPostDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                            index:(NSInteger)index
                       compressed:(BOOL)compressed;

@end

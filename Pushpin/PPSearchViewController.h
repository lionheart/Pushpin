//
//  PPSearchViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

#import "PPTableViewController.h"

typedef enum : NSInteger {
    PPSearchSectionQuery,
    PPSearchSectionFilters
} PPSearchSectionType;

typedef enum : NSInteger {
    PPSearchQueryRow
} PPSearchQueryRowType;

typedef enum : NSInteger {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterStarred,
    PPSearchFilterUntagged
} PPSearchFilterRowType;

typedef enum : NSInteger {
    PPSearchQueryRowCount = PPSearchQueryRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
} PPSearchRowCounts;

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate, UIActionSheetDelegate>

@end

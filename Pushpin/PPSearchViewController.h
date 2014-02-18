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

#ifdef PINBOARD
typedef enum : NSInteger {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterStarred,
    PPSearchFilterUntagged
} PPSearchFilterRowType;
#endif

#ifdef DELICIOUS
typedef enum : NSInteger {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterUntagged
} PPSearchFilterRowType;
#endif

typedef enum : NSInteger {
    PPSearchQueryRowCount = PPSearchQueryRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
} PPSearchRowCounts;

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate, UIActionSheetDelegate>

@end

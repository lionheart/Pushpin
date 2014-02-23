//
//  PPSearchViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

#import "PPTableViewController.h"

typedef enum : NSInteger {
    PPSearchScopeMine,
    
#ifdef PINBOARD
    PPSearchScopePinboard,
#endif

    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
} PPSearchScopeType;

static NSArray *PPSearchScopes() {
//    return @[@"Mine", @"Pinboard Search", @"Network", @"Everyone"];
    return @[@"Mine", @"Pinboard Search"];
}

typedef enum : NSInteger {
    PPSearchSectionQuery,
    PPSearchSectionScope,
    PPSearchSectionFilters
} PPSearchSectionType;

typedef enum : NSInteger {
    PPSearchQueryRow
} PPSearchQueryRowType;

typedef enum : NSInteger {
    PPSearchScopeRow
} PPSearchScopeRowType;

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
    PPSearchScopeRowCount = PPSearchScopeRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
} PPSearchRowCounts;

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate, UIActionSheetDelegate>

@end

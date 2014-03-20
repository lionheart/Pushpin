//
//  PPSearchViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

#import "PPTableViewController.h"
#import <LHSKeyboardAdjusting/LHSKeyboardAdjusting.h>

#ifdef PINBOARD
typedef enum : NSInteger {
    PPSearchScopeMine,
    PPSearchScopePinboard,
    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
} PPSearchScopeType;

typedef enum : NSInteger {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterStarred,
    PPSearchFilterUntagged
} PPSearchFilterRowType;

typedef enum : NSInteger {
    PPSearchSectionQuery,
    PPSearchSectionScope,
    PPSearchSectionFilters
} PPSearchSectionType;
#endif

#ifdef DELICIOUS
typedef enum : NSInteger {
    PPSearchScopeMine,
    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
    
    // Unused
    PPSearchScopePinboard,
} PPSearchScopeType;

typedef enum : NSInteger {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterUntagged
} PPSearchFilterRowType;

typedef enum : NSInteger {
    PPSearchSectionQuery,
    PPSearchSectionFilters,
    
    // Unused
    PPSearchSectionScope
} PPSearchSectionType;
#endif

static NSArray *PPSearchScopes() {
    return @[@"Mine", @"Pinboard Search"];
}

typedef enum : NSInteger {
    PPSearchQueryRow
} PPSearchQueryRowType;

typedef enum : NSInteger {
    PPSearchScopeRow
} PPSearchScopeRowType;

typedef enum : NSInteger {
    PPSearchQueryRowCount = PPSearchQueryRow + 1,
    PPSearchScopeRowCount = PPSearchScopeRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
} PPSearchRowCounts;

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate, UIActionSheetDelegate, LHSKeyboardAdjusting>

@end

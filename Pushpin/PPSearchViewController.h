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
typedef NS_ENUM(NSInteger, PPSearchScopeType) {
    PPSearchScopeMine,
    PPSearchScopePinboard,
    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
};

typedef NS_ENUM(NSInteger, PPSearchFilterRowType) {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterStarred,
    PPSearchFilterUntagged
};

typedef NS_ENUM(NSInteger, PPSearchSectionType) {
    PPSearchSectionQuery,
    PPSearchSectionScope,
    PPSearchSectionFilters,
    PPSearchSectionSave
};

static NSArray *PPSearchScopes() {
    return @[@"Pushpin", @"Pinboard Servers"];
}
#endif

#ifdef DELICIOUS
typedef NS_ENUM(NSInteger, PPSearchScopeType) {
    PPSearchScopeMine,
    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
    
    // Unused
    PPSearchScopePinboard,
};

typedef NS_ENUM(NSInteger, PPSearchFilterRowType) {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterUntagged
};

typedef NS_ENUM(NSInteger, PPSearchSectionType) {
    PPSearchSectionQuery,
    PPSearchSectionScope,
    PPSearchSectionFilters,
    PPSearchSectionSave
};

static NSArray *PPSearchScopes() {
    return @[];
}
#endif

typedef NS_ENUM(NSInteger, PPSearchQueryRowType) {
    PPSearchQueryRow
};

typedef NS_ENUM(NSInteger, PPSearchScopeRowType) {
    PPSearchScopeRow
};

typedef NS_ENUM(NSInteger, PPSearchRowCounts) {
    PPSearchQueryRowCount = PPSearchQueryRow + 1,
    PPSearchScopeRowCount = PPSearchScopeRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
};

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate,  LHSKeyboardAdjusting>

@end

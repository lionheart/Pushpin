//
//  PPTagEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import UIKit;
@import LHSKeyboardAdjusting;

@class PPTagEditViewController;

@protocol PPBadgeWrapperDelegate;

@protocol PPTagEditing <NSObject>

- (void)tagEditViewControllerDidUpdateTags:(PPTagEditViewController *)tagEditViewController;

@end

@interface PPTagEditViewController : UIViewController <PPBadgeWrapperDelegate,  UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, LHSKeyboardAdjusting>

@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;

@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL loadingTags;
@property (nonatomic) BOOL presentedFromShareSheet;

@property (nonatomic, strong) NSDictionary *bookmarkData;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableArray *popularTags;
@property (nonatomic, strong) NSMutableArray *previousTagSuggestions;
@property (nonatomic, strong) NSMutableArray *recommendedTags;
@property (nonatomic, strong) NSMutableArray *tagCompletions;
@property (nonatomic, strong) NSMutableArray *unfilteredPopularTags;
@property (nonatomic, strong) NSMutableArray *unfilteredRecommendedTags;
@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) NSMutableDictionary *tagDescriptions;
@property (nonatomic, strong) NSString *currentlySelectedTag;
@property (nonatomic, strong) UIAlertController *removeTagActionSheet;
@property (nonatomic, strong) UITextField *tagTextField;
@property (nonatomic, weak) id<PPTagEditing> tagDelegate;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *allTags;

- (NSInteger)maxTagsToAutocomplete;
- (NSInteger)minTagsToAutocomplete;

@end

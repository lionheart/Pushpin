//
//  PPTagEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import UIKit;

@class PPTagEditViewController;

@protocol PPBadgeWrapperDelegate;

@protocol PPTagEditing <NSObject>

- (void)tagEditViewControllerDidUpdateTags:(PPTagEditViewController *)tagEditViewController;

@end

@interface PPTagEditViewController : UIViewController <PPBadgeWrapperDelegate, UIActionSheetDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL loadingTags;
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
@property (nonatomic, strong) UIActionSheet *removeTagActionSheet;
@property (nonatomic, strong) UITextField *tagTextField;
@property (nonatomic, weak) id<PPTagEditing> tagDelegate;
@property (nonatomic, strong) UITableView *tableView;

- (NSInteger)maxTagsToAutocomplete;
- (NSInteger)minTagsToAutocomplete;

@end

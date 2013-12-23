//
//  AddBookmarkViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "PPSwitch.h"
#import <TextExpander/SMTEDelegateController.h>

@class PPNavigationController;

typedef enum BookmarkRows {
    kBookmarkTitleRow,
    kBookmarkDescriptionRow,
    kBookmarkTagRow,
    kBookmarkPrivateRow = 0,
    kBookmarkReadRow = 1
} BookmarkRowType;

typedef enum BookmarkSections {
    kBookmarkTopSection,
    kBookmarkBottomSection,
} BookmarkSectionType;

@interface AddBookmarkViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, SMTEFillDelegate> {
    UIEdgeInsets _oldContentInset;
}

@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSString *postDescription;
@property (nonatomic, strong) UITextView *postDescriptionTextView;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) NSMutableDictionary *tagDescriptions;
@property (nonatomic, strong) NSDictionary *bookmarkData;

@property (nonatomic) BOOL editingTags;
@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL isUpdate;
@property (nonatomic) BOOL loadingTags;
@property (nonatomic) BOOL loadingTitle;
@property (nonatomic, copy) void (^callback)();

@property (nonatomic, strong) NSMutableArray *popularTags;
@property (nonatomic, strong) NSMutableArray *recommendedTags;

@property (nonatomic, strong) NSMutableArray *previousTagSuggestions;
@property (nonatomic, strong) NSMutableArray *tagCompletions;
@property (nonatomic, strong) NSNumber *markAsRead;
@property (nonatomic, strong) NSNumber *setAsPrivate;
@property (nonatomic, strong) NSString *previousURLContents;
@property (nonatomic, strong) UIButton *privateButton;
@property (nonatomic, strong) UIButton *readButton;
@property (nonatomic, strong) UILabel *descriptionTextLabel;
@property (nonatomic, strong) UISwitch *privateSwitch;
@property (nonatomic, strong) UISwitch *readSwitch;
@property (nonatomic, strong) UITextField *currentTextField;
@property (nonatomic, strong) UITextField *tagTextField;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, strong) id<ModalDelegate> modalDelegate;

@property (nonatomic) BOOL textExpanderSnippetExpanded;
@property (nonatomic, assign) UIEdgeInsets keyboardTableInset;
@property (nonatomic, strong) SMTEDelegateController *textExpander;
@property (nonatomic, strong) UISwipeGestureRecognizer *descriptionGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeTagGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *tagGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *titleGestureRecognizer;
@property (nonatomic, strong) UIViewController *editTextViewController;

- (void)keyboardDidShow:(NSNotification *)sender;
- (void)keyboardDidHide:(NSNotification *)sender;

- (void)urlTextFieldDidChange:(NSNotification *)notification;
- (void)prefillPopularTags;
- (void)handleTagSuggestions;
- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate;
- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string;
- (void)togglePrivate:(id)sender;
- (void)toggleRead:(id)sender;
- (void)addBookmark;
- (void)close;
- (void)gestureDetected:(UISwipeGestureRecognizer *)gestureRecognizer;
- (void)finishEditingDescription;
- (void)setEditingTags:(BOOL)editingTags;
- (NSArray *)pinboardTags;
- (BOOL)pinboardTagsVisible;

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback;

@end

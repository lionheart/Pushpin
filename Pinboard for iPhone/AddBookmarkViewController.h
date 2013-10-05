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

@class PPNavigationController;

@interface AddBookmarkViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate> {
    UIEdgeInsets _oldContentInset;
}

@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSString *postDescription;
@property (nonatomic, strong) UITextView *postDescriptionTextView;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) NSMutableDictionary *tagDescriptions;

@property (nonatomic, retain) id<ModalDelegate> modalDelegate;
@property (nonatomic, retain) UITextField *urlTextField;
@property (nonatomic, retain) UITextField *descriptionTextField;
@property (nonatomic, retain) UITextField *titleTextField;
@property (nonatomic, retain) PPSwitch *privateSwitch;
@property (nonatomic, retain) PPSwitch *readSwitch;
@property (nonatomic, retain) UITextField *tagTextField;
@property (nonatomic, retain) NSArray *popularTags;
@property (nonatomic, retain) NSArray *recommendedTags;
@property (nonatomic, retain) NSMutableArray *tagCompletions;
@property (nonatomic, retain) NSMutableArray *popularTagSuggestions;
@property (nonatomic, retain) NSMutableArray *previousTagSuggestions;
@property (nonatomic, retain) NSNumber *setAsPrivate;
@property (nonatomic, retain) NSNumber *markAsRead;
@property (nonatomic, retain) UITextField *currentTextField;
@property (nonatomic) BOOL loadingTitle;
@property (nonatomic) BOOL loadingTags;
@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL suggestedTagsVisible;
@property (nonatomic, retain) NSString *previousURLContents;
@property (nonatomic, copy) void (^callback)();
@property (nonatomic, retain) NSArray *suggestedTagsPayload;

@property (nonatomic, retain) UISwipeGestureRecognizer *titleGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer *descriptionGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer *tagGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer *leftSwipeTagGestureRecognizer;

- (void)keyboardDidShow:(NSNotification *)sender;
- (void)keyboardDidHide:(NSNotification *)sender;

- (void)urlTextFieldDidChange:(NSNotification *)notification;
- (void)prefillPopularTags;
- (void)handleTagSuggestions;
- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate;
- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string;
- (void)privateSwitchChanged:(id)sender;
- (void)readSwitchChanged:(id)sender;
- (void)addBookmark;
- (void)close;
- (void)handleGesture:(UISwipeGestureRecognizer *)gestureRecognizer;
- (void)finishEditingDescription;

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback;

@end

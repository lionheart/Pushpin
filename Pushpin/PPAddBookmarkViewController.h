//
//  AddBookmarkViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import UIKit;

#import "PPBadgeWrapperView.h"
#import "PPEditDescriptionViewController.h"

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

@interface PPAddBookmarkViewController : UITableViewController <PPBadgeWrapperDelegate, UITextFieldDelegate, UITextViewDelegate, PPDescriptionEditing> {
    UIEdgeInsets _oldContentInset;
}

@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSString *postDescription;
@property (nonatomic, strong) NSDictionary *bookmarkData;

@property (nonatomic) BOOL isUpdate;

// Putting this in since for some reason, multiple copies of ASPinboard are being instantiated.
@property (nonatomic, strong) NSString *tokenOverride;
@property (nonatomic, strong) NSExtensionContext *presentingViewControllersExtensionContext;
@property (nonatomic) BOOL loadingTitle;
@property (nonatomic, copy) void (^callback)(NSDictionary *);

@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;
@property (nonatomic) BOOL markAsRead;
@property (nonatomic) BOOL setAsPrivate;
@property (nonatomic, strong) NSString *previousURLContents;
@property (nonatomic, strong) UIButton *privateButton;
@property (nonatomic, strong) UIButton *readButton;
@property (nonatomic, strong) UILabel *descriptionTextLabel;
@property (nonatomic, strong) UISwitch *privateSwitch;
@property (nonatomic, strong) UISwitch *readSwitch;
@property (nonatomic, strong) UITextField *currentTextField;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, strong) UITextField *tagTextField;
@property (nonatomic, strong) NSMutableArray *existingTags;

@property (nonatomic, assign) UIEdgeInsets keyboardTableInset;
@property (nonatomic, strong) UISwipeGestureRecognizer *descriptionGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeTagGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeTagGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *titleGestureRecognizer;
@property (nonatomic, strong) UIViewController *editTextViewController;
@property (nonatomic, strong) UITapGestureRecognizer *badgeTapGestureRecognizer;

- (BOOL)presentedFromShareSheet;

- (void)leftBarButtonTouchUpInside:(id)sender;
- (void)urlTextFieldDidChange:(NSNotification *)notification;
- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate;
- (void)togglePrivate:(id)sender;
- (void)toggleRead:(id)sender;
- (void)addBookmark;
- (void)close;
- (void)gestureDetected:(UISwipeGestureRecognizer *)gestureRecognizer;
- (void)configureWithBookmark:(NSDictionary *)bookmark
                       update:(NSNumber *)isUpdate
                     callback:(void (^)(NSDictionary *))callback;

+ (PPNavigationController *)updateBookmarkViewControllerWithURLString:(NSString *)urlString callback:(void (^)(NSDictionary *))callback;
+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)(NSDictionary *))callback;

@end

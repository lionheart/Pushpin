
//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import QuartzCore;
@import MobileCoreServices;
@import ASPinboard;
@import LHSTableViewCells;
@import LHSCategoryCollection;
@import FMDB;

#import "Pushpin-Swift.h"
#import "PPAddBookmarkViewController.h"
#import "PPNotification.h"
#import "PPUtilities.h"
#import "PPNavigationController.h"
#import "PPTheme.h"
#import "PPBadgeWrapperView.h"
#import "PPBadgeView.h"
#import "PPTableViewTitleView.h"
#import "PPEditDescriptionViewController.h"
#import "PPShortcutEnabledDescriptionViewController.h"
#import "PPPinboardDataSource.h"
#import "PPConstants.h"
#import "PPSettings.h"

#ifndef APP_EXTENSION_SAFE
#import "PPAppDelegate.h"
#endif

#import "NSString+URLEncoding2.h"
#import "UITableView+Additions.h"

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPAddBookmarkViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *descriptionAttributes;
@property (nonatomic, strong) UIKeyCommand *focusTitleKeyCommand;
@property (nonatomic, strong) UIKeyCommand *focusDescriptionKeyCommand;
@property (nonatomic, strong) UIKeyCommand *focusTagsKeyCommand;
@property (nonatomic, strong) UIKeyCommand *togglePrivateKeyCommand;
@property (nonatomic, strong) UIKeyCommand *toggleReadKeyCommand;
@property (nonatomic, strong) UIKeyCommand *closeKeyCommand;
@property (nonatomic, strong) UIKeyCommand *saveKeyCommand;

@property (nonatomic, strong) UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *updateOrAddBarButtonItem;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;
- (void)openDescriptionViewController;
- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags;
- (void)leftBarButtonTouchUpInside:(id)sender;
- (void)rightBarButtonTouchUpInside:(id)sender;

#pragma mark Tag Editing

@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL loadingTags;
@property (nonatomic) BOOL isEditingTags;
@property (nonatomic, strong) NSMutableArray *recommendedTags;
@property (nonatomic, strong) NSMutableArray *tagCompletions;
@property (nonatomic, strong) NSMutableArray *popularTags;
@property (nonatomic, strong) NSMutableArray *unfilteredPopularTags;
@property (nonatomic, strong) NSMutableArray *unfilteredRecommendedTags;
@property (nonatomic, strong) NSMutableDictionary *tagDescriptions;
@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) NSString *currentlySelectedTag;
@property (nonatomic, strong) UIAlertController *removeTagActionSheet;

@property (nonatomic, strong) NSString *originalTitle;

@property (nonatomic, strong) NSNumber *topYCoordinateForView;

- (NSArray *)indexPathsForPopularAndSuggestedRows;
- (NSArray *)indexPathsForAutocompletedRows;
- (NSArray *)indexPathsForArray:(NSArray *)array offset:(NSInteger)offset;

- (NSArray *)filteredPopularAndRecommendedTags;
- (BOOL)filteredPopularAndRecommendedTagsVisible;
- (NSInteger)tagOffset;

- (void)prefillPopularTags;
- (void)handleTagSuggestions;
- (void)searchUpdatedWithString:(NSString *)string;
- (void)deleteTagButtonTouchUpInside:(id)sender;
- (void)deleteTagWithName:(NSString *)name;
- (void)deleteTagWithName:(NSString *)name animation:(UITableViewRowAnimation)animation;

- (void)intersectionBetweenStartingAmount:(NSInteger)start
                           andFinalAmount:(NSInteger)final
                                   offset:(NSInteger)offset
                                 callback:(void (^)(NSArray *, NSArray *, NSArray *))callback;

- (NSInteger)maxTagsToAutocomplete;
- (NSInteger)minTagsToAutocomplete;

@end

@implementation PPAddBookmarkViewController

#pragma mark - Instantiation

- (id)init {
    self = [super init];
    if (self) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.tableView.translatesAutoresizingMaskIntoConstraints = false;
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.scrollEnabled = YES;
        
        self.isEditingTags = NO;
        self.autocompleteInProgress = NO;

        self.unfilteredPopularTags = [NSMutableArray array];
        self.unfilteredRecommendedTags = [NSMutableArray array];
        self.popularTags = [NSMutableArray array];
        self.recommendedTags = [NSMutableArray array];
        self.tagDescriptions = [NSMutableDictionary dictionary];
        self.tagCounts = [NSMutableDictionary dictionary];
        self.deleteTagButtons = [NSMutableDictionary dictionary];
        self.tagCompletions = [NSMutableArray array];
        
        self.deleteTagButtons = [NSMutableDictionary dictionary];

        self.postDescription = @"";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

        self.cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(leftBarButtonTouchUpInside:)];
        
        self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(rightBarButtonTouchUpInside:)];

        self.descriptionAttributes = [@{NSFontAttributeName: [UIFont systemFontOfSize:16],
                                        NSForegroundColorAttributeName: HEX(0xc7c7cdff),
                                        NSParagraphStyleAttributeName: paragraphStyle } mutableCopy];
        
        PPSettings *settings = [PPSettings sharedSettings];
        
        UIFont *font = [UIFont systemFontOfSize:16];
        self.urlTextField = [[UITextField alloc] init];
        self.urlTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.urlTextField.font = font;
        self.urlTextField.delegate = self;
        self.urlTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.urlTextField.placeholder = @"https://pinboard.in/";
        self.urlTextField.keyboardType = UIKeyboardTypeURL;
        
        // TODO Pull from settings
        self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.urlTextField.text = @"";
        self.previousURLContents = @"";

        self.descriptionTextLabel = [[UILabel alloc] init];
        self.descriptionTextLabel.numberOfLines = 3;
        self.descriptionTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.descriptionTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.descriptionTextLabel.userInteractionEnabled = NO;

        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleTextField.font = font;
        self.titleTextField.returnKeyType = UIReturnKeyDone;
        self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.titleTextField.delegate = self;
        self.titleTextField.autocapitalizationType = [settings autoCapitalizationType];
        self.titleTextField.autocorrectionType = [settings autoCorrectionType];
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Swipe right to prefill", nil);
        self.titleTextField.text = @"";

        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = font;
        self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagTextField.autocorrectionType = [settings tagAutoCorrectionType];
        self.tagTextField.placeholder = NSLocalizedString(@"Tap to add tags.", nil);
        self.tagTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.userInteractionEnabled = NO;
        self.tagTextField.text = @"";
        self.tagTextField.delegate = self;

        self.markAsRead = NO;
        self.loadingTitle = NO;
        self.setAsPrivate = [PPSettings sharedSettings].privateByDefault;
        self.existingTags = [NSMutableArray array];
        
        self.callback = ^(NSDictionary *bookmark) {};
        self.titleGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.titleGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.titleTextField addGestureRecognizer:self.titleGestureRecognizer];

        self.descriptionGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.descriptionGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.descriptionTextLabel addGestureRecognizer:self.descriptionGestureRecognizer];

        self.rightSwipeTagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.rightSwipeTagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.tagTextField addGestureRecognizer:self.rightSwipeTagGestureRecognizer];

        self.leftSwipeTagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.leftSwipeTagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.tagTextField addGestureRecognizer:self.leftSwipeTagGestureRecognizer];
        
        self.focusTitleKeyCommand = [UIKeyCommand keyCommandWithInput:@"1"
                                                        modifierFlags:UIKeyModifierCommand
                                                               action:@selector(handleKeyCommand:)];
        
        self.focusDescriptionKeyCommand = [UIKeyCommand keyCommandWithInput:@"2"
                                                              modifierFlags:UIKeyModifierCommand
                                                                     action:@selector(handleKeyCommand:)];
        
        self.focusTagsKeyCommand = [UIKeyCommand keyCommandWithInput:@"3"
                                                       modifierFlags:UIKeyModifierCommand
                                                              action:@selector(handleKeyCommand:)];
        
        self.togglePrivateKeyCommand = [UIKeyCommand keyCommandWithInput:@"4"
                                                           modifierFlags:UIKeyModifierCommand
                                                                  action:@selector(handleKeyCommand:)];
        
        self.toggleReadKeyCommand = [UIKeyCommand keyCommandWithInput:@"5"
                                                        modifierFlags:UIKeyModifierCommand
                                                               action:@selector(handleKeyCommand:)];

        self.saveKeyCommand = [UIKeyCommand keyCommandWithInput:@"s"
                                                  modifierFlags:UIKeyModifierCommand
                                                         action:@selector(handleKeyCommand:)];
        
        
        self.closeKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                   modifierFlags:0
                                                          action:@selector(handleKeyCommand:)];
        
        
        self.privateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.privateButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.privateButton setImage:[[UIImage imageNamed:@"roundbutton-private"] lhs_imageWithColor:HEX(0xd8dde4ff)] forState:UIControlStateNormal];
        [self.privateButton setImage:[[UIImage imageNamed:@"roundbutton-private"] lhs_imageWithColor:HEX(0xFFAE44FF)] forState:UIControlStateSelected];
        [self.privateButton addTarget:self action:@selector(togglePrivate:) forControlEvents:UIControlEventTouchUpInside];
        
        self.readButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.readButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.readButton setImage:[[UIImage imageNamed:@"roundbutton-checkmark"] lhs_imageWithColor:HEX(0xd8dde4ff)] forState:UIControlStateNormal];
        [self.readButton setImage:[[UIImage imageNamed:@"roundbutton-checkmark"] lhs_imageWithColor:HEX(0xEF6034FF)] forState:UIControlStateSelected];
        [self.readButton addTarget:self action:@selector(toggleRead:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

+ (PPNavigationController *)updateBookmarkViewControllerWithURLString:(NSString *)urlString
                                                             callback:(void (^)(NSDictionary *))callback {
    __block NSDictionary *post;
    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[urlString]];
        [results next];
        post = [PPPinboardDataSource postFromResultSet:results];

        [results close];
    }];
    
    return [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:post
                                                                     update:@(YES)
                                                                   callback:callback];
}

- (void)configureWithBookmark:(NSDictionary *)bookmark
                       update:(NSNumber *)isUpdate
                     callback:(void (^)(NSDictionary *))callback {
    self.bookmarkData = bookmark;
    [self setIsUpdate:isUpdate.boolValue];
    
    if (isUpdate.boolValue) {
        self.updateOrAddBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update", nil)
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(rightBarButtonTouchUpInside:)];

        self.title = NSLocalizedString(@"Update Bookmark", nil);
        self.urlTextField.textColor = [UIColor grayColor];
    } else {
        self.updateOrAddBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil)
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(rightBarButtonTouchUpInside:)];

        self.title = NSLocalizedString(@"Add Bookmark", nil);
    }
    self.navigationItem.rightBarButtonItem = self.updateOrAddBarButtonItem;

    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    
    if (bookmark[@"title"]) {
        self.titleTextField.text = bookmark[@"title"];
    }
    
    if (bookmark[@"url"]) {
        self.urlTextField.text = bookmark[@"url"];

        if (isUpdate.boolValue) {
            self.urlTextField.enabled = NO;
        }
    }
    
    if (bookmark[@"tags"]) {
        NSString *tags = [bookmark[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (tags.length > 0) {
            self.existingTags = [[tags componentsSeparatedByString:@" "] mutableCopy];
        }
    }
    
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    self.badgeWrapperView.userInteractionEnabled = NO;
    
    if (bookmark[@"description"]) {
        self.postDescription = [bookmark[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (![self.postDescription isEqualToString:@""]) {
            self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescription
                                                                                       attributes:self.descriptionAttributes];
        }
    }
    
    if (callback) {
        self.callback = callback;
    }
    
    if (bookmark[@"private"]) {
        self.setAsPrivate = [bookmark[@"private"] boolValue];
    } else {
        self.setAsPrivate = [PPSettings sharedSettings].privateByDefault;
    }
    
    if (bookmark[@"unread"]) {
        BOOL isRead = !([bookmark[@"unread"] boolValue]);
        self.markAsRead = isRead;
    } else {
        self.markAsRead = [PPSettings sharedSettings].readByDefault;
    }
    
    self.privateButton.selected = self.setAsPrivate;
    self.readButton.selected = self.markAsRead;
}

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark
                                                           update:(NSNumber *)isUpdate
                                                         callback:(void (^)(NSDictionary *))callback {
    PPAddBookmarkViewController *addBookmarkViewController = [[PPAddBookmarkViewController alloc] init];
    PPNavigationController *addBookmarkViewNavigationController = [[PPNavigationController alloc] initWithRootViewController:addBookmarkViewController];
    [addBookmarkViewController configureWithBookmark:bookmark update:isUpdate callback:callback];
    return addBookmarkViewNavigationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];

    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // We need to set this here, since on iPad the table view's frame isn't set until this happens.
    self.descriptionTextLabel.preferredMaxLayoutWidth = self.tableView.frame.size.width - 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.tokenOverride) {
        [[ASPinboard sharedInstance] setToken:self.tokenOverride];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isEditingTags && self.existingTags.count == 0) {
        return 1;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isEditingTags) {
        if (section == 0) {
            if (self.filteredPopularAndRecommendedTagsVisible) {
                return self.filteredPopularAndRecommendedTags.count + [self tagOffset];
            } else if (self.tagCompletions.count > 0) {
                return self.tagCompletions.count + [self tagOffset];
            } else {
                return [self tagOffset];
            }
        } else {
            return self.existingTags.count;
        }
    } else {
        switch (section) {
            case kBookmarkTopSection:
                return kBookmarkTagRow + 1;
                
            case kBookmarkBottomSection:
                return 2;
                
            default:
                return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (self.isEditingTags) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        [cell.contentView lhs_removeSubviews];
        cell.textLabel.text = @"";
        cell.textLabel.enabled = YES;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.imageView.image = nil;
        cell.detailTextLabel.text = @"";
        cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = nil;
        
        if (indexPath.section == 0) {
            NSInteger index = indexPath.row - [self tagOffset];
            
            if (index >= 0) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                
                if (self.filteredPopularAndRecommendedTagsVisible) {
                    cell.textLabel.text = self.filteredPopularAndRecommendedTags[index];
                    cell.detailTextLabel.textColor = HEX(0x96989DFF);
                    cell.detailTextLabel.text = self.tagDescriptions[cell.textLabel.text];
                } else if (self.tagCompletions.count > 0) {
                    NSString *tag = self.tagCompletions[index];
                    cell.textLabel.text = tag;
                    cell.detailTextLabel.text = self.tagCounts[tag];
                }
            } else {
                // This is the tag entry row
                if (index == -1) {
                    UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                    topImageView.frame = CGRectMake(14, 12, 20, 20);
                    [cell.contentView addSubview:topImageView];
                    
                    if (self.loadingTags) {
                        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                        [activity startAnimating];
                        cell.accessoryView = activity;
                        cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                        cell.textLabel.enabled = NO;
                    }

                    [cell.contentView addSubview:self.tagTextField];
                    
                    NSDictionary *views = @{@"view": self.tagTextField};
                    [cell.contentView lhs_addConstraints:@"H:|-40-[view]-10-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-10-[view]" views:views];
                } else {
                    // If it's -2, it's the badge row
                    [cell.contentView addSubview:self.badgeWrapperView];
                    [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": self.badgeWrapperView}];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:@{@"badges": self.badgeWrapperView}];
                }
            }
        } else {
            //This is because '&' was shown as '&amp;' int existingTags
            NSMutableArray *newArray = [NSMutableArray array];
            for (NSString *input in self.existingTags)
            {
                NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
                    [newArray addObject:replacement];
            }
            self.existingTags = newArray;
            
            NSString *tag = self.existingTags[self.existingTags.count - indexPath.row - 1];
            cell.textLabel.text = tag;
            
            // We set this up as an image view so that the image can be centered in a large tap area.
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Delete-Button"]];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button addTarget:self action:@selector(deleteTagButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            button.clipsToBounds = YES;
            [button addSubview:imageView];
            
            [button lhs_addConstraints:@"H:[imageView(23)]-15-|" views:NSDictionaryOfVariableBindings(imageView)];
            [button lhs_centerVerticallyForView:imageView height:23];
            self.deleteTagButtons[tag] = button;
            
            [cell.contentView addSubview:button];
            [cell lhs_addConstraints:@"H:[button(70)]|" views:NSDictionaryOfVariableBindings(button)];
            [cell lhs_addConstraints:@"V:|[button]|" views:NSDictionaryOfVariableBindings(button)];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        [cell.contentView lhs_removeSubviews];
        cell.textLabel.text = @"";
        cell.textLabel.enabled = YES;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.imageView.image = nil;
        cell.detailTextLabel.text = @"";
        cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = nil;
        
        switch (indexPath.section) {
            case kBookmarkTopSection:
                switch (indexPath.row) {
                    case kBookmarkTitleRow: {
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-bookmark"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.translatesAutoresizingMaskIntoConstraints = NO;
                        
                        NSDictionary *views = @{@"image": topImageView,
                                                @"url": self.urlTextField,
                                                @"title": self.titleTextField };
                        [cell.contentView addSubview:topImageView];
                        [cell.contentView addSubview:self.titleTextField];
                        [cell.contentView addSubview:self.urlTextField];
                        
                        [cell.contentView lhs_addConstraints:@"H:|-14-[image(20)]" views:views];
                        [cell.contentView lhs_addConstraints:@"H:|-40-[url]-10-|" views:views];
                        
                        [cell.contentView lhs_addConstraints:@"V:|-12-[image(20)]" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-8-[title(24)][url]" views:views];
                        
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            [cell.contentView lhs_addConstraints:@"H:|-40-[title]-30-|" views:views];
                        } else {
                            [cell.contentView lhs_addConstraints:@"H:|-40-[title]-10-|" views:views];
                        }
                        
                        if (self.isUpdate) {
                            self.urlTextField.font = [UIFont systemFontOfSize:14];
                            self.urlTextField.textColor = [UIColor grayColor];
                        } else {
                            self.urlTextField.font = [UIFont systemFontOfSize:16];
                            self.urlTextField.textColor = [UIColor blackColor];
                        }
                        
                        break;
                    }
                    case kBookmarkDescriptionRow: {
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-description"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.translatesAutoresizingMaskIntoConstraints = NO;
                        
                        NSDictionary *views = @{@"image": topImageView,
                                                @"description": self.descriptionTextLabel };
                        [cell.contentView addSubview:topImageView];
                        [cell.contentView lhs_addConstraints:@"H:|-14-[image(20)]" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-12-[image(20)]" views:views];
                        
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            self.descriptionAttributes[NSForegroundColorAttributeName] = HEX(0xc7c7cdff);
                            self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Loading..." attributes:self.descriptionAttributes];
                        } else {
                            if ([self.postDescription isEqualToString:@""]) {
                                self.descriptionAttributes[NSForegroundColorAttributeName] = HEX(0xc7c7cdff);
                                self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Tap to add a description.", nil) attributes:self.descriptionAttributes];
                            } else {
                                self.descriptionAttributes[NSForegroundColorAttributeName] = [UIColor blackColor];
                                self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescription attributes:self.descriptionAttributes];
                            }
                            
                            [cell.contentView addSubview:self.descriptionTextLabel];
                            [cell.contentView lhs_addConstraints:@"H:|-40-[description]" views:views];
                            [cell.contentView lhs_addConstraints:@"V:|-10-[description]" views:views];
                        }
                        
                        break;
                    }
                    case kBookmarkTagRow: {
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.translatesAutoresizingMaskIntoConstraints = NO;
                        
                        NSDictionary *views = @{@"image": topImageView,
                                                @"text": self.tagTextField,
                                                @"badges": self.badgeWrapperView };
                        [cell.contentView addSubview:topImageView];
                        [cell.contentView addSubview:self.tagTextField];
                        [cell.contentView addSubview:self.badgeWrapperView];
                        
                        [cell.contentView lhs_addConstraints:@"H:|-14-[image(20)]" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-12-[image(20)]" views:views];
                        [cell.contentView lhs_addConstraints:@"H:|-40-[text]-10-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-10-[text]" views:views];
                        [cell.contentView lhs_addConstraints:@"H:|-40-[badges]-10-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:views];
                        
                        if (self.existingTags.count == 0) {
                            self.tagTextField.hidden = NO;
                        } else {
                            self.tagTextField.hidden = YES;
                        }
                        break;
                    }
                }
                break;
                
            case kBookmarkBottomSection: {
                switch (indexPath.row) {
                    case kBookmarkPrivateRow: {
                        self.privateButton.selected = self.setAsPrivate;
                        
                        if (self.setAsPrivate) {
                            cell.textLabel.text = NSLocalizedString(@"Private", nil);
                        } else {
                            cell.textLabel.text = NSLocalizedString(@"Public", nil);
                        }
                        
                        [cell.contentView addSubview:self.privateButton];
                        NSDictionary *views = @{@"view": self.privateButton};
                        [cell.contentView lhs_addConstraints:@"H:[view(23)]-10-|" views:views];
                        [cell.contentView lhs_centerVerticallyForView:self.privateButton height:23];
                        break;
                    }
                        
                    case kBookmarkReadRow:
                        self.readButton.selected = self.markAsRead;
                        
                        if (self.markAsRead) {
                            cell.textLabel.text = NSLocalizedString(@"Read", nil);
                        } else {
                            cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                        }
                        
                        [cell.contentView addSubview:self.readButton];
                        NSDictionary *views = @{@"view": self.readButton};
                        [cell.contentView lhs_addConstraints:@"H:[view(23)]-10-|" views:views];
                        [cell.contentView lhs_centerVerticallyForView:self.readButton height:23];
                        break;
                }
                break;
            }
        }
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.isEditingTags) {
        if (section == 0) {
            return NSLocalizedString(@"Swipe right to suggest popular tags, swipe left to remove them. Separate tags with spaces and make a tag private by prepending it with a period.", nil);
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditingTags) {
        if (self.existingTags.count > 0 && [indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]]) {
            return 20 + [self.badgeWrapperView calculateHeightForWidth:(CGRectGetWidth(self.tableView.frame) - 20)];
        }
    } else {
        switch (indexPath.section) {
            case kBookmarkTopSection:
                switch (indexPath.row) {
                    case kBookmarkTitleRow:
                        if (self.isUpdate) {
                            return 58;
                        } else {
                            return 62;
                        }
                        
                    case kBookmarkDescriptionRow: {
                        if (self.descriptionTextLabel.text && ![self.descriptionTextLabel.text isEqualToString:@""]) {
                            CGFloat width = self.view.frame.size.width - 50;
                            CGRect descriptionRect = [self.descriptionTextLabel textRectForBounds:CGRectMake(0, 0, width, CGFLOAT_MAX) limitedToNumberOfLines:3];
                            return CGRectGetHeight(descriptionRect) + 20;
                        } else {
                            return 42;
                        }
                    }
                        
                    case kBookmarkTagRow: {
                        CGFloat width = self.view.frame.size.width - 50;
                        return MAX(44, [self.badgeWrapperView calculateHeightForWidth:width] + 20);
                    }
                }
        }
    }
    
    return 44;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    //doesnt matter if they are already added, tags with '&' are shown when searching, so the loop below will avoid adding them again into 'existing tags' when they are tapped
    for (id object in self.existingTags) {
        if ([object caseInsensitiveCompare:[tableView cellForRowAtIndexPath:indexPath].textLabel.text] == NSOrderedSame) {
            return;
        }
    }
    
    if (self.isEditingTags) {
        NSInteger row = indexPath.row;
        
        if (row >= [self tagOffset] && indexPath.section == 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *completion;
                NSMutableArray *indexPathsToDelete = [NSMutableArray array];
                NSMutableArray *indexPathsToInsert = [NSMutableArray array];
                NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
                NSMutableArray *indexPathsToReload = [NSMutableArray array];

                // Add the row to the bookmark list below
                
                if (self.existingTags.count == 0) {
                    [indexSetsToInsert addIndex:1];
                    [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                } else {
                    [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
                    [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                }
                
                NSInteger index = row - [self tagOffset];
                
                if (self.tagCompletions.count > 0) {
                    completion = self.tagCompletions[index];
                    [indexPathsToDelete addObjectsFromArray:[self indexPathsForAutocompletedRows]];
                    [self.tagCompletions removeAllObjects];
                    [self.existingTags addObject:completion];
                } else if (self.filteredPopularAndRecommendedTagsVisible) {
                    completion = self.filteredPopularAndRecommendedTags[index];
                    
                    if (index < self.popularTags.count) {
                        completion = self.popularTags[index];
                        
#warning http://crashes.to/s/4988f817e3d
                        [self.popularTags removeObjectAtIndex:index];
                    } else {
                        completion = self.recommendedTags[index];
                        [self.recommendedTags removeObjectAtIndex:(index - self.popularTags.count)];
                    }
                    
                    [self.existingTags addObject:completion];
                    [indexPathsToDelete addObject:indexPath];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                    self.tagTextField.text = @"";
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
            });
        }
    } else {
        switch (indexPath.section) {
            case kBookmarkTopSection:
                switch (indexPath.row) {
                    case kBookmarkDescriptionRow: {
                        [self openDescriptionViewController];
                        break;
                    }
                        
                    case kBookmarkTagRow: {
                        self.isEditingTags = YES;

                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.tagTextField.userInteractionEnabled = YES;
                            self.tagTextField.hidden = NO;
                            self.badgeWrapperView.userInteractionEnabled = YES;

                            NSMutableIndexSet *indexSetsToReload = [NSMutableIndexSet indexSet];
                            [indexSetsToReload addIndex:0];

                            NSMutableIndexSet *indexSetsToDelete = [NSMutableIndexSet indexSet];

                            if (self.existingTags.count > 0) {
                                [indexSetsToReload addIndex:1];
                            } else {
                                [indexSetsToDelete addIndex:1];
                            }

                            [self.tableView beginUpdates];
                            [self.tableView reloadSections:indexSetsToReload withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView deleteSections:indexSetsToDelete withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];

                            [self.tagTextField becomeFirstResponder];

                            self.navigationItem.leftBarButtonItem = nil;
                            self.navigationItem.rightBarButtonItem = self.doneBarButtonItem;

                            self.originalTitle = self.title;
                            self.title = NSLocalizedString(@"Edit Tags", nil);
                        });
                        break;
                    }
                }
                break;
                
            case kBookmarkBottomSection:
                switch (indexPath.row) {
                    case kBookmarkPrivateRow:
                        [self togglePrivate:nil];
                        break;
                        
                    case kBookmarkReadRow:
                        [self toggleRead:nil];
                        break;
                }
                break;
        }
    }
}

#pragma mark - UITextFieldDelegate



#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.isEditingTags) {
        NSCharacterSet *invalidCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        if (string.length > 0) {
            NSRange range = [string rangeOfCharacterFromSet:invalidCharacterSet];
            BOOL containsInvalidCharacters = range.location != NSNotFound;
            if (containsInvalidCharacters) {
                [self textFieldShouldReturn:textField];
                return NO;
            }
        }
        
        NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (finalString.length == 0) {
            self.searchString = nil;
            NSInteger finalAmount;
            if (self.filteredPopularAndRecommendedTagsVisible) {
                finalAmount = self.filteredPopularAndRecommendedTags.count;
                self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Suggest", nil);
            } else {
                finalAmount = 0;
            }
            
            [self intersectionBetweenStartingAmount:self.tagCompletions.count
                                     andFinalAmount:finalAmount
                                             offset:[self tagOffset]
                                           callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                               [self.tagCompletions removeAllObjects];
                                               [self.popularTags removeAllObjects];
                                               [self.recommendedTags removeAllObjects];
                                               
                                               [self.tableView beginUpdates];
                                               [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
                                               [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                                               [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                                               [self.tableView endUpdates];
                                           }];
        } else {
            self.searchString = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:string];
            [self searchUpdatedWithString:self.searchString];
        }
    } else {
        NSCharacterSet *invalidCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        if (textField == self.urlTextField) {
            if ([string rangeOfCharacterFromSet:invalidCharacterSet].location != NSNotFound) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.isEditingTags) {
        NSString *tag = self.tagTextField.text;
        if (tag.length > 0) {
            if (![self.existingTags containsObject:tag]) {
                self.tagTextField.text = @"";
                
                NSMutableArray *indexPathsToInsert = [NSMutableArray array];
                NSMutableArray *indexPathsToDelete = [NSMutableArray array];
                NSMutableArray *indexPathsToReload = [NSMutableArray array];
                NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
                
                if (self.existingTags.count == 0) {
                    [indexSetsToInsert addIndex:1];
                    [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                } else {
                    [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
                    [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                }
                
                if (self.filteredPopularAndRecommendedTagsVisible) {
                    [indexPathsToDelete addObjectsFromArray:[self indexPathsForPopularAndSuggestedRows]];
                    [self.popularTags removeAllObjects];
                    [self.recommendedTags removeAllObjects];
                } else {
                    [indexPathsToDelete addObjectsFromArray:[self indexPathsForAutocompletedRows]];
                    [self.tagCompletions removeAllObjects];
                }
                
                [self.existingTags addObject:tag];
                self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            }
        } else {
            [self.navigationController popViewControllerAnimated:YES];
            return YES;
        }
        return NO;
    } else {
        [textField resignFirstResponder];
        
        if (textField == self.urlTextField) {
            [self prefillTitleAndForceUpdate:NO];
        }
        
        return YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (self.isEditingTags) {
        NSArray *indexPathsToDelete;
        if (self.filteredPopularAndRecommendedTagsVisible) {
            indexPathsToDelete = [self indexPathsForPopularAndSuggestedRows];
            [self.popularTags removeAllObjects];
            [self.recommendedTags removeAllObjects];
        } else if (self.tagCompletions.count > 0) {
            indexPathsToDelete = [self indexPathsForAutocompletedRows];
            [self.tagCompletions removeAllObjects];
        }

        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    return YES;
}

#pragma mark - Everything Else

- (void)togglePrivate:(id)sender {
    self.setAsPrivate = !self.setAsPrivate;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkPrivateRow inSection:kBookmarkBottomSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)toggleRead:(id)sender {
    self.markAsRead = !self.markAsRead;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkReadRow inSection:kBookmarkBottomSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)urlTextFieldDidChange:(NSNotification *)notification {
    if ([UIPasteboard generalPasteboard].string == self.urlTextField.text) {
        [self prefillTitleAndForceUpdate:NO];
    }
}

- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    self.previousURLContents = self.urlTextField.text;

    BOOL shouldPrefillDescription = [self.descriptionTextLabel.text isEqualToString:NSLocalizedString(@"Tap to add a description.", nil)];
    BOOL shouldPrefillTitle = !self.loadingTitle
    && (forceUpdate || self.titleTextField == nil || [self.titleTextField.text isEqualToString:@""])
#ifndef APP_EXTENSION_SAFE
    && [[UIApplication sharedApplication] canOpenURL:url]
#endif
    && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTitle) {
        [self.urlTextField resignFirstResponder];
        self.loadingTitle = YES;

        NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithArray:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
        if (shouldPrefillDescription) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:1 inSection:0]];
        }
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [PPUtilities retrievePageTitle:url
                              callback:^(NSString *title, NSString *description) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      self.titleTextField.text = title;

                                      if (shouldPrefillDescription) {
                                          self.postDescription = description;
                                          self.descriptionAttributes[NSForegroundColorAttributeName] = [UIColor blackColor];
                                          self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescription attributes:self.descriptionAttributes];
                                      }
                                      self.loadingTitle = NO;

                                      [self.tableView beginUpdates];
                                      [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                                      [self.tableView endUpdates];
                                  });
                              }];
    }
}

- (void)addBookmark {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifndef APP_EXTENSION_SAFE
        if (![[PPAppDelegate sharedDelegate] connectionAvailable]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [PPNotification notifyWithMessage:NSLocalizedString(@"Unable to add bookmark; no connection available.", nil)];
                [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
            });
        }
#endif
        
        if ([self.urlTextField.text isEqualToString:@""] && [self.titleTextField.text isEqualToString:@""]) {
            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                           message:NSLocalizedString(@"You can't add a bookmark without a URL or title.", nil)];
            
            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{


            });
            return;
        }

        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *url = self.urlTextField.text;
        if (!url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [PPNotification notifyWithMessage:NSLocalizedString(@"Unable to add bookmark without a URL.", nil)];
                [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
            });
            return;
        }
        NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:characterSet];
        NSString *description = [self.postDescription stringByTrimmingCharactersInSet:characterSet];
        NSString *tags = [[self existingTags] componentsJoinedByString:@" "];
        BOOL private = self.setAsPrivate;
        BOOL unread = !self.markAsRead;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            void (^BookmarkSuccessBlock)(void) = ^{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                    __block BOOL bookmarkAdded;
                    __block NSDictionary *post;

                    [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        FMResultSet *results = [db executeQuery:@"SELECT hash, COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[url]];
                        [results next];
                        
                        NSString *hash = [results stringForColumnIndex:0];
                        NSInteger count = [results intForColumnIndex:1];
                        
                        [results close];

                        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                      @"url": url,
                                                                                                      @"title": title,
                                                                                                      @"description": description,
                                                                                                      @"tags": tags,
                                                                                                      @"unread": @(unread),
                                                                                                      @"private": @(private),
                                                                                                      

                                                                                                      @"starred": @(NO)
                                                                                                      }];
                        BOOL hashExists = hash && ![hash isEqual:[NSNull null]];
                        
                        if (count > 0) {
                            // The bookmark already exists, so we're updating it.
                            

                            
                            if (hashExists) {
                                [params removeObjectForKey:@"url"];
                                params[@"hash"] = hash;

                                [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE hash=:hash" withParameterDictionary:params];
                                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                                for (NSString *tagName in [tags componentsSeparatedByString:@" "]) {
                                    [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                                    [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                                }
                            } else {
#warning The bookmark doesn't yet have a hash
                                
                                

                                [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE url=:url" withParameterDictionary:params];
                            }
                            bookmarkAdded = NO;
                        } else {
                            // We're adding this bookmark for the first time.
                            params[@"created_at"] = [NSDate date];

                            
                            

                            [db executeUpdate:@"INSERT INTO bookmark (meta, title, description, url, private, unread, starred, tags, created_at) VALUES (random(), :title, :description, :url, :private, :unread, :starred, :tags, :created_at);" withParameterDictionary:params];
                            
                            bookmarkAdded = YES;
                        }
                        
                        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                        [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
                        

                        FMResultSet *resultSet = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[url]];
                        [resultSet next];
                        post = [PPPinboardDataSource postFromResultSet:resultSet];
                        [resultSet close];
                    }];
                    
                    PPBookmarkEventType eventType;
                    if (bookmarkAdded) {
                        eventType = PPBookmarkEventAdd;
                    } else {
                        eventType = PPBookmarkEventUpdate;
                    }

                    if (self.callback) {
                        self.callback(post);

                        dispatch_async(dispatch_get_main_queue(), ^{
#warning This used to be "NO". Why?
                            [self.parentViewController dismissViewControllerAnimated:YES
                                                                          completion:^{
#ifndef APP_EXTENSION_SAFE
                                                                              NSDecimalNumber *threshold = [NSDecimalNumber decimalNumberWithString:@"10000"];
                                                                              StoreReviewPointsManager *manager = [[StoreReviewPointsManager alloc] initWithThreshold:threshold];
                                                                              [manager addActionWithValue:StoreReviewValueHigh halfLife:StoreReviewHalfLifeWeek];
#endif

                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkEventNotificationName
                                                                                                                                  object:nil
                                                                                                                                userInfo:@{@"type": @(eventType) }];
                                                                          }];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *message;
                            if (bookmarkAdded) {
                                message = NSLocalizedString(@"Your bookmark was added.", nil);
                            } else {
                                message = NSLocalizedString(@"Your bookmark was updated.", nil);
                            }
                            
                            [PPNotification notifyWithMessage:message success:YES updated:YES];

                            [self.parentViewController dismissViewControllerAnimated:YES completion:^{
#ifndef APP_EXTENSION_SAFE
                                NSDecimalNumber *threshold = [NSDecimalNumber decimalNumberWithString:@"10000"];
                                StoreReviewPointsManager *manager = [[StoreReviewPointsManager alloc] initWithThreshold:threshold];
                                [manager addActionWithValue:StoreReviewValueHigh halfLife:StoreReviewHalfLifeWeek];
#endif

                                [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkEventNotificationName
                                                                                    object:nil
                                                                                  userInfo:@{@"type": @(eventType) }];
                            }];
                        });
                    }
                });
            };
            
            void (^BookmarkFailureBlock)(NSError *) = ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.leftBarButtonItem.enabled = YES;
                    self.navigationItem.rightBarButtonItem.enabled = YES;

                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                                 message:NSLocalizedString(@"There was an error adding your bookmark.", nil)];
                    
                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                });
            };

            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard addBookmarkWithURL:url
                                   title:title
                             description:description
                                    tags:tags
                                  shared:!private
                                  unread:unread
                                 success:BookmarkSuccessBlock
                                 failure:BookmarkFailureBlock];

        });
    });
}

- (void)gestureDetected:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.titleGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    } else if (gestureRecognizer == self.descriptionGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    } else if (gestureRecognizer == self.rightSwipeTagGestureRecognizer) {
        [self prefillPopularTags];
        [self.tagTextField resignFirstResponder];
    } else if (gestureRecognizer == self.leftSwipeTagGestureRecognizer) {
        [self.tagTextField resignFirstResponder];

        if (self.filteredPopularAndRecommendedTagsVisible) {
            [self intersectionBetweenStartingAmount:self.filteredPopularAndRecommendedTags.count
                                     andFinalAmount:self.tagCompletions.count
                                             offset:2
                                           callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                               [self.popularTags removeAllObjects];
                                               [self.recommendedTags removeAllObjects];
                                               
                                               [self.tableView beginUpdates];
                                               [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                                               [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                                               [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                                               [self.tableView endUpdates];
                                           }];
        }
    }
}

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags {
    NSMutableArray *badges = [NSMutableArray array];
    NSArray *existingTags = [self existingTags];
    for (NSString *tag in existingTags) {
        if (![tag isEqualToString:@""]) {
            [badges addObject:@{ @"type": @"tag", @"tag": tag }];
        }
    }

    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges
                                                                     options:@{
                                                                               PPBadgeFontSize: @([PPTheme staticBadgeFontSize]) }];
    
    if (!self.isEditingTags) {
        wrapper.userInteractionEnabled = NO;
    }

    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    wrapper.delegate = self;
    return wrapper;
}

- (void)rightBarButtonTouchUpInside:(id)sender {
    if (self.isEditingTags) {
        self.isEditingTags = NO;
        self.tagTextField.userInteractionEnabled = NO;
        self.tagTextField.text = @"";
        self.tagTextField.hidden = YES;
        self.badgeWrapperView.userInteractionEnabled = NO;
        
        NSMutableIndexSet *indexSetsToReload = [NSMutableIndexSet indexSet];
        [indexSetsToReload addIndex:0];
        
        NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
        
        if (self.existingTags.count > 0) {
            [indexSetsToReload addIndex:1];
        } else {
            [indexSetsToInsert addIndex:1];
        }
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:indexSetsToReload withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
        self.title = self.originalTitle;
    } else {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.hidesWhenStopped = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [activityIndicator startAnimating];
        NSLog(@"%@", _existingTags);
        //This is because '&' was shown as '&amp;' int existingTags
        NSMutableArray *newArray = [NSMutableArray array];
        for (NSString *input in self.existingTags)
        {
            NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
                [newArray addObject:replacement];
        }
        self.existingTags = newArray;
        NSLog(@"%@", _existingTags);
        if (self.presentedFromShareSheet) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.urlTextField.text isEqualToString:@""] && [self.titleTextField.text isEqualToString:@""]) {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                                 message:NSLocalizedString(@"You can't add a bookmark without a URL or title.", nil)];
                    [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }

                NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSString *url = self.urlTextField.text;
                if (!url) {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                                 message:NSLocalizedString(@"Unable to add bookmark without a URL.", nil)];
                    [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }

                self.navigationItem.leftBarButtonItem.enabled = NO;
                self.navigationItem.rightBarButtonItem.enabled = NO;

                NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:characterSet];
                NSString *description = [self.postDescription stringByTrimmingCharactersInSet:characterSet];
                NSString *tags = [[self existingTags] componentsJoinedByString:@" "];
                BOOL private = self.setAsPrivate;
                BOOL unread = !self.markAsRead;

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    void (^BookmarkSuccessBlock)(void) = ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIViewController *shareViewController = self.parentViewController.presentingViewController;
                            [shareViewController dismissViewControllerAnimated:YES completion:^{
                                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                            }];
                        });
                    };

                    void (^BookmarkFailureBlock)(NSError *) = ^(NSError *error) {
                        NSHTTPURLResponse *response = error.userInfo[ASPinboardHTTPURLResponseKey];
                        NSString *title;
                        NSString *message;
                        if (response.statusCode == 401) {
                            title = NSLocalizedString(@"Invalid Credentials", nil);
                            message = NSLocalizedString(@"Your Pinboard credentials are currently out-of-date. Your auth token may have been reset. Please log out and back into Pushpin to continue syncing bookmarks.", nil);
                        } else {
                            title = NSLocalizedString(@"Uh oh.", nil);
                            message = NSLocalizedString(@"There was an error adding your bookmark.", nil);
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.navigationItem.leftBarButtonItem.enabled = YES;
                            self.navigationItem.rightBarButtonItem.enabled = YES;

                            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:title
                                                                                         message:message];
                            [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                            [self presentViewController:alert animated:YES completion:nil];
                        });
                    };



                    ASPinboard *pinboard = [ASPinboard sharedInstance];
                    [pinboard addBookmarkWithURL:url
                                           title:title
                                     description:description
                                            tags:tags
                                          shared:!private
                                          unread:unread
                                         success:BookmarkSuccessBlock
                                         failure:BookmarkFailureBlock];

                });
            });
        } else {
            [self addBookmark];
        }
    }
}

- (void)leftBarButtonTouchUpInside:(id)sender {
    if (self.presentedFromShareSheet) {
        UIViewController *shareViewController = self.parentViewController.presentingViewController;
        [shareViewController dismissViewControllerAnimated:YES completion:^{
            [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]];
        }];
    } else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:^{
            self.callback(@{});
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - PPDescriptionEditing

- (void)editDescriptionViewControllerDidUpdateDescription:(PPEditDescriptionViewController *)editDescriptionViewController {
    NSString *text = [editDescriptionViewController.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.postDescription = text;
    self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:self.descriptionAttributes];

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkDescriptionRow inSection:kBookmarkTopSection]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.focusTitleKeyCommand, self.focusDescriptionKeyCommand, self.focusTagsKeyCommand, self.togglePrivateKeyCommand, self.toggleReadKeyCommand, self.saveKeyCommand, self.closeKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.focusTitleKeyCommand) {
        [self.titleTextField becomeFirstResponder];
    } else if (keyCommand == self.focusDescriptionKeyCommand) {
        [self openDescriptionViewController];
    } else if (keyCommand == self.focusTagsKeyCommand) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:kBookmarkTagRow inSection:kBookmarkTopSection]
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
    } else if (keyCommand == self.togglePrivateKeyCommand) {
        [self togglePrivate:keyCommand];
    } else if (keyCommand == self.toggleReadKeyCommand) {
        [self toggleRead:keyCommand];
    } else if (keyCommand == self.saveKeyCommand) {
        [self addBookmark];
    } else if (keyCommand == self.closeKeyCommand) {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Other

- (void)openDescriptionViewController {
    PPShortcutEnabledDescriptionViewController *editDescriptionViewController = [[PPShortcutEnabledDescriptionViewController alloc] initWithDescription:self.postDescription];
    editDescriptionViewController.delegate = self;
    [self.navigationController pushViewController:editDescriptionViewController animated:YES];
}

- (BOOL)presentedFromShareSheet {
    return self.presentingViewControllersExtensionContext != nil;
}

- (NSExtensionContext *)extensionContext {
    return self.presentingViewControllersExtensionContext;
}

#pragma mark - Tag Editing

- (NSArray *)filteredPopularAndRecommendedTags {
    return [self.popularTags arrayByAddingObjectsFromArray:self.recommendedTags];
}

- (BOOL)filteredPopularAndRecommendedTagsVisible {
    return self.filteredPopularAndRecommendedTags.count > 0;
}

- (NSInteger)tagOffset {
    if (self.existingTags.count > 0) {
        return 2;
    }
    return 1;
}

- (void)deleteTagButtonTouchUpInside:(id)sender {
    NSString *tag = [[self.deleteTagButtons allKeysForObject:sender] firstObject];
    [self deleteTagWithName:tag animation:UITableViewRowAnimationFade];
}
- (void)deleteTagWithName:(NSString *)name {
    [self deleteTagWithName:name animation:UITableViewRowAnimationFade];
}

- (void)deleteTagWithName:(NSString *)name animation:(UITableViewRowAnimation)animation {
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    NSMutableIndexSet *sectionIndicesToDelete = [NSMutableIndexSet indexSet];
    
    NSInteger index = [self.existingTags indexOfObject:name];
    
    if (self.existingTags.count > 1) {
        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(self.existingTags.count - index - 1) inSection:1]];
    } else {
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [sectionIndicesToDelete addIndex:1];
    }
    
    [self.existingTags removeObject:name];
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    
    [indexPathsToDelete addObjectsFromArray:self.indexPathsForAutocompletedRows];
    self.tagTextField.text = @"";
    self.searchString = @"";
    [self.tagCompletions removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:sectionIndicesToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:animation];
        [self.tableView endUpdates];
        
        if (self.searchString) {
            [self searchUpdatedWithString:self.searchString];
        }
    });
}

- (NSArray *)indexPathsForAutocompletedRows {
    return [self indexPathsForArray:self.tagCompletions offset:[self tagOffset]];
}

- (NSArray *)indexPathsForPopularAndSuggestedRows {
    return [self indexPathsForArray:self.filteredPopularAndRecommendedTags offset:[self tagOffset]];
}

- (NSArray *)indexPathsForArray:(NSArray *)array
                         offset:(NSInteger)offset {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i=0; i<array.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
    }
    return indexPaths;
}
- (void)searchUpdatedWithString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        self.autocompleteInProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *newTagCompletions = [NSMutableArray array];
            NSMutableArray *oldTagCompletions = [self.tagCompletions copy];
            if (string.length > 0) {
                NSString *searchString = [string stringByAppendingString:@"*"];
                NSArray *existingTags = [self existingTags];
                __block NSInteger skipPivot = 0;
                
                void (^DatabaseBlock)(FMDatabase *db) = ^(FMDatabase *db) {
                    NSMutableArray *queryComponents = [NSMutableArray array];
                    NSMutableArray *arguments = [NSMutableArray array];
                    [arguments addObject:searchString];
                    
                    [queryComponents addObject:@"SELECT DISTINCT tag_fts.name, tag.count FROM tag_fts, tag WHERE tag_fts.name MATCH ? AND tag_fts.name = tag.name"];
                    
                    for (NSString *tag in self.existingTags) {
                        [queryComponents addObject:@"AND tag.name != ?"];
                        [arguments addObject:tag];
                    }
                    
                    [queryComponents addObject:@"ORDER BY tag.count DESC LIMIT ?"];
                    [arguments addObject:@(MAX([self minTagsToAutocomplete], (NSInteger)([self maxTagsToAutocomplete] - self.existingTags.count)))];
                    
#warning XXX For some reason, getting double results here sometimes. Search duplication?
                    FMResultSet *result = [db executeQuery:[queryComponents componentsJoinedByString:@" "] withArgumentsInArray:arguments];
                    
                    NSString *tag, *count;
                    NSInteger index = [self tagOffset];
                    BOOL tagFound = NO;
                    
                    while ([result next]) {
                        tagFound = NO;
                        tag = [result stringForColumnIndex:0];
                        count = [result stringForColumnIndex:1];
                        
                        if (!count || count.length == 0) {
                            count = @"0";
                        }
                        
                        self.tagCounts[tag] = count;
                        if (![existingTags containsObject:tag]) {
                            for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                                if ([oldTagCompletions[i] isEqualToString:tag]) {
                                    // Delete all posts that were skipped
                                    for (NSInteger j=skipPivot; j<i; j++) {
                                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(j+[self tagOffset]) inSection:0]];
                                    }
                                    
                                    tagFound = YES;
                                    skipPivot = i+1;
                                    break;
                                }
                            }
                            
                            if (!tagFound) {
                                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                            }
                            
                            index++;
                            [newTagCompletions addObject:tag];
                        }
                    }
                    
                    [result close];
                };
                
                if (self.presentedFromShareSheet) {
                    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
                    [[FMDatabaseQueue databaseQueueWithPath:[containerURL URLByAppendingPathComponent:@"shared.db"].path] inDatabase:DatabaseBlock];
                } else {
                    [[PPUtilities databaseQueue] inDatabase:DatabaseBlock];
                }
                
                if (self.filteredPopularAndRecommendedTagsVisible) {
                    [indexPathsToDelete addObjectsFromArray:self.indexPathsForPopularAndSuggestedRows];
                } else if (oldTagCompletions.count > 0) {
                    for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+[self tagOffset]) inSection:0]];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.popularTags removeAllObjects];
                    [self.recommendedTags removeAllObjects];
                    
                    self.tagCompletions = newTagCompletions;
                    //This is because '&' was shown as '&amp;' int tagCompletions
                    NSMutableArray *newArray = [NSMutableArray array];
                    for (NSString *input in self.tagCompletions)
                    {
                        NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
                            [newArray addObject:replacement];
                    }
                    self.tagCompletions = newArray;
                    
                    
                    @try {
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    }
                    @catch (NSException *exception) {
                        [self.tableView reloadData];
                    }
                    
                    self.autocompleteInProgress = NO;
                });
            } else if (!self.filteredPopularAndRecommendedTagsVisible) {
                self.autocompleteInProgress = NO;
            } else {
                self.autocompleteInProgress = NO;
            }
        });
    }
}

- (NSInteger)maxTagsToAutocomplete {
    if ([UIApplication isIPad]) {
        return 10;
    } else {
        return 10;
    }
}

- (NSInteger)minTagsToAutocomplete {
    if ([UIApplication isIPad]) {
        return 8;
    } else {
        return 4;
    }
}

- (void)intersectionBetweenStartingAmount:(NSInteger)start
                           andFinalAmount:(NSInteger)final
                                   offset:(NSInteger)offset
                                 callback:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    
    if (final >= start) {
        for (NSInteger i=0; i<start; i++) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
        
        for (NSInteger i=start; i<final; i++) {
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
    } else {
        for (NSInteger i=0; i<final; i++) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
        
        for (NSInteger i=final; i<start; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
    }
    
    callback(indexPathsToInsert, indexPathsToReload, indexPathsToDelete);
}

- (void)handleTagSuggestions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.filteredPopularAndRecommendedTagsVisible) {
            [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
            
            NSInteger previousCount;
            if (self.filteredPopularAndRecommendedTagsVisible) {
                previousCount = self.filteredPopularAndRecommendedTags.count;
            } else if (self.tagCompletions.count > 0) {
                previousCount = self.tagCompletions.count;
                [self.tagCompletions removeAllObjects];
            } else {
                previousCount = 0;
            }
            
            [self.popularTags removeAllObjects];
            [self.recommendedTags removeAllObjects];
            
            NSArray *existingTags = [self existingTags];
            for (NSString *tag in self.unfilteredPopularTags) {
                if (![existingTags containsObject:tag]) {
                    self.tagDescriptions[tag] = @"popular";
                    [self.popularTags addObject:tag];
                }
            }
            
            for (NSString *tag in self.unfilteredRecommendedTags) {
                if (![existingTags containsObject:tag] && ![self.popularTags containsObject:tag]) {
                    self.tagDescriptions[tag] = @"recommended";
                    [self.recommendedTags addObject:tag];
                }
            }
            [self.popularTags filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF MATCHES '^[ ]?$'"]];
            
            [self intersectionBetweenStartingAmount:previousCount
                                     andFinalAmount:self.filteredPopularAndRecommendedTags.count
                                             offset:[self tagOffset]
                                           callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   self.tagTextField.text = @"";
                                                   
                                                   [self.tableView beginUpdates];
                                                   
                                                   if (self.loadingTags) {
                                                       self.loadingTags = NO;
                                                   }
                                                   
                                                   [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView endUpdates];
                                               });
                                           }];
        }
    });
}

- (void)prefillPopularTags {
    NSURL *url = [NSURL URLWithString:self.bookmarkData[@"url"]];
    BOOL shouldPrefillTags = !self.loadingTags
        && (self.unfilteredPopularTags.count == 0 && self.unfilteredRecommendedTags.count == 0)
#ifndef APP_EXTENSION_SAFE
        && [[UIApplication sharedApplication] canOpenURL:url]
#endif
        && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTags) {
        self.loadingTags = YES;
        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [self.unfilteredPopularTags removeAllObjects];
            [self.unfilteredRecommendedTags removeAllObjects];
            
            [pinboard tagSuggestionsForURL:self.bookmarkData[@"url"]
                                   success:^(NSArray *popular, NSArray *recommended) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                                       });

                                       [self.unfilteredPopularTags addObjectsFromArray:popular];
                                       [self.unfilteredRecommendedTags addObjectsFromArray:recommended];
                                       [self handleTagSuggestions];
                                   }];
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self handleTagSuggestions];
        });
    }
}


#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    NSString *tag = badge.textLabel.text;
    self.currentlySelectedTag = tag;

    self.removeTagActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];

    [self.removeTagActionSheet lhs_addActionWithTitle:[NSString stringWithFormat:@"Remove '%@'", tag]
                                                style:UIAlertActionStyleDestructive
                                              handler:^(UIAlertAction *action) {
                                                  self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                                                  
                                                  NSIndexPath *indexPathToReload;
                                                  indexPathToReload = [NSIndexPath indexPathForRow:0 inSection:0];
                                                  
                                                  [self.tableView beginUpdates];
                                                  [self.tableView reloadRowsAtIndexPaths:@[indexPathToReload] withRowAnimation:UITableViewRowAnimationFade];
                                                  [self.tableView endUpdates];
                                                  
                                                  [self deleteTagWithName:self.currentlySelectedTag];
                                              }];
    
    [self.removeTagActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    CGRect rect = [badge lhs_centerRect];
    self.removeTagActionSheet.popoverPresentationController.sourceRect = [self.view convertRect:rect fromView:badge];
    self.removeTagActionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:self.removeTagActionSheet animated:YES completion:nil];
}

@end

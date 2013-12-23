
//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <QuartzCore/QuartzCore.h>

#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "NSString+URLEncoding2.h"
#import "PPNavigationController.h"
#import "PPTheme.h"
#import "UITableViewCellValue1.h"
#import "PPBadgeWrapperView.h"
#import "PPBadgeView.h"
#import "UITableView+Additions.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIImage+Tint.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface AddBookmarkViewController ()

@property (nonatomic, strong) NSMutableDictionary *descriptionAttributes;

@end

@implementation AddBookmarkViewController

@synthesize textExpander, textExpanderSnippetExpanded;
@synthesize isUpdate = _isUpdate;

#pragma mark - Instantiation

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        
        self.postDescription = @"";
        
        // Use the instance variable because we don't want to trigger any table view animations caused by the setter
        _editingTags = NO;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

        self.descriptionAttributes = [@{NSFontAttributeName: [UIFont fontWithName:[PPTheme fontName] size:16],
                                        NSForegroundColorAttributeName: HEX(0xc7c7cdff),
                                        NSParagraphStyleAttributeName: paragraphStyle } mutableCopy];
        
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
        self.urlTextField = [[UITextField alloc] init];
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
        self.descriptionTextLabel.numberOfLines = 0;
        self.descriptionTextLabel.preferredMaxLayoutWidth = 270;
        self.descriptionTextLabel.userInteractionEnabled = NO;

        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.font = font;
        self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Swipe right to prefill", nil);
        self.titleTextField.text = @"";
        
        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = font;
        self.tagTextField.userInteractionEnabled = NO;
        self.tagTextField.delegate = self;
        self.tagTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.placeholder = NSLocalizedString(@"Tap here to add tags", nil);
        self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagTextField.text = @"";
        
        self.markAsRead = @(NO);
        self.loadingTitle = NO;
        self.loadingTags = NO;
        self.autocompleteInProgress = NO;
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
        self.unfilteredPopularTags = [NSMutableArray array];
        self.unfilteredRecommendedTags = [NSMutableArray array];
        self.previousTagSuggestions = [NSMutableArray array];
        self.popularTags = [NSMutableArray array];
        self.recommendedTags = [NSMutableArray array];
        self.tagDescriptions = [NSMutableDictionary dictionary];
        self.tagCounts = [NSMutableDictionary dictionary];
        
        self.callback = ^(void) {};
        self.titleGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.titleGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.titleTextField addGestureRecognizer:self.titleGestureRecognizer];
        
        self.descriptionGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.descriptionGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.descriptionTextLabel addGestureRecognizer:self.descriptionGestureRecognizer];
        
        self.tagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.tagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.tagTextField addGestureRecognizer:self.tagGestureRecognizer];
        
        self.leftSwipeTagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.leftSwipeTagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.tagTextField addGestureRecognizer:self.leftSwipeTagGestureRecognizer];
        
        self.privateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.privateButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.privateButton setImage:[[UIImage imageNamed:@"roundbutton-private"] imageWithColor:HEX(0xd8dde4ff)] forState:UIControlStateNormal];
        [self.privateButton setImage:[[UIImage imageNamed:@"roundbutton-private"] imageWithColor:HEX(0xFFAE44FF)] forState:UIControlStateSelected];
        [self.privateButton addTarget:self action:@selector(togglePrivate:) forControlEvents:UIControlEventTouchUpInside];
        
        self.readButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.readButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.readButton setImage:[[UIImage imageNamed:@"roundbutton-checkmark"] imageWithColor:HEX(0xd8dde4ff)] forState:UIControlStateNormal];
        [self.readButton setImage:[[UIImage imageNamed:@"roundbutton-checkmark"] imageWithColor:HEX(0xEF6034FF)] forState:UIControlStateSelected];
        [self.readButton addTarget:self action:@selector(toggleRead:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    PPNavigationController *addBookmarkViewNavigationController = [[PPNavigationController alloc] initWithRootViewController:addBookmarkViewController];
    
    [addBookmarkViewController setIsUpdate:isUpdate.boolValue];
    
    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark", nil);
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    else {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark", nil);
    }
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:delegate action:@selector(closeModal:)];
    
    if (bookmark[@"title"]) {
        addBookmarkViewController.titleTextField.text = bookmark[@"title"];
    }
    
    if (bookmark[@"url"]) {
        addBookmarkViewController.urlTextField.text = bookmark[@"url"];
        
        if (isUpdate.boolValue) {
            addBookmarkViewController.urlTextField.enabled = NO;
        }
    }
    
    if (bookmark[@"tags"]) {
        addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    }
    
    addBookmarkViewController.badgeWrapperView = [addBookmarkViewController badgeWrapperViewForCurrentTags];
    
    if (bookmark[@"description"]) {
        addBookmarkViewController.postDescription = bookmark[@"description"];
        addBookmarkViewController.postDescriptionTextView.text = bookmark[@"description"];
        
        if (![bookmark[@"description"] isEqualToString:@""]) {
            addBookmarkViewController.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:bookmark[@"description"] attributes:addBookmarkViewController.descriptionAttributes];
        }
    }
    
    if (delegate) {
        addBookmarkViewController.modalDelegate = delegate;
    }
    
    if (callback) {
        addBookmarkViewController.callback = callback;
    }
    
    if (bookmark[@"private"]) {
        addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    }
    else {
        addBookmarkViewController.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
    }
    
    if (bookmark[@"unread"]) {
        BOOL isRead = !([bookmark[@"unread"] boolValue]);
        addBookmarkViewController.markAsRead = @(isRead);
    }
    else {
        addBookmarkViewController.markAsRead = [[AppDelegate sharedDelegate] readByDefault];
    }
    
    addBookmarkViewController.privateButton.selected = addBookmarkViewController.setAsPrivate.boolValue;
    addBookmarkViewController.readButton.selected = addBookmarkViewController.markAsRead.boolValue;
    return addBookmarkViewNavigationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tagCompletions = [NSMutableArray array];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.urlTextField];
    [self.postDescriptionTextView resignFirstResponder];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];

    if (!self.postDescriptionTextView) {
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
        BOOL isIPad = [UIApplication isIPad];
        CGFloat offset;
        if (isIPad) {
            offset = 75;
        }
        else {
            offset = 225;
        }

        self.postDescriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - offset)];
        self.postDescriptionTextView.autocorrectionType = [AppDelegate sharedDelegate].enableAutoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo;
        self.postDescriptionTextView.autocapitalizationType =  [AppDelegate sharedDelegate].enableAutoCapitalize ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone;
        self.postDescriptionTextView.spellCheckingType = UITextSpellCheckingTypeDefault;
        self.postDescriptionTextView.font = font;
        self.postDescriptionTextView.text = self.postDescription;
        
        // TextExpander SDK
        self.textExpander = [[SMTEDelegateController alloc] init];
        [self.postDescriptionTextView setDelegate:textExpander];
        [self.textExpander setNextDelegate:self];
    }
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
    if (self.editingTags) {
        return 1;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.editingTags) {
        if (self.popularAndRecommendedTagsVisible) {
            return self.filteredPopularAndRecommendedTags.count + 1;
        }
        else {
            return self.tagCompletions.count + 1;
        }
    }
    else {
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editingTags) {
        return 44;
    }
    else {
        switch (indexPath.section) {
            case kBookmarkTopSection:
                switch (indexPath.row) {
                    case kBookmarkTitleRow:
                        if (self.isUpdate) {
                            return 58;
                        }
                        else {
                            return 62;
                        }
                        
                    case kBookmarkDescriptionRow: {
                        CGRect descriptionRect = [self.descriptionTextLabel textRectForBounds:CGRectMake(0, 0, 250, CGFLOAT_MAX) limitedToNumberOfLines:3];
                        return descriptionRect.size.height + 20;
                    }

                    case kBookmarkTagRow: {
                        return MAX(44, [self.badgeWrapperView calculateHeight] + 20);
                    }
                }
        }
    }

    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == kBookmarkTopSection) {
        if (!self.footerView) {
            self.footerView = [[UIView alloc] init];
            self.footerView.clipsToBounds = NO;
            UILabel *label = [[UILabel alloc] init];
            label.frame = CGRectMake(20, 5, self.tableView.frame.size.width - 40, [self tableView:tableView heightForFooterInSection:0]);
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont fontWithName:[PPTheme fontName] size:13];
            label.textColor = HEX(0x4C586AFF);
            label.numberOfLines = 0;
            label.backgroundColor = HEX(0xF7F9FDff);
            label.text = NSLocalizedString(@"Separate tags with spaces", nil);
            [self.footerView addSubview:label];
        }
        return self.footerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == kBookmarkTopSection) {
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:13];
        NSString *title = NSLocalizedString(@"Separate tags with spaces", nil);
        CGRect rect = [title boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 40, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: font} context:nil];
        return rect.size.height;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.contentView lhs_removeSubviews];
    cell.textLabel.text = @"";
    cell.textLabel.enabled = YES;
    cell.textLabel.font = [UIFont fontWithName:[PPTheme fontName] size:16];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:16];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;

    CGFloat textFieldWidth = tableView.frame.size.width - 2 * tableView.groupedCellMargin - 40;
    CGRect frame = cell.frame;
    
    if (self.editingTags) {
        if (indexPath.row == 0) {
            UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] imageWithColor:HEX(0xD8DDE4FF)]];
            topImageView.frame = CGRectMake(14, 12, 20, 20);
            [cell.contentView addSubview:topImageView];
            self.tagTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
            [cell.contentView addSubview:self.tagTextField];

            if (self.loadingTags) {
                UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [activity startAnimating];
                cell.accessoryView = activity;
                cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                cell.textLabel.enabled = NO;
            }
            else {
                self.tagTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
                [cell.contentView addSubview:self.tagTextField];
            }
        }
        else {
            if (self.tagCompletions.count > 0) {
                NSString *tag = self.tagCompletions[indexPath.row - 1];
                cell.textLabel.text = tag;
                cell.detailTextLabel.text = self.tagCounts[tag];
            }
            else {
                cell.textLabel.text = self.filteredPopularAndRecommendedTags[indexPath.row - 1];
                cell.detailTextLabel.textColor = HEX(0x96989DFF);
                cell.detailTextLabel.text = self.tagDescriptions[cell.textLabel.text];
            }
        }
    }
    else {
        switch (indexPath.section) {
            case kBookmarkTopSection:
                switch (indexPath.row) {
                    case kBookmarkTitleRow: {
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-bookmark"] imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.frame = CGRectMake(14, 12, 20, 20);
                        [cell.contentView addSubview:topImageView];
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            cell.textLabel.text = @"Loading";
                            cell.textLabel.enabled = NO;
                        }
                        else {
                            self.titleTextField.frame = CGRectMake(40, 8, textFieldWidth, 24);
                            [cell.contentView addSubview:self.titleTextField];
                        }
                        
                        if (self.isUpdate) {
                            self.urlTextField.frame = CGRectMake(40, self.titleTextField.frame.origin.y + 24.0f, textFieldWidth, 18);
                            self.urlTextField.font = [UIFont fontWithName:[PPTheme fontName] size:14];
                            self.urlTextField.textColor = [UIColor grayColor];
                            
                        } else {
                            self.urlTextField.frame = CGRectMake(40, self.titleTextField.frame.origin.y + 24.0f, textFieldWidth, 20);
                            self.urlTextField.font = [UIFont fontWithName:[PPTheme fontName] size:16];
                            self.urlTextField.textColor = [UIColor blackColor];
                        }
                        [cell.contentView addSubview:self.urlTextField];
                        
                        break;
                    }
                    case kBookmarkDescriptionRow: {
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        
                        CGRect descriptionRect = [self.descriptionTextLabel textRectForBounds:CGRectMake(0, 0, 250, CGFLOAT_MAX) limitedToNumberOfLines:3];
                        self.descriptionTextLabel.frame = (CGRect){{40, 10}, descriptionRect.size};
                        
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-description"] imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.frame = CGRectMake(14, 12, 20, 20);
                        [cell.contentView addSubview:topImageView];
                        
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            cell.textLabel.text = @"Loading";
                            cell.textLabel.enabled = NO;
                        }
                        else {
                            if (![self.postDescription isEqualToString:@""]) {
                                self.descriptionAttributes[NSForegroundColorAttributeName] = [UIColor blackColor];
                                self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescription attributes:self.descriptionAttributes];
                            }
                            else {
                                self.descriptionAttributes[NSForegroundColorAttributeName] = HEX(0xc7c7cdff);
                                self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Tap here to add description", nil) attributes:self.descriptionAttributes];
                            }
                            
                            [cell.contentView addSubview:self.descriptionTextLabel];
                        }
                        break;
                    }
                    case kBookmarkTagRow: {
                        UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] imageWithColor:HEX(0xD8DDE4FF)]];
                        topImageView.frame = CGRectMake(14, 12, 20, 20);
                        [cell.contentView addSubview:topImageView];
                        [cell.contentView addSubview:self.badgeWrapperView];
                        [cell.contentView lhs_addConstraints:@"H:|-40-[badges]-10-|" views:@{@"badges": self.badgeWrapperView}];
                        
                        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.badgeWrapperView attribute:NSLayoutAttributeCenterY multiplier:1 constant:-2]];
                        break;
                    }
                }
                break;
                
            case kBookmarkBottomSection: {
                switch (indexPath.row) {
                    case kBookmarkPrivateRow: {
                        self.privateButton.selected = self.setAsPrivate.boolValue;
                        
                        if (self.setAsPrivate.boolValue) {
                            cell.textLabel.text = NSLocalizedString(@"Private", nil);
                        }
                        else {
                            cell.textLabel.text = NSLocalizedString(@"Public", nil);
                        }
                        
                        [cell.contentView addSubview:self.privateButton];
                        NSDictionary *views = @{@"view": self.privateButton};
                        [cell.contentView lhs_addConstraints:@"H:[view(23)]-10-|" views:views];
                        [cell.contentView lhs_centerVerticallyForView:self.privateButton height:23];
                        break;
                    }
                        
                    case kBookmarkReadRow:
                        self.readButton.selected = self.markAsRead.boolValue;
                        
                        if (self.markAsRead.boolValue) {
                            cell.textLabel.text = NSLocalizedString(@"Read", nil);
                        }
                        else {
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.editingTags) {
        NSString *tagText = self.tagTextField.text;
        NSInteger row = indexPath.row;
        
        if (row > 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *completion;
                NSMutableArray *indexPathsToDelete = [NSMutableArray array];
                
                if (self.tagCompletions.count > 0) {
                    completion = self.tagCompletions[row - 1];
                    [self.tagCompletions removeObjectAtIndex:row-1];
                    [indexPathsToDelete addObject:indexPath];
                }
                else if (self.filteredPopularAndRecommendedTags.count > 0) {
                    completion = self.filteredPopularAndRecommendedTags[row - 1];

                    if (self.popularTags.count >= row) {
                        [self.popularTags removeObjectAtIndex:(row - 1)];
                    }
                    else {
                        [self.recommendedTags removeObjectAtIndex:(row - self.popularTags.count - 1)];
                    }

                    unichar space = ' ';
                    if (tagText.length > 0 && [tagText characterAtIndex:tagText.length - 1] != space) {
                        self.tagTextField.text = [NSString stringWithFormat:@"%@ ", tagText];
                    }
                    
                    [indexPathsToDelete addObject:indexPath];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    
                    NSString *stringToReplace = [[tagText componentsSeparatedByString:@" "] lastObject];
                    NSRange range = NSMakeRange(tagText.length - stringToReplace.length, stringToReplace.length);
                    self.tagTextField.text = [tagText stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", completion]];
                });
            });
        }
    }
    else {
        if (indexPath.section == kBookmarkTopSection && indexPath.row == kBookmarkDescriptionRow) {
            self.editTextViewController = [[UIViewController alloc] init];
            self.editTextViewController.title = NSLocalizedString(@"Description", nil);
            self.editTextViewController.view = [[UIView alloc] initWithFrame:SCREEN.bounds];
            self.editTextViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(finishEditingDescription)];
            [self.editTextViewController.view addSubview:self.postDescriptionTextView];
            self.postDescriptionTextView.text = self.postDescription;
            [self.navigationController pushViewController:self.editTextViewController animated:YES];
            [self.postDescriptionTextView becomeFirstResponder];
        }
        else if (indexPath.section == kBookmarkTopSection && indexPath.row == kBookmarkTagRow) {
            self.editingTags = YES;
        }
        else if (indexPath.section == kBookmarkBottomSection && indexPath.row == kBookmarkPrivateRow) {
            [self togglePrivate:nil];
        }
        else if (indexPath.section == kBookmarkBottomSection && indexPath.row == kBookmarkReadRow) {
            [self toggleRead:nil];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.tagTextField) {
        self.editingTags = NO;
    }
    else if (textField == self.urlTextField) {
        [textField resignFirstResponder];
        [self prefillTitleAndForceUpdate:NO];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagTextField) {
        if (textField.text.length > 0 && [textField.text characterAtIndex:textField.text.length-1] == ' ' && [string isEqualToString:@" "]) {
            return NO;
        }
        else {
            [self searchUpdatedWithRange:range andString:string];
        }
    }
    else if (textField == self.urlTextField) {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (self.popularAndRecommendedTagsVisible) {
        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
        for (NSInteger i=1; i<self.filteredPopularAndRecommendedTags.count+1; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:kBookmarkTopSection]];
        }
        
        self.popularAndRecommendedTagsVisible = NO;

        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }

    self.currentTextField = textField;
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (self.textExpanderSnippetExpanded) {
        [self performSelector:@selector(fixTextView:) withObject:textView afterDelay:0.01];
        self.textExpanderSnippetExpanded = NO;
    }
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.textExpander.isAttemptingToExpandText) {
        self.textExpanderSnippetExpanded = YES;
    }
    
    return YES;
}

#pragma mark - Everything Else


- (void)keyboardDidShow:(NSNotification *)sender {
    if (self.currentTextField == self.descriptionTextLabel) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:kBookmarkDescriptionRow inSection:kBookmarkTopSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.urlTextField || self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:kBookmarkTitleRow inSection:kBookmarkTopSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)keyboardDidHide:(NSNotification *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.autocompleteInProgress = NO;
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.navigationController.topViewController != self.editTextViewController) {
        self.callback();
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        self.autocompleteInProgress = YES;
        
        NSString *tagTextFieldText = self.tagTextField.text;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *indexPathsToRemove = [NSMutableArray array];
            NSMutableArray *indexPathsToAdd = [NSMutableArray array];
            NSMutableArray *newTagCompletions = [NSMutableArray array];
            NSMutableArray *oldTagCompletions = [self.tagCompletions copy];
            
            NSString *newString = [tagTextFieldText stringByReplacingCharactersInRange:range withString:string];
            if (string && newString.length > 0 && [newString characterAtIndex:newString.length-1] != ' ') {
                NSString *newTextFieldContents;
                if (range.length > string.length) {
                    newTextFieldContents = [tagTextFieldText substringToIndex:tagTextFieldText.length - range.length];
                }
                else {
                    newTextFieldContents = [NSString stringWithFormat:@"%@", tagTextFieldText];
                }
                
                NSString *searchString = [[[newTextFieldContents componentsSeparatedByString:@" "] lastObject] stringByAppendingFormat:@"%@*", string];
                NSArray *existingTags = [tagTextFieldText componentsSeparatedByString:@" "];
                
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                
#warning XXX For some reason, getting double results here sometimes. Search duplication?
                FMResultSet *result = [db executeQuery:@"SELECT DISTINCT tag_fts.name, tag.count FROM tag_fts, tag WHERE tag_fts.name MATCH ? AND tag_fts.name = tag.name ORDER BY tag.count DESC LIMIT 6" withArgumentsInArray:@[searchString]];
                
                NSString *tag, *count;
                NSInteger index = 1;
                NSInteger skipPivot = 0;
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
                                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(j+1) inSection:kBookmarkTopSection]];
                                }
                                
                                tagFound = YES;
                                skipPivot = i+1;
                                break;
                            }
                        }
                        
                        if (!tagFound) {
                            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:kBookmarkTopSection]];
                        }
                        
                        index++;
                        [newTagCompletions addObject:tag];
                    }
                }
                
                [db close];
                
                for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
                }
                
                if (self.popularAndRecommendedTagsVisible) {
                    for (NSInteger i=0; i<self.filteredPopularAndRecommendedTags.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.popularAndRecommendedTagsVisible = NO;
                    self.tagCompletions = newTagCompletions;
                    
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    self.autocompleteInProgress = NO;
                });
            }
            else if (!self.popularAndRecommendedTagsVisible) {
                for (NSInteger i=0; i<self.tagCompletions.count; i++) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
                }
                
                for (NSInteger i=0; i<self.filteredPopularAndRecommendedTags.count; i++) {
                    [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tagCompletions removeAllObjects];
                    self.popularAndRecommendedTagsVisible = YES;
                    
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    self.autocompleteInProgress = NO;
                });
            }
            else {
                self.autocompleteInProgress = NO;
            }
        });
    }
}


- (void)togglePrivate:(id)sender {
    self.setAsPrivate = @(!self.setAsPrivate.boolValue);
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkPrivateRow inSection:kBookmarkBottomSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)toggleRead:(id)sender {
    self.markAsRead = @(!self.markAsRead.boolValue);
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkReadRow inSection:kBookmarkBottomSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)urlTextFieldDidChange:(NSNotification *)notification {
    if ([UIPasteboard generalPasteboard].string == self.urlTextField.text) {
        [self prefillTitleAndForceUpdate:NO];
    }
}

- (void)handleTagSuggestions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.popularAndRecommendedTagsVisible) {
            NSString *tagText = self.tagTextField.text;
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToAdd = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];

            [self.popularTags removeAllObjects];
            [self.recommendedTags removeAllObjects];

            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            
            NSInteger previousEndIndex;
            if (self.popularAndRecommendedTagsVisible) {
                previousEndIndex = self.filteredPopularAndRecommendedTags.count;
            }
            else {
                previousEndIndex = self.tagCompletions.count;
            }
            
            for (NSInteger i=0; i<previousEndIndex; i++) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i + 1) inSection:kBookmarkTopSection]];
            }
            
            NSArray *existingTags = [tagText componentsSeparatedByString:@" "];
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

            if (self.filteredPopularAndRecommendedTags.count > 0) {
                if (self.tagTextField.text.length > 0 && [self.tagTextField.text characterAtIndex:self.tagTextField.text.length-1] != ' ') {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagTextField.text = [NSString stringWithFormat:@"%@ ", self.tagTextField.text];
                    });
                }
            }

            for (NSInteger i=0; i<self.filteredPopularAndRecommendedTags.count; i++) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
            }
            
            if (self.loadingTags) {
                self.loadingTags = NO;
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:kBookmarkTopSection]];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                self.popularAndRecommendedTagsVisible = YES;

                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        }
    });
}

- (void)prefillPopularTags {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    BOOL shouldPrefillTags = !self.loadingTags
    && !self.popularAndRecommendedTagsVisible
    && [[UIApplication sharedApplication] canOpenURL:url]
    && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTags) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingTags = YES;

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kBookmarkTopSection]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [self.popularTags removeAllObjects];
            [self.recommendedTags removeAllObjects];

            [pinboard tagSuggestionsForURL:self.urlTextField.text
                                   success:^(NSArray *popular, NSArray *recommended) {
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                           [self.unfilteredPopularTags addObjectsFromArray:popular];
                                           [self.unfilteredRecommendedTags addObjectsFromArray:recommended];
                                           [self handleTagSuggestions];
                                       });
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                       });
                                   }];
        });
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self handleTagSuggestions];
        });
    }
}

- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    self.previousURLContents = self.urlTextField.text;
    
    BOOL shouldPrefillTitle = !self.loadingTitle
    && (forceUpdate || self.titleTextField == nil || [self.titleTextField.text isEqualToString:@""])
    && [[UIApplication sharedApplication] canOpenURL:url]
    && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTitle) {
        [self.urlTextField resignFirstResponder];
        self.loadingTitle = YES;
        
        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0]];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [[AppDelegate sharedDelegate] retrievePageTitle:url
                                               callback:^(NSString *title, NSString *description) {
                                                   self.titleTextField.text = title;
                                                   self.postDescription = description;
                                                   self.loadingTitle = NO;
                                                   [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                                               }];
    }
}

- (void)close {
    [self.modalDelegate closeModal:self];
}

- (void)addBookmark {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.alertBody = NSLocalizedString(@"Unable to add bookmark; no connection available.", nil);
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [self.modalDelegate closeModal:self];
            });
        }
        
        if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"You can't add a bookmark without a URL or title.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
            });
            return;
        }
        
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *url = self.urlTextField.text;
        if (!url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.alertBody = NSLocalizedString(@"Unable to add bookmark without a URL.", nil);
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [self.modalDelegate closeModal:self];
            });
            return;
        }
        NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:characterSet];
        NSString *description = [self.postDescription stringByTrimmingCharactersInSet:characterSet];
        NSString *tags = [self.tagTextField.text stringByTrimmingCharactersInSet:characterSet];
        BOOL private = self.privateSwitch.on;
        BOOL unread = !self.readSwitch.on;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard addBookmarkWithURL:url
                                   title:title
                             description:description
                                    tags:tags
                                  shared:!private
                                  unread:unread
                                 success:^{
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                         Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                         FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                         BOOL bookmarkAdded;
                                         
                                         [db open];
                                         [db beginTransaction];
                                         
                                         FMResultSet *results = [db executeQuery:@"SELECT hash, COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.urlTextField.text]];
                                         [results next];
                                         
                                         NSString *hash = [results stringForColumnIndex:0];
                                         NSInteger count = [results intForColumnIndex:1];
                                         
                                         NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                       @"url": url,
                                                                                                                       @"title": title,
                                                                                                                       @"description": description,
                                                                                                                       @"tags": tags,
                                                                                                                       @"unread": @(unread),
                                                                                                                       @"private": @(private),
                                                                                                                       @"starred": @(NO)
                                                                                                                       }];
                                         
                                         if (count > 0) {
                                             [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(private), @"Read": @(!unread)}];
                                             
                                             if (hash && ![hash isEqual:[NSNull null]]) {
                                                 params[@"hash"] = hash;
                                                 [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE hash=:hash" withParameterDictionary:params];
                                                 [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                                                 for (NSString *tagName in [tags componentsSeparatedByString:@" "]) {
                                                     [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                                                     [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                                                 }
                                             }
                                             else {
#warning The bookmark doesn't yet have a hash
                                                 [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE url=:url" withParameterDictionary:params];
                                             }
                                             bookmarkAdded = NO;
                                         }
                                         else {
                                             params[@"created_at"] = [NSDate date];
                                             [mixpanel track:@"Added bookmark" properties:@{@"Private": @(private), @"Read": @(!unread)}];
                                             [db executeUpdate:@"INSERT INTO bookmark (meta, title, description, url, private, unread, starred, tags, created_at) VALUES (random(), :title, :description, :url, :private, :unread, :starred, :tags, :created_at);" withParameterDictionary:params];
                                             
                                             bookmarkAdded = YES;
                                         }
                                         
                                         [db commit];
                                         [db close];
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             UILocalNotification *notification = [[UILocalNotification alloc] init];
                                             if (bookmarkAdded) {
                                                 notification.alertBody = NSLocalizedString(@"Your bookmark was added.", nil);
                                             }
                                             else {
                                                 notification.alertBody = NSLocalizedString(@"Your bookmark was updated.", nil);
                                             }
                                             
                                             notification.alertAction = @"Open Pushpin";
                                             notification.userInfo = @{@"success": @YES, @"updated": @YES};
                                             [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                             [self.modalDelegate closeModal:self];
                                         });
                                     });
                                 }
                                 failure:^(NSError *error) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         self.navigationItem.leftBarButtonItem.enabled = YES;
                                         self.navigationItem.rightBarButtonItem.enabled = YES;
                                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"There was an error adding your bookmark.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                         [alert show];
                                     });
                                 }];
        });
    });
}

- (void)fixTextView:(UITextView *)textView {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f) {
        [textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
    }
}

- (void)finishEditingDescription {
    // Update the description text
    self.postDescription = self.postDescriptionTextView.text;
    self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescriptionTextView.text attributes:self.descriptionAttributes];
    
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkDescriptionRow inSection:kBookmarkTopSection]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)gestureDetected:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.tagGestureRecognizer) {
        [self prefillPopularTags];
        [self.tagTextField resignFirstResponder];
    }
    else if (gestureRecognizer == self.titleGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.descriptionGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.leftSwipeTagGestureRecognizer) {
        [self.tagTextField resignFirstResponder];

        if (self.filteredPopularAndRecommendedTags.count > 0) {
            if (self.popularAndRecommendedTagsVisible) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                    for (NSInteger i=0; i<self.filteredPopularAndRecommendedTags.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+1) inSection:kBookmarkTopSection]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.popularTags removeAllObjects];
                        [self.recommendedTags removeAllObjects];
                        self.popularAndRecommendedTagsVisible = NO;

                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    });
                });
            }
        }
    }
    else if (gestureRecognizer == self.badgeTapGestureRecognizer) {
        self.editingTags = YES;
    }
}

- (void)setEditingTags:(BOOL)editingTags {
    _editingTags = editingTags;

    if (editingTags) {
        self.tagTextField.userInteractionEnabled = YES;

        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        
        NSArray *indexPathsToDelete = @[[NSIndexPath indexPathForRow:kBookmarkTitleRow inSection:kBookmarkTopSection],
                                        [NSIndexPath indexPathForRow:kBookmarkDescriptionRow inSection:kBookmarkTopSection]];
        
        NSArray *indexPathsToReload = @[[NSIndexPath indexPathForRow:kBookmarkTagRow inSection:kBookmarkTopSection]];
        
        [CATransaction begin];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kBookmarkBottomSection] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [CATransaction setCompletionBlock:^{
            [self.tagTextField becomeFirstResponder];
        }];
        [CATransaction commit];
    }
    else {
        self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
        self.tagTextField.userInteractionEnabled = NO;
        [self.tagTextField resignFirstResponder];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;

        NSArray *indexPathsToInsert = @[[NSIndexPath indexPathForRow:kBookmarkTitleRow inSection:kBookmarkTopSection],
                                        [NSIndexPath indexPathForRow:kBookmarkDescriptionRow inSection:kBookmarkTopSection]];
        
        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
        NSArray *indexPathsToReload = @[[NSIndexPath indexPathForRow:0 inSection:kBookmarkTopSection]];

        if (self.popularAndRecommendedTagsVisible) {
            for (NSInteger i=1; i<self.filteredPopularAndRecommendedTags.count+1; i++) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:kBookmarkTopSection]];
            }
        }
        else {
            for (NSInteger i=1; i<self.tagCompletions.count+1; i++) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:kBookmarkTopSection]];
            }
        }
        
        [self.tagCompletions removeAllObjects];
        [self.popularTags removeAllObjects];
        [self.recommendedTags removeAllObjects];
        self.popularAndRecommendedTagsVisible = NO;

        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kBookmarkBottomSection] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (NSArray *)filteredPopularAndRecommendedTags {
    return [self.popularTags arrayByAddingObjectsFromArray:self.recommendedTags];
}

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags {
    NSMutableArray *badges = [NSMutableArray array];

    NSString *tagText = [self.tagTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *existingTags = [tagText componentsSeparatedByString:@" "];
    for (NSString *tag in existingTags) {
        if (![tag isEqualToString:@""]) {
            [badges addObject:@{ @"type": @"tag", @"tag": tag }];
        }
    }
    
    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme tagFontSize]) }];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.badgeTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.badgeTapGestureRecognizer.numberOfTapsRequired = 1;

    [wrapper addGestureRecognizer:self.badgeTapGestureRecognizer];
    return wrapper;
}

@end

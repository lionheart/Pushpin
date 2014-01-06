
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
#import "PPTableViewTitleView.h"
#import "PPEditDescriptionViewController.h"
#import "PinboardDataSource.h"
#import "PPConstants.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface AddBookmarkViewController ()

@property (nonatomic, strong) NSMutableDictionary *descriptionAttributes;
@property (nonatomic, weak) id<ModalDelegate> modalDelegate;

@end

@implementation AddBookmarkViewController

#pragma mark - Instantiation

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.scrollEnabled = YES;
        
        self.postDescription = @"";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

        self.descriptionAttributes = [@{NSFontAttributeName: [UIFont fontWithName:[PPTheme fontName] size:16],
                                        NSForegroundColorAttributeName: HEX(0xc7c7cdff),
                                        NSParagraphStyleAttributeName: paragraphStyle } mutableCopy];
        
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
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
        self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Swipe right to prefill", nil);
        self.titleTextField.text = @"";

        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = font;
        self.tagTextField.placeholder = @"Tap to add tags.";
        self.tagTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.userInteractionEnabled = NO;
        self.tagTextField.text = @"";

        self.markAsRead = @(NO);
        self.loadingTitle = NO;
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
        self.existingTags = [NSMutableArray array];
        
        self.callback = ^(void) {};
        self.titleGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.titleGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.titleTextField addGestureRecognizer:self.titleGestureRecognizer];
        self.descriptionGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self.descriptionGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];

        [self.descriptionTextLabel addGestureRecognizer:self.descriptionGestureRecognizer];
        
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
                                                             delegate:(id<ModalDelegate>)delegate
                                                             callback:(void (^)())callback {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE url=?" withArgumentsInArray:@[urlString]];
    [results next];
    NSDictionary *post = [PinboardDataSource postFromResultSet:results];
    [db close];
    
    return [AddBookmarkViewController addBookmarkViewControllerWithBookmark:post
                                                                     update:@(YES)
                                                                   delegate:delegate
                                                                   callback:callback];
}

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark
                                                           update:(NSNumber *)isUpdate
                                                         delegate:(id <ModalDelegate>)delegate
                                                         callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    PPNavigationController *addBookmarkViewNavigationController = [[PPNavigationController alloc] initWithRootViewController:addBookmarkViewController];

    addBookmarkViewController.bookmarkData = bookmark;
    addBookmarkViewController.modalDelegate = delegate;
    [addBookmarkViewController setIsUpdate:isUpdate.boolValue];
    
    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(rightBarButtonTouchUpInside:)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark", nil);
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    else {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(rightBarButtonTouchUpInside:)];
        addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark", nil);
    }
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(leftBarButtonTouchUpInside:)];
    
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
        NSString *tags = [bookmark[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (tags.length > 0) {
            addBookmarkViewController.existingTags = [[tags componentsSeparatedByString:@" "] mutableCopy];
        }
    }

    addBookmarkViewController.badgeWrapperView = [addBookmarkViewController badgeWrapperViewForCurrentTags];
    addBookmarkViewController.badgeWrapperView.userInteractionEnabled = NO;
    
    if (bookmark[@"description"]) {
        addBookmarkViewController.postDescription = [bookmark[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (![addBookmarkViewController.postDescription isEqualToString:@""]) {
            addBookmarkViewController.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:addBookmarkViewController.postDescription attributes:addBookmarkViewController.descriptionAttributes];
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

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.urlTextField];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];

    // We need to set this here, since on iPad the table view's frame isn't set until this happens.
    self.descriptionTextLabel.preferredMaxLayoutWidth = self.tableView.frame.size.width - 50;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.callback();
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kBookmarkTopSection:
            return kBookmarkTagRow + 1;
            
        case kBookmarkBottomSection:
            return 2;
            
        default:
            return 0;
    }
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
                        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                        [activity startAnimating];
                        cell.accessoryView = activity;
                        [cell.contentView lhs_addConstraints:@"H:|-40-[title]-30-|" views:views];
                    }
                    else {
                        [cell.contentView lhs_addConstraints:@"H:|-40-[title]-10-|" views:views];
                    }

                    if (self.isUpdate) {
                        self.urlTextField.font = [UIFont fontWithName:[PPTheme fontName] size:14];
                        self.urlTextField.textColor = [UIColor grayColor];
                    }
                    else {
                        self.urlTextField.font = [UIFont fontWithName:[PPTheme fontName] size:16];
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
                        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                        [activity startAnimating];
                        cell.accessoryView = activity;
                        self.descriptionAttributes[NSForegroundColorAttributeName] = HEX(0xc7c7cdff);
                        self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Loading..." attributes:self.descriptionAttributes];
                    }
                    else {
                        if ([self.postDescription isEqualToString:@""]) {
                            self.descriptionAttributes[NSForegroundColorAttributeName] = HEX(0xc7c7cdff);
                            self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Tap to add a description.", nil) attributes:self.descriptionAttributes];
                        }
                        else {
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
                    }
                    else {
                        self.tagTextField.hidden = YES;
                    }
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

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
                    if (self.descriptionTextLabel.text && ![self.descriptionTextLabel.text isEqualToString:@""]) {
                        CGFloat width = self.view.frame.size.width - 50;
                        CGRect descriptionRect = [self.descriptionTextLabel textRectForBounds:CGRectMake(0, 0, width, CGFLOAT_MAX) limitedToNumberOfLines:3];
                        return CGRectGetHeight(descriptionRect) + 20;
                    }
                    else {
                        return 42;
                    }
                }
                    
                case kBookmarkTagRow: {
                    CGFloat width = self.view.frame.size.width - 50;
                    return MAX(44, [self.badgeWrapperView calculateHeightForWidth:width] + 20);
                }
            }
    }
    
    return 44;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case kBookmarkTopSection:
            switch (indexPath.row) {
                case kBookmarkDescriptionRow: {
                    PPEditDescriptionViewController *editDescriptionViewController = [[PPEditDescriptionViewController alloc] initWithDescription:self.postDescription];
                    editDescriptionViewController.delegate = self;
                    [self.navigationController pushViewController:editDescriptionViewController animated:YES];
                    break;
                }
                    
                case kBookmarkTagRow: {
                    PPTagEditViewController *tagEditViewController = [[PPTagEditViewController alloc] init];
                    tagEditViewController.tagDelegate = self;
                    tagEditViewController.bookmarkData = self.bookmarkData;
                    tagEditViewController.existingTags = [self.existingTags mutableCopy];
                    [self.navigationController pushViewController:tagEditViewController animated:YES];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    if (textField == self.urlTextField) {
        [self prefillTitleAndForceUpdate:NO];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *invalidCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (textField == self.urlTextField) {
        if ([string rangeOfCharacterFromSet:invalidCharacterSet].location != NSNotFound) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;
    return YES;
}

#pragma mark - Everything Else

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

        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [[AppDelegate sharedDelegate] retrievePageTitle:url
                                               callback:^(NSString *title, NSString *description) {
                                                   self.titleTextField.text = title;
                                                   self.postDescription = description;

                                                   self.descriptionAttributes[NSForegroundColorAttributeName] = [UIColor blackColor];
                                                   self.descriptionTextLabel.attributedText = [[NSAttributedString alloc] initWithString:self.postDescription attributes:self.descriptionAttributes];
                                                   self.loadingTitle = NO;

                                                   [self.tableView beginUpdates];
                                                   [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView endUpdates];
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
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
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
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [self.modalDelegate closeModal:self];
            });
            return;
        }
        NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:characterSet];
        NSString *description = [self.postDescription stringByTrimmingCharactersInSet:characterSet];
        NSString *tags = [[self existingTags] componentsJoinedByString:@" "];
        BOOL private = self.setAsPrivate.boolValue;
        BOOL unread = !(self.markAsRead.boolValue);
        
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
                                             notification.userInfo = @{@"success": @(YES), @"updated": @(YES)};
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

- (void)gestureDetected:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.titleGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.descriptionGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
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

    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme staticBadgeFontSize]) }];
    wrapper.userInteractionEnabled = NO;
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    return wrapper;
}

- (void)rightBarButtonTouchUpInside:(id)sender {
    [self addBookmark];
}

- (void)leftBarButtonTouchUpInside:(id)sender {
    [self.modalDelegate closeModal:self];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - PPTagEditing

- (void)tagEditViewControllerDidUpdateTags:(PPTagEditViewController *)tagEditViewController {
    self.existingTags = [tagEditViewController.existingTags mutableCopy];
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kBookmarkTagRow inSection:kBookmarkTopSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
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

@end

//
//  PPSearchViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

#import "PPSearchViewController.h"
#import "PPTheme.h"
#import "PPSearchExamplesViewController.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "UITableViewCellValue1.h"
#import "PPTitleButton.h"
#import "AppDelegate.h"
#import "FeedListViewController.h"
#import "DeliciousDataSource.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPSearchViewController ()

@property (nonatomic, strong) UITextField *searchTextField;

@property (nonatomic, strong) UIActionSheet *starredActionSheet;
@property (nonatomic, strong) UIActionSheet *isPrivateActionSheet;
@property (nonatomic, strong) UIActionSheet *unreadActionSheet;
@property (nonatomic, strong) UIActionSheet *untaggedActionSheet;

@property (nonatomic) kPushpinFilterType starred;
@property (nonatomic) kPushpinFilterType isPrivate;
@property (nonatomic) kPushpinFilterType read;
@property (nonatomic) kPushpinFilterType tagged;

- (void)searchBarButtonItemTouchUpInside:(id)sender;
- (void)cancelBarButtonItemTouchUpInside:(id)sender;
- (void)switchValueChanged:(UISwitch *)sender;

- (void)keyboardWillHide:(NSNotification *)sender;
- (void)keyboardDidShow:(NSNotification *)sender;

@end

@implementation PPSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *button = [PPTitleButton button];
    [button setTitle:@"Advanced Search" imageName:nil];
    self.navigationItem.titleView = button;

    if ([UIApplication isIPad]) {
        
    }
    else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonItemTouchUpInside:)];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleDone target:nil action:nil];
        [self.navigationItem setBackBarButtonItem:backButton];
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonItemTouchUpInside:)];
    
    self.starred = kPushpinFilterNone;
    self.isPrivate = kPushpinFilterNone;
    self.read = kPushpinFilterNone;
    self.tagged = kPushpinFilterNone;
    
    UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.font = font;
    self.searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTextField.userInteractionEnabled = YES;
    self.searchTextField.delegate = self;
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.searchTextField.placeholder = NSLocalizedString(@"Search query", nil);
    
    self.isPrivateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Private", @"Public", @"Clear", nil];
    self.isPrivateActionSheet.destructiveButtonIndex = 2;
    
    self.starredActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Starred", @"Unstarred", @"Clear", nil];
    self.starredActionSheet.destructiveButtonIndex = 2;

    self.unreadActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Read", @"Unread", @"Clear", nil];
    self.unreadActionSheet.destructiveButtonIndex = 2;

    self.untaggedActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Tagged", @"Untagged", @"Clear", nil];
    self.untaggedActionSheet.destructiveButtonIndex = 2;
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return PPSearchQueryRowCount;
            
        case PPSearchSectionFilters:
            return PPSearchFilterRowCount;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return nil;
            
        case PPSearchSectionFilters:
            return @"Filters";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];

    switch ((PPSearchSectionType)indexPath.section) {
        case PPSearchSectionQuery: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.hidden = YES;
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            [cell.contentView addSubview:self.searchTextField];
            
            NSDictionary *views = @{@"view": self.searchTextField };
            [cell.contentView lhs_addConstraints:@"H:|-15-[view]-15-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-10-[view]" views:views];
            break;
        }

        case PPSearchSectionFilters: {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.hidden = NO;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            kPushpinFilterType filter;

            switch ((PPSearchFilterRowType)indexPath.row) {
                case PPSearchFilterPrivate:
                    filter = self.isPrivate;

                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = NSLocalizedString(@"Private", nil);
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = NSLocalizedString(@"Public", nil);
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@", NSLocalizedString(@"Private", nil), NSLocalizedString(@"Public", nil)];
                            break;
                    }
                    break;
                    
#ifdef PINBOARD
                case PPSearchFilterStarred:
                    filter = self.starred;
                    
                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = NSLocalizedString(@"Unstarred", nil);
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@", NSLocalizedString(@"Starred", nil), NSLocalizedString(@"Unstarred", nil)];
                            break;
                    }
                    break;
#endif
                    
                case PPSearchFilterUnread:
                    filter = self.read;

                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = NSLocalizedString(@"Read", nil);
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@", NSLocalizedString(@"Read", nil), NSLocalizedString(@"Unread", nil)];
                            break;
                    }
                    break;

                case PPSearchFilterUntagged:
                    filter = self.tagged;

                    if (filter == kPushpinFilterTrue) {
                        cell.textLabel.text = NSLocalizedString(@"Tagged", nil);
                    }
                    else {
                        cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    }
                    
                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = NSLocalizedString(@"Tagged", nil);
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@", NSLocalizedString(@"Tagged", nil), NSLocalizedString(@"Untagged", nil)];
                            break;
                    }
                    break;
            }
            
            switch (filter) {
                case kPushpinFilterTrue: {
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"roundbutton-checkmark"] lhs_imageWithColor:HEX(0x53A93FFF)]];
                    cell.textLabel.textColor = [UIColor blackColor];
                    break;
                }
                    
                case kPushpinFilterFalse:
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"roundbutton-checkmark"] lhs_imageWithColor:HEX(0xEF6034FF)]];
                    cell.textLabel.textColor = [UIColor blackColor];
                    break;
                    
                case kPushpinFilterNone:
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"roundbutton-checkmark"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                    break;
            }
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return @"Tap the info button to read about advanced searches.";
            
        case PPSearchSectionFilters:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    switch ((PPSearchSectionType)indexPath.section) {
        case PPSearchSectionQuery: {
            PPSearchExamplesViewController *examples = [[PPSearchExamplesViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:examples animated:YES];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ((PPSearchSectionType)indexPath.section) {
        case PPSearchSectionQuery:
            [self.searchTextField becomeFirstResponder];
            break;
            
        case PPSearchSectionFilters:
            switch ((PPSearchFilterRowType)indexPath.row) {
                case PPSearchFilterPrivate:
                    [self.isPrivateActionSheet showInView:self.view];
                    break;
                    
                case PPSearchFilterUnread:
                    [self.unreadActionSheet showInView:self.view];
                    break;
                    
                case PPSearchFilterUntagged:
                    [self.untaggedActionSheet showInView:self.view];
                    break;
                    
#ifdef PINBOARD
                case PPSearchFilterStarred:
                    [self.starredActionSheet showInView:self.view];
                    break;
#endif
            }
            break;
    }
}

#pragma -

- (void)searchBarButtonItemTouchUpInside:(id)sender {
    GenericPostViewController *genericPostViewController = [[GenericPostViewController alloc] init];
    
#ifdef PINBOARD
    PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
    
    if (self.searchTextField.text && ![self.searchTextField.text isEqualToString:@""]) {
        dataSource.searchQuery = self.searchTextField.text;
    }

    dataSource.isPrivate = self.isPrivate;
    dataSource.starred = self.starred;
    
    switch (self.read) {
        case kPushpinFilterTrue:
            dataSource.unread = kPushpinFilterFalse;
            break;
            
        case kPushpinFilterFalse:
            dataSource.unread = kPushpinFilterTrue;
            break;
            
        case kPushpinFilterNone:
            dataSource.unread = kPushpinFilterNone;
            break;
    }
    
    switch (self.tagged) {
        case kPushpinFilterTrue:
            dataSource.untagged = kPushpinFilterFalse;
            break;
            
        case kPushpinFilterFalse:
            dataSource.untagged = kPushpinFilterTrue;
            break;
            
        case kPushpinFilterNone:
            dataSource.untagged = kPushpinFilterNone;
            break;
    }
#endif
    
#ifdef DELICIOUS
    DeliciousDataSource *dataSource = [[DeliciousDataSource alloc] init];
    
    if (self.searchTextField.text && ![self.searchTextField.text isEqualToString:@""]) {
        dataSource.searchQuery = self.searchTextField.text;
    }
    
    dataSource.isPrivate = self.isPrivate;
    
    switch (self.read) {
        case kPushpinFilterTrue:
            dataSource.unread = kPushpinFilterFalse;
            break;
            
        case kPushpinFilterFalse:
            dataSource.unread = kPushpinFilterTrue;
            break;
            
        case kPushpinFilterNone:
            dataSource.unread = kPushpinFilterNone;
            break;
    }
    
    switch (self.tagged) {
        case kPushpinFilterTrue:
            dataSource.untagged = kPushpinFilterFalse;
            break;
            
        case kPushpinFilterFalse:
            dataSource.untagged = kPushpinFilterTrue;
            break;
            
        case kPushpinFilterNone:
            dataSource.untagged = kPushpinFilterNone;
            break;
    }
#endif

    genericPostViewController.postDataSource = dataSource;
    
    // We need to switch this based on whether the user is on an iPad, due to the split view controller.
    if ([UIApplication isIPad]) {
        UINavigationController *navigationController = [AppDelegate sharedDelegate].navigationController;
        if (navigationController.viewControllers.count == 1) {
            UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
            if (showPopoverBarButtonItem) {
                genericPostViewController.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
            }
        }
        
        [navigationController setViewControllers:@[genericPostViewController] animated:YES];
        
        if ([dataSource respondsToSelector:@selector(barTintColor)]) {
            [self.navigationController.navigationBar setBarTintColor:[dataSource barTintColor]];
        }
        
        UIPopoverController *popover = [AppDelegate sharedDelegate].feedListViewController.popover;
        if (popover) {
            [popover dismissPopoverAnimated:YES];
        }
    }
    else {
        [self.navigationController pushViewController:genericPostViewController animated:YES];
    }
}

- (void)cancelBarButtonItemTouchUpInside:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    kPushpinFilterType filter;
    switch (buttonIndex) {
        case 0:
            filter = kPushpinFilterTrue;
            break;
            
        case 1:
            filter = kPushpinFilterFalse;
            break;
            
        case 2:
            filter = kPushpinFilterNone;
            break;

        case 3:
            return;
    }

    PPSearchFilterRowType rowType;
    if (actionSheet == self.isPrivateActionSheet) {
        self.isPrivate = filter;
        rowType = PPSearchFilterPrivate;
    }
    else if (actionSheet == self.unreadActionSheet) {
        self.read = filter;
        rowType = PPSearchFilterUnread;
    }
    else if (actionSheet == self.untaggedActionSheet) {
        self.tagged = filter;
        rowType = PPSearchFilterUntagged;
    }
#ifdef PINBOARD
    else if (actionSheet == self.starredActionSheet) {
        self.starred = filter;
        rowType = PPSearchFilterStarred;
    }
#endif
    else {
        return;
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowType inSection:PPSearchSectionFilters]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self searchBarButtonItemTouchUpInside:textField];
    return NO;
}

#pragma mark -

- (void)keyboardDidShow:(NSNotification *)sender {
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    [self.view layoutIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)sender {
    self.bottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
}

@end

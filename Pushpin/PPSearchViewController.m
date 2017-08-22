//
//  PPSearchViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

@import LHSCategoryCollection;
@import LHSKeyboardAdjusting;
@import LHSTableViewCells;
@import ASPinboard;

#import "PPSearchViewController.h"
#import "PPTheme.h"
#import "PPSearchExamplesViewController.h"
#import "PPGenericPostViewController.h"
#import "PPPinboardDataSource.h"
#import "PPAppDelegate.h"
#import "PPFeedListViewController.h"
#import "PPSettings.h"
#import "PPUtilities.h"

static NSString *DefaultCellIdentifier = @"DefaultCellIdentifier";
static NSString *CellIdentifier = @"CellIdentifier";
static NSString *SubtitleCellIdentifier = @"SubtitleCellIdentifier";

@interface PPSearchViewController ()

@property (nonatomic, strong) UITextField *searchTextField;

@property (nonatomic, strong) UIAlertController *starredActionSheet;
@property (nonatomic, strong) UIAlertController *isPrivateActionSheet;
@property (nonatomic, strong) UIAlertController *unreadActionSheet;
@property (nonatomic, strong) UIAlertController *untaggedActionSheet;
@property (nonatomic, strong) UIAlertController *searchScopeActionSheet;
@property (nonatomic, strong) UIAlertController *fullTextSearchAlert;

@property (nonatomic) kPushpinFilterType starred;
@property (nonatomic) kPushpinFilterType isPrivate;
@property (nonatomic) kPushpinFilterType read;
@property (nonatomic) kPushpinFilterType tagged;
@property (nonatomic) PPSearchScopeType searchScope;


@property (nonatomic) ASPinboardSearchScopeType pinboardSearchScope;

- (void)searchBarButtonItemTouchUpInside:(id)sender;
- (void)cancelBarButtonItemTouchUpInside:(id)sender;
- (void)switchValueChanged:(UISwitch *)sender;

@end

@implementation PPSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *button = [PPTitleButton button];
    [button setTitle:NSLocalizedString(@"Advanced Search", nil) imageName:nil];
    self.navigationItem.titleView = button;

    if ([UIApplication isIPad]) {
        
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonItemTouchUpInside:)];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleDone target:nil action:nil];
        [self.navigationItem setBackBarButtonItem:backButton];
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonItemTouchUpInside:)];
    
    self.starred = kPushpinFilterNone;
    self.isPrivate = kPushpinFilterNone;
    self.read = kPushpinFilterNone;
    self.tagged = kPushpinFilterNone;
    self.searchScope = PPSearchScopeMine;
    
    self.fullTextSearchAlert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                   message:NSLocalizedString(@"To enable Pinboard full-text search, please log out and then log back in.", nil)];

    [self.fullTextSearchAlert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:nil];
    

    self.pinboardSearchScope = ASPinboardSearchScopeNone;
    
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
    
    self.isPrivateActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    [self.isPrivateActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Private", nil)
                                                style:UIAlertActionStyleDefault
                                              handler:nil];
    
    [self.isPrivateActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Public", nil)
                                                style:UIAlertActionStyleDefault
                                              handler:nil];
    
    [self.isPrivateActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Clear", nil)
                                                style:UIAlertActionStyleDestructive
                                              handler:nil];
    
    [self.isPrivateActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                style:UIAlertActionStyleCancel
                                              handler:nil];
    
    self.starredActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    [self.starredActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Starred", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil];
    
    [self.starredActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Unstarred", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil];
    
    [self.starredActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Clear", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:nil];
    
    [self.starredActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil];
    
    self.unreadActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    [self.unreadActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Read", nil)
                                             style:UIAlertActionStyleDefault
                                           handler:nil];
    
    [self.unreadActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Unread", nil)
                                             style:UIAlertActionStyleDefault
                                           handler:nil];
    
    [self.unreadActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Clear", nil)
                                             style:UIAlertActionStyleDestructive
                                           handler:nil];
    
    [self.unreadActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                             style:UIAlertActionStyleCancel
                                           handler:nil];
    
    self.untaggedActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    [self.untaggedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Tagged", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:nil];
    
    [self.untaggedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Untagged", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:nil];
    
    [self.untaggedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Clear", nil)
                                               style:UIAlertActionStyleDestructive
                                             handler:nil];
    
    [self.untaggedActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                               style:UIAlertActionStyleCancel
                                             handler:nil];
    
    self.searchScopeActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];
    
    for (NSString *scope in PPSearchScopes()) {
        [self.searchScopeActionSheet lhs_addActionWithTitle:scope
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        NSInteger buttonIndex = [self.searchScopeActionSheet.actions indexOfObject:action];
                                                        if (buttonIndex == [PPSearchScopes() count]) {
                                                            return;
                                                        }
                                                        
                                                        NSString *title = action.title;
                                                        
                                                        PPSearchScopeType previousSearchScope = self.searchScope;
                                                        self.searchScope = (PPSearchScopeType)[PPSearchScopes() indexOfObject:title];
                                                        
                                                        if (self.searchScope == PPSearchScopePinboard) {
                                                            // Check if the user has no username or password set.
                                                            PPSettings *settings = [PPSettings sharedSettings];
                                                            if ([settings.username length] == 0 || [settings.password length] == 0) {
                                                                self.searchScope = PPSearchScopeMine;
                                                                [self presentViewController:self.fullTextSearchAlert animated:YES completion:nil];
                                                            } else {
                                                                self.pinboardSearchScope = ASPinboardSearchScopeFullText;
                                                            }
                                                        } else {
                                                            self.pinboardSearchScope = ASPinboardSearchScopeMine;
                                                        }
                                                        
                                                        [self.tableView beginUpdates];
                                                        
                                                        if (self.searchScope != previousSearchScope) {
                                                            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPSearchScopeRow inSection:PPSearchSectionScope]] withRowAnimation:UITableViewRowAnimationFade];
                                                            
                                                            switch (self.searchScope) {
                                                                case PPSearchScopeMine:
                                                                    self.pinboardSearchScope = ASPinboardSearchScopeNone;
                                                                    
                                                                    switch (previousSearchScope) {
                                                                        case PPSearchScopeMine:
                                                                            break;
                                                                            
                                                                        case PPSearchScopePinboard:
                                                                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPSearchSectionSave] withRowAnimation:UITableViewRowAnimationFade];
                                                                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopeEveryone:
                                                                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopeNetwork:
                                                                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                    }
                                                                    break;
                                                                    
                                                                case PPSearchScopeNetwork:
                                                                    self.pinboardSearchScope = ASPinboardSearchScopeNetwork;
                                                                    
                                                                    switch (previousSearchScope) {
                                                                        case PPSearchScopeMine:
                                                                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopePinboard:
                                                                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        default:
                                                                            break;
                                                                    }
                                                                    break;
                                                                    
                                                                case PPSearchScopeEveryone:
                                                                    self.pinboardSearchScope = ASPinboardSearchScopeAll;
                                                                    
                                                                    switch (previousSearchScope) {
                                                                        case PPSearchScopeMine:
                                                                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopePinboard:
                                                                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        default:
                                                                            break;
                                                                    }
                                                                    break;
                                                                    
                                                                case PPSearchScopePinboard:
                                                                    self.pinboardSearchScope = ASPinboardSearchScopeMine;
                                                                    
                                                                    switch (previousSearchScope) {
                                                                        case PPSearchScopeMine:
                                                                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPSearchSectionSave] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopePinboard:
                                                                            break;
                                                                            
                                                                        case PPSearchScopeEveryone:
                                                                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                            
                                                                        case PPSearchScopeNetwork:
                                                                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPSearchSectionFilters] withRowAnimation:UITableViewRowAnimationFade];
                                                                            break;
                                                                    }
                                                            }
                                                        }
                                                        [self.tableView endUpdates];
                                                    }];
    }
    
    [self.searchScopeActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DefaultCellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBarTintColor:HEX(0x0096FFFF)];
    
    [self lhs_activateKeyboardAdjustment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self lhs_deactivateKeyboardAdjustment];
}

#pragma mark - LHSKeyboardAdjusting

- (UIView *)keyboardAdjustingView {
    return self.tableView;
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return PPSearchQueryRowCount;
            
        case PPSearchSectionScope:
            return PPSearchScopeRowCount;

        case PPSearchSectionFilters:
            switch (self.searchScope) {
                case PPSearchScopeMine:
                    return PPSearchFilterRowCount;
                    
                case PPSearchScopePinboard:
                    return 1;
                    
                default:
                    return 0;
            }
            
        case PPSearchSectionSave:
            return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    switch (self.searchScope) {
        case PPSearchScopeMine:
            return 4;
            
        case PPSearchScopeEveryone:
            return 3;
            
        case PPSearchScopeNetwork:
            return 3;
            
        case PPSearchScopePinboard:
            return 3;
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return nil;
            
        case PPSearchSectionScope:
            return nil;
            
        case PPSearchSectionFilters:
            return @"Filters";
            
        case PPSearchSectionSave:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PPSearchSectionFilters && indexPath.row == 0) {
        if (self.searchScope == PPSearchScopePinboard) {
            return 50;
        }
    }

    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    switch ((PPSearchSectionType)indexPath.section) {
        case PPSearchSectionQuery: {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];

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
            
        case PPSearchSectionScope: {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.hidden = NO;
            cell.textLabel.text = @"Search method";

            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.detailTextLabel.text = PPSearchScopes()[self.searchScope];

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case PPSearchSectionFilters: {
            switch (self.searchScope) {
                case PPSearchScopePinboard: {
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.textLabel.textColor = [UIColor blackColor];

                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];

                    cell.textLabel.text = NSLocalizedString(@"Search Full-Text", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"For archival accounts only.", nil);


                    switch (self.pinboardSearchScope) {
                        case ASPinboardSearchScopeFullText: {
                            cell.accessoryType = UITableViewCellAccessoryCheckmark;
                            break;
                        }

                        case ASPinboardSearchScopeMine:
                            cell.accessoryType = UITableViewCellAccessoryNone;
                            break;
                            
                        default:
                            break;
                    }
                    break;
                }

                case PPSearchScopeMine: {
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];

                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.hidden = NO;
                    cell.detailTextLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                    kPushpinFilterType filter;
                    
                    switch ((PPSearchFilterRowType)indexPath.row) {
                        case PPSearchFilterPrivate:
                            filter = self.isPrivate;
                            
                            switch (filter) {
                                case kPushpinFilterTrue: {
                                    cell.textLabel.text = NSLocalizedString(@"Private", nil);
                                    
                                    // We invert this since public -> green, private -> red
                                    filter = kPushpinFilterFalse;
                                    break;
                                }
                                    
                                case kPushpinFilterFalse:
                                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                                    
                                    // We invert this since public -> green, private -> red
                                    filter = kPushpinFilterTrue;
                                    break;
                                    
                                case kPushpinFilterNone:
                                    cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@", NSLocalizedString(@"Public", nil), NSLocalizedString(@"Private", nil)];
                                    break;
                            }
                            break;
                            

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
                            } else {
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

                default:
                    break;
            }
            
            break;
        }
            
        case PPSearchSectionSave: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Save Search", nil);

            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            UIColor *color = [button titleColorForState:UIControlStateNormal];
            
            cell.textLabel.textColor = color;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    PPSearchSectionType sectionType = (PPSearchSectionType)section;
    switch (sectionType) {
        case PPSearchSectionQuery:
            return NSLocalizedString(@"Tap the info button to read about advanced searches.", nil);
            
        case PPSearchSectionScope:
            return nil;
            
        case PPSearchSectionFilters:
            return nil;
            
        case PPSearchSectionSave:
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
            
        case PPSearchSectionScope: {
            UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
            self.searchScopeActionSheet.popoverPresentationController.sourceView = cell;
            self.searchScopeActionSheet.popoverPresentationController.sourceRect = [cell lhs_centerRect];
            [self presentViewController:self.searchScopeActionSheet animated:YES completion:nil];
            break;
        }
            
        case PPSearchSectionFilters:
            switch (self.searchScope) {
                case PPSearchScopePinboard:

                    switch (self.pinboardSearchScope) {
                        case ASPinboardSearchScopeFullText: {
                            // Check if the user has no username or password set.
                            PPSettings *settings = [PPSettings sharedSettings];
                            if ([settings.username length] == 0 || [settings.password length] == 0) {
                                [self presentViewController:self.fullTextSearchAlert animated:YES completion:nil];
                            } else {
                                self.pinboardSearchScope = ASPinboardSearchScopeMine;
                            }
                            break;
                        }
                            
                        case ASPinboardSearchScopeMine:
                            self.pinboardSearchScope = ASPinboardSearchScopeFullText;
                            break;
                            
                        default:
                            break;
                    }
                    break;

                case PPSearchScopeMine:
                    switch ((PPSearchFilterRowType)indexPath.row) {
                        case PPSearchFilterPrivate:
                            switch (self.isPrivate) {
                                case kPushpinFilterTrue:
                                    self.isPrivate = kPushpinFilterNone;
                                    break;
                                    
                                case kPushpinFilterFalse:
                                    self.isPrivate = kPushpinFilterTrue;
                                    break;
                                    
                                case kPushpinFilterNone:
                                    self.isPrivate = kPushpinFilterFalse;
                                    break;
                            }
                            
                            break;
                            
                        case PPSearchFilterUnread:
                            switch (self.read) {
                                case kPushpinFilterTrue:
                                    self.read = kPushpinFilterFalse;
                                    break;
                                    
                                case kPushpinFilterFalse:
                                    self.read = kPushpinFilterNone;
                                    break;
                                    
                                case kPushpinFilterNone:
                                    self.read = kPushpinFilterTrue;
                                    break;
                            }
                            
                            break;
                            
                        case PPSearchFilterUntagged:
                            switch (self.tagged) {
                                case kPushpinFilterTrue:
                                    self.tagged = kPushpinFilterFalse;
                                    break;
                                    
                                case kPushpinFilterFalse:
                                    self.tagged = kPushpinFilterNone;
                                    break;
                                    
                                case kPushpinFilterNone:
                                    self.tagged = kPushpinFilterTrue;
                                    break;
                            }
                            
                            break;
                            

                        case PPSearchFilterStarred:
                            switch (self.starred) {
                                case kPushpinFilterTrue:
                                    self.starred = kPushpinFilterFalse;
                                    break;
                                    
                                case kPushpinFilterFalse:
                                    self.starred = kPushpinFilterNone;
                                    break;
                                    
                                case kPushpinFilterNone:
                                    self.starred = kPushpinFilterTrue;
                                    break;
                            }
                            
                            break;
                    }
                    break;
                    
                default:
                    break;
            }
            
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
            
        case PPSearchSectionSave: {
            UIAlertController *alert = [PPUtilities saveSearchAlertControllerWithQuery:self.searchTextField.text
                                                                             isPrivate:self.isPrivate
                                                                                unread:[PPUtilities inverseValueForFilter:self.read]
                                                                               starred:self.starred
                                                                                tagged:self.tagged
                                                                            completion:^{
                                                                                nil;
                                                                            }];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma -

- (void)searchBarButtonItemTouchUpInside:(id)sender {
    PPGenericPostViewController *genericPostViewController = [[PPGenericPostViewController alloc] init];
    [self.view endEditing:YES];
    

    PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
    
    if (self.searchTextField.text && ![self.searchTextField.text isEqualToString:@""]) {
        dataSource.searchQuery = self.searchTextField.text;
    }

    dataSource.searchScope = self.pinboardSearchScope;
    switch (self.searchScope) {
        case PPSearchScopeMine:
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
            break;
            
        default:
            break;
    }

    

    genericPostViewController.postDataSource = dataSource;
    
    // We need to switch this based on whether the user is on an iPad, due to the split view controller.
    if ([UIApplication isIPad]) {
        UINavigationController *navigationController = [PPAppDelegate sharedDelegate].navigationController;
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
        
        UIPopoverController *popover = [PPAppDelegate sharedDelegate].feedListViewController.popover;
        if (popover) {
            [popover dismissPopoverAnimated:YES];
        }
    } else {
        [self.navigationController pushViewController:genericPostViewController animated:YES];
    }
}

- (void)cancelBarButtonItemTouchUpInside:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self searchBarButtonItemTouchUpInside:textField];
    return NO;
}

@end

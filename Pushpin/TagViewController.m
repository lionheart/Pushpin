//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

@import QuartzCore;

#import "TagViewController.h"
#import "FMDatabase.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "UITableViewCellValue1.h"
#import "PPTableViewTitleView.h"
#import "FeedListViewController.h"
#import "DeliciousDataSource.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"TagCell";

@interface TagViewController ()

@property (nonatomic) BOOL searchInProgress;
@property (nonatomic, strong) NSMutableDictionary *sectionTitles;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) UIActionSheet *tagActionSheet;
@property (nonatomic, strong) UIAlertView *deleteConfirmationAlertView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSTimer *tagUpdateTimer;

- (void)updateTagsAndCounts;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (NSString *)titleForSectionIndex:(NSInteger)section;
- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)sortedSectionTitles:(NSDictionary *)sectionTitles;

@end

@implementation TagViewController

@synthesize searchDisplayController = __searchDisplayController;
@synthesize searchBar = _searchBar;

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Tags", nil) imageName:nil];
    
    // TODO Trying to get this to @"" but back button still displays "Back"
    self.navigationItem.titleView = titleView;
    self.searchInProgress = NO;
    self.tagCounts = [NSMutableDictionary dictionary];
    self.sectionTitles = [NSMutableDictionary dictionary];
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    
    self.tableView.opaque = NO;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.sectionIndexBackgroundColor = [UIColor whiteColor];
    self.tableView.sectionIndexTrackingBackgroundColor = HEX(0xDDDDDDFF);
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];

    self.filteredTags = [NSMutableArray array];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
    self.searchBar.delegate = self;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tagUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateTagsAndCounts) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.tagUpdateTimer invalidate];
    self.tagUpdateTimer = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    MixpanelProxy *mixpanel = [MixpanelProxy sharedInstance];
    [mixpanel track:@"Opened tags"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return 0;
        }
        else {
            NSString *key = [self sortedSectionTitles:self.sectionTitles][section];
            return [(NSMutableArray *)self.sectionTitles[key] count];
        }
    }
    else {
        if (section == 0) {
            return [self.filteredTags count];
        }
        else {
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return [self.sectionTitles count];
    }
    else {
        return 1;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([self.searchDisplayController isActive]) {
        return nil;
    }
    else {
        return [self sortedSectionTitles:self.sectionTitles];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == self.tableView) {
        if (title == UITableViewIndexSearch) {
            [tableView scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth(self.searchBar.frame), CGRectGetHeight(self.searchBar.frame)) animated:YES];
            return -1;
        }
        return index;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchDisplayController.active && section > 0) {
        return [self sortedSectionTitles:self.sectionTitles][section];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString *tag;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        tag = self.filteredTags[indexPath.row];
    }
    else {
        tag = [self tagForIndexPath:indexPath];
    }

    cell.textLabel.text = tag;
    cell.textLabel.font = [PPTheme textLabelFont];

    NSString *badgeCount = [NSString stringWithFormat:@"%@", self.tagCounts[tag]];
    cell.detailTextLabel.text = badgeCount;
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    return cell;
}

#pragma mark - UISearchDisplayController

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

#pragma mark - UISearchBar

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!self.searchInProgress) {
        self.searchInProgress = YES;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *result = [db executeQuery:@"SELECT name, count FROM tag WHERE name in (SELECT tag_fts.name FROM tag_fts WHERE tag_fts.name MATCH ?) ORDER BY count DESC" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];
            
            NSMutableArray *newTagNames = [NSMutableArray array];
            NSMutableArray *oldTagNames = [NSMutableArray array];
            
            NSMutableArray *indexPathsToRemove = [NSMutableArray array];
            NSMutableArray *indexPathsToAdd = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            NSMutableArray *newTags = [NSMutableArray array];
            NSInteger index = 0;
            
            for (NSDictionary *tag in self.filteredTags) {
                [oldTagNames addObject:tag];
            }
            
            while ([result next]) {
                NSString *tagName = [result stringForColumn:@"name"];
                
                if (tagName) {
                    [newTagNames addObject:tagName];

                    if (![oldTagNames containsObject:tagName]) {
                        [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                    }
                    index++;
                }
            }
            [db close];
            
            NSInteger i;
            for (i=0; i<oldTagNames.count; i++) {
                if (![newTagNames containsObject:oldTagNames[i]]) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.filteredTags = newTags;
                [self.searchDisplayController.searchResultsTableView beginUpdates];
                [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.searchDisplayController.searchResultsTableView endUpdates];
                self.searchInProgress = NO;
            });
        });
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    
    self.deleteConfirmationAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                  message:@"Are you sure you want to delete this tag? There is no undo."
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                        otherButtonTitles:@"Delete", nil];

    [self.deleteConfirmationAlertView show];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tag;
    if (tableView == self.tableView) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = [self tagForIndexPath:indexPath];
    }
    else {
        [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.filteredTags[indexPath.row];
    }
    
    [self.navigationController.navigationBar setBarTintColor:HEX(0x0096FFFF)];

    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    
#ifdef DELICIOUS
    DeliciousDataSource *deliciousDataSource = [[DeliciousDataSource alloc] init];
    deliciousDataSource.tags = @[tag];
    postViewController.postDataSource = deliciousDataSource;
#endif
    
#ifdef PINBOARD
    PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
    pinboardDataSource.tags = @[tag];
    postViewController.postDataSource = pinboardDataSource;
#endif

    // We need to switch this based on whether the user is on an iPad, due to the split view controller.
    if ([UIApplication isIPad]) {
        UINavigationController *navigationController = [AppDelegate sharedDelegate].navigationController;
        if (navigationController.viewControllers.count == 1) {
            UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
            if (showPopoverBarButtonItem) {
                postViewController.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
            }
        }
        
        [navigationController setViewControllers:@[postViewController] animated:YES];
        
        UIPopoverController *popover = [AppDelegate sharedDelegate].feedListViewController.popover;
        if (popover) {
            [popover dismissPopoverAnimated:YES];
        }
    }
    else {
        [self.navigationController pushViewController:postViewController animated:YES];
    }
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)titleForSectionIndex:(NSInteger)section {
    return [self tableView:self.tableView titleForHeaderInSection:section];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.deleteConfirmationAlertView) {
        ASPinboard *pinboard = [ASPinboard sharedInstance];
        NSString *tag = [self tagForIndexPath:self.selectedIndexPath];
        [pinboard deleteTag:tag
                    success:^{
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                            [db open];
                            // Delete the tag from the database.
                            
                            [db executeUpdate:@"DELETE FROM tags WHERE name=?" withArgumentsInArray:@[tag]];
                            [db executeUpdate:@"DELETE FROM tagging WHERE tag_name=?" withArgumentsInArray:@[tag]];
                            [db close];
                        });
                    }];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.tagActionSheet) {
        NSString *title = [self.tagActionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Delete"]) {
            NSString *tagName = [self tagForIndexPath:self.selectedIndexPath];
            self.deleteConfirmationAlertView = [[UIAlertView alloc] initWithTitle:tagName
                                                                          message:@"Are you sure you want to delete this tag? There is no undo."
                                                                         delegate:self
                                                                cancelButtonTitle:@"Cancel"
                                                                otherButtonTitles:@"Delete", nil];
            [self.deleteConfirmationAlertView show];
        }
    }
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        if (self.longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            CGPoint point = [self.longPressGestureRecognizer locationInView:self.tableView];
            self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:point];
            NSString *tagName = [self tagForIndexPath:self.selectedIndexPath];
            self.tagActionSheet = [[UIActionSheet alloc] initWithTitle:tagName
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:@"Delete"
                                                     otherButtonTitles:@"Rename", nil];
            [self.tagActionSheet showInView:self.tableView];
        }
    }
}

- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath {
    return self.sectionTitles[[self titleForSectionIndex:indexPath.section]][indexPath.row];
}

- (void)updateTagsAndCounts {
    NSArray *letters = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    NSMutableDictionary *updatedSectionTitles = [NSMutableDictionary dictionary];
    NSMutableDictionary *updatedTagCounts = [NSMutableDictionary dictionary];

    FMResultSet *results = [db executeQuery:@"SELECT name, count FROM tag ORDER BY name ASC"];
    while ([results next]) {
        NSString *name = [results stringForColumnIndex:0];
        NSMutableString *lossyName = [name mutableCopy];
        CFStringTransform((__bridge  CFMutableStringRef)lossyName, NULL, kCFStringTransformStripCombiningMarks, NO);
        NSString *count = [results stringForColumnIndex:1];
        
        if ([name length] == 0) {
            continue;
        }
        
        if ([count length] == 0) {
            continue;
        }

        NSString *firstLetter = [[lossyName substringToIndex:1] uppercaseString];
        if (![letters containsObject:firstLetter]) {
            firstLetter = @"#";
        }
        
        NSMutableArray *temp = updatedSectionTitles[firstLetter];
        if (!temp) {
            temp = [NSMutableArray array];
        }

        updatedTagCounts[name] = count;

        [temp addObject:name];
        updatedSectionTitles[firstLetter] = temp;
    }
    
    // Handle section additions / removals
    NSArray *previousSortedTitles = [self sortedSectionTitles:self.sectionTitles];
    NSArray *updatedSortedTitles = [self sortedSectionTitles:updatedSectionTitles];

    NSMutableSet *A = [NSMutableSet setWithArray:previousSortedTitles];
    NSMutableSet *B = [NSMutableSet setWithArray:updatedSortedTitles];
    
    NSMutableSet *deletedSectionTitles = [NSMutableSet setWithSet:A];
    [deletedSectionTitles minusSet:B];
    
    NSMutableSet *insertedSectionTitles = [NSMutableSet setWithSet:B];
    [insertedSectionTitles minusSet:A];
    
    NSMutableIndexSet *sectionIndicesToDelete = [NSMutableIndexSet indexSet];
    for (NSString *title in deletedSectionTitles) {
        [sectionIndicesToDelete addIndex:[previousSortedTitles indexOfObject:title]];
    }
    
    NSMutableIndexSet *sectionIndicesToInsert = [NSMutableIndexSet indexSet];
    for (NSString *title in insertedSectionTitles) {
        [sectionIndicesToInsert addIndex:[updatedSortedTitles indexOfObject:title]];
    }
    
    // Get sections that are in both A & B.
    NSMutableSet *reloadedSectionTitles = [NSMutableSet setWithSet:A];
    [A intersectSet:B];
    
    // Now we handle the changes for the index paths
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];

    NSInteger section = 0;
    for (NSString *title in reloadedSectionTitles) {
        NSArray *previousTags = self.sectionTitles[title];
        NSArray *updatedTags = updatedSectionTitles[title];
        NSMutableSet *Atags = [NSMutableSet setWithArray:previousTags];
        NSMutableSet *Btags = [NSMutableSet setWithArray:updatedTags];
        
        NSMutableSet *deletedTags = [NSMutableSet setWithSet:Atags];
        [deletedTags minusSet:Btags];
        
        NSMutableSet *insertedTags = [NSMutableSet setWithSet:Btags];
        [insertedTags minusSet:Atags];

        for (NSString *tag in deletedTags) {
            NSInteger row = [previousTags indexOfObject:tag];
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
        
        for (NSString *tag in insertedTags) {
            NSInteger row = [updatedTags indexOfObject:tag];
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
        
        // Get sections that are in both A & B.
        NSMutableSet *reloadedTags = [NSMutableSet setWithSet:Atags];
        [Atags intersectSet:Btags];
        
        for (NSString *tag in reloadedTags) {
            if (![self.tagCounts[tag] isEqualToString:updatedTagCounts[tag]]) {
                NSInteger row = [previousTags indexOfObject:tag];
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }

        section++;
    }
    
    self.sectionTitles = updatedSectionTitles;
    self.tagCounts = updatedTagCounts;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView deleteSections:sectionIndicesToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertSections:sectionIndicesToInsert withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (NSArray *)sortedSectionTitles:(NSDictionary *)sectionTitles {
    return [[sectionTitles allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

@end

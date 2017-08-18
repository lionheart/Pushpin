//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

@import QuartzCore;
@import Mixpanel;
@import LHSCategoryCollection;
@import LHSTableViewCells;
@import MWFeedParser;

#import "PPTagViewController.h"
#import "PPGenericPostViewController.h"
#import "PPPinboardDataSource.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "PPTableViewTitleView.h"
#import "PPFeedListViewController.h"
#import "PPUtilities.h"

static NSString *CellIdentifier = @"TagCell";

@interface PPTagViewController ()

@property (nonatomic) BOOL searchInProgress;
@property (nonatomic, strong) NSMutableDictionary *sectionTitles;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) UIAlertController *tagActionSheet;
@property (nonatomic, strong) UIAlertController *deleteConfirmationAlertView;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSTimer *tagUpdateTimer;
@property (nonatomic, strong) NSMutableDictionary *duplicates;
@property (nonatomic, strong) UIAlertController *selectTagToDeleteActionSheet;
@property (nonatomic, strong) NSString *tagToDelete;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) PPTableViewController *searchResultsController;

- (void)showSelectTagToDeleteActionSheet;
- (void)showDeleteConfirmationAlertView;
- (void)updateTagsAndCounts;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (NSString *)titleForSectionIndex:(NSInteger)section;
- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)sortedSectionTitles:(NSDictionary *)sectionTitles;

- (void)deleteTagWithName:(NSString *)name;

@end

@implementation PPTagViewController

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
    self.definesPresentationContext = YES;
    self.searchInProgress = NO;
    self.tagCounts = [NSMutableDictionary dictionary];
    self.sectionTitles = [NSMutableDictionary dictionary];
    self.duplicates = [NSMutableDictionary dictionary];
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    
    self.tableView.opaque = YES;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.sectionIndexBackgroundColor = [UIColor whiteColor];
    self.tableView.sectionIndexTrackingBackgroundColor = HEX(0xDDDDDDFF);
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self.navigationController action:@selector(popViewControllerAnimated:)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];

    self.filteredTags = [NSMutableArray array];

    self.searchResultsController = [[PPTableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.searchResultsController.tableView.delegate = self;
    self.searchResultsController.tableView.dataSource = self;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;

    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.searchBar.isAccessibilityElement = YES;
    self.searchController.searchBar.accessibilityLabel = NSLocalizedString(@"Search Bar", nil);
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
    self.searchController.searchBar.keyboardType = UIKeyboardTypeASCIICapable;

    self.tableView.tableHeaderView = self.searchController.searchBar;

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
    [self.searchResultsController.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateTagsAndCounts];
    self.tagUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(updateTagsAndCounts) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.tagUpdateTimer invalidate];
    self.tagUpdateTimer = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened tags"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        NSString *key = [self sortedSectionTitles:self.sectionTitles][section];
        return [(NSMutableArray *)self.sectionTitles[key] count];
    } else {
        return [self.filteredTags count];
    }
}

- (NSString *)titleForSectionIndex:(NSInteger)section {
    return [self tableView:self.tableView titleForHeaderInSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return [self.sectionTitles count];
    } else {
        return 1;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.searchController.active) {
        return nil;
    } else {
        return [self sortedSectionTitles:self.sectionTitles];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == self.tableView) {
        if (title == UITableViewIndexSearch) {
            [tableView scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth(self.searchController.searchBar.frame), CGRectGetHeight(self.searchController.searchBar.frame)) animated:YES];
            return -1;
        }
        return index;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchController.active) {
        return [self sortedSectionTitles:self.sectionTitles][section];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString *tag;
    if (tableView == self.searchResultsController.tableView) {
        tag = self.filteredTags[indexPath.row];
        cell.textLabel.text = tag;
        cell.textLabel.font = [PPTheme textLabelFont];
    } else {
        tag = [self tagForIndexPath:indexPath];

        NSArray *tags = self.duplicates[tag];
        if ([tags count] > 1) {
            NSString *tagsString = [tags componentsJoinedByString:@" · "];
            NSRange range = NSMakeRange([[tags firstObject] length] + 1, [tagsString length] - [[tags firstObject] length] - 1);
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:tagsString
                                                                                               attributes:@{NSForegroundColorAttributeName: [UIColor blackColor],
                                                                                                            NSFontAttributeName: [PPTheme textLabelFont] }];
            [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];
            cell.textLabel.attributedText = attributedText;
        } else {
            cell.textLabel.text = tag;
            cell.textLabel.font = [PPTheme textLabelFont];
        }
    }

    NSString *badgeCount = [NSString stringWithFormat:@"%@", self.tagCounts[tag]];
    cell.detailTextLabel.text = badgeCount;
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    return cell;
}

#pragma mark - UISearchBar

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    return YES;
}

#pragma mark - UISearchController

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    if (!self.searchInProgress) {
        self.searchInProgress = YES;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *newTagNames = [NSMutableArray array];
            NSMutableArray *oldTagNames = [NSMutableArray array];
            
            NSMutableArray *indexPathsToRemove = [NSMutableArray array];
            NSMutableArray *indexPathsToAdd = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            __block NSInteger index = 0;

            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *result = [db executeQuery:@"SELECT name, count FROM tag WHERE name in (SELECT tag_fts.name FROM tag_fts WHERE tag_fts.name MATCH ?) ORDER BY count DESC" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];
                
                for (NSDictionary *tag in self.filteredTags) {
                    [oldTagNames addObject:tag];
                }
                
                while ([result next]) {
                    NSString *tagName = [result stringForColumn:@"name"];
                    tagName = [tagName stringByDecodingHTMLEntities];
                    
                    if (tagName) {
                        [newTagNames addObject:tagName];
                        
                        if (![oldTagNames containsObject:tagName]) {
                            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                        }
                        index++;
                    }
                }
                
                [result close];
            }];
            
            NSInteger i;
            for (i=0; i<oldTagNames.count; i++) {
                if (![newTagNames containsObject:oldTagNames[i]]) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.filteredTags = newTagNames;
                [self.searchResultsController.tableView beginUpdates];
                [self.searchResultsController.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.searchResultsController.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.searchResultsController.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.searchResultsController.tableView endUpdates];
                self.searchInProgress = NO;
            });
        });
    }
}

#pragma mark - UITableViewDelegate

// Only let users delete tags with Pinboard (for now)

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tagToDelete = [self tagForIndexPath:indexPath];
    NSArray *duplicates = self.duplicates[self.tagToDelete];
    if ([duplicates count] > 1) {
        [self showSelectTagToDeleteActionSheet];
    } else {
        [self showDeleteConfirmationAlertView];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tag;
    if (tableView == self.tableView) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = [self tagForIndexPath:indexPath];
    } else {
        [self.searchResultsController.tableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.filteredTags[indexPath.row];
    }
    
    tag = [tag stringByEncodingHTMLEntities];

    [self.navigationController.navigationBar setBarTintColor:HEX(0x0096FFFF)];

    PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
    
    

    PPPinboardDataSource *pinboardDataSource = [[PPPinboardDataSource alloc] init];
    pinboardDataSource.tags = @[tag];
    postViewController.postDataSource = pinboardDataSource;

    // We need to switch this based on whether the user is on an iPad, due to the split view controller.
    if ([UIApplication isIPad]) {
        UINavigationController *navigationController = [PPAppDelegate sharedDelegate].navigationController;
        if (navigationController.viewControllers.count == 1) {
            UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
            if (showPopoverBarButtonItem) {
                postViewController.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
            }
        }
        
        [navigationController setViewControllers:@[postViewController] animated:YES];
        
        UIPopoverController *popover = [PPAppDelegate sharedDelegate].feedListViewController.popover;
        if (popover) {
            [popover dismissPopoverAnimated:YES];
        }
    } else {
        [self.navigationController pushViewController:postViewController animated:YES];
    }
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        if (self.longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            CGPoint point = [self.longPressGestureRecognizer locationInView:self.tableView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
            CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
            self.tagToDelete = [self tagForIndexPath:indexPath];
            
            NSArray *duplicates = self.duplicates[self.tagToDelete];
            if ([duplicates count] > 1) {
                [self showSelectTagToDeleteActionSheet];
            } else {
                self.tagActionSheet = [UIAlertController lhs_actionSheetWithTitle:self.tagToDelete];
                
                [self.tagActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *action) {
                                                        [self showDeleteConfirmationAlertView];
                                                    }];

                [self.tagActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil];
                
                self.tagActionSheet.popoverPresentationController.sourceView = self.tableView;
                self.tagActionSheet.popoverPresentationController.sourceRect = rect;
                [self presentViewController:self.tagActionSheet animated:YES completion:nil];
            }
        }
    }
}

- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath {
    return self.sectionTitles[[self titleForSectionIndex:indexPath.section]][indexPath.row];
}

- (void)updateTagsAndCounts {
    static dispatch_queue_t serialQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.lionheartsw.TagUpdateQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    if (!self.searchController.active) {
        dispatch_async(serialQueue, ^{
            NSArray *letters = [[UILocalizedIndexedCollation currentCollation] sectionTitles];

            NSMutableDictionary *updatedSectionTitles = [NSMutableDictionary dictionary];
            NSMutableDictionary *updatedTagCounts = [NSMutableDictionary dictionary];
            NSMutableDictionary *updatedDuplicates = [NSMutableDictionary dictionary];

            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:@"SELECT name, group_concat(name, ' '), SUM(count) FROM tag GROUP BY lower(name) ORDER BY lower(name) ASC"];
                while ([results next]) {
                    NSString *name = [results stringForColumnIndex:0];
                    name = [name stringByDecodingHTMLEntities];

                    NSArray *names = [[results stringForColumnIndex:1] componentsSeparatedByString:@" "];
                    NSString *count = [results stringForColumnIndex:2];
                    NSMutableString *lossyName = [name mutableCopy];
                    CFStringTransform((__bridge  CFMutableStringRef)lossyName, NULL, kCFStringTransformStripCombiningMarks, NO);
                    
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
                    
                    if ([names count] > 0) {
                        updatedDuplicates[name] = names;
                    }

                    updatedTagCounts[name] = count;
                    for (NSString *otherName in names) {
                        updatedTagCounts[[otherName stringByDecodingHTMLEntities]] = count;
                    }

                    [temp addObject:name];
                    updatedSectionTitles[firstLetter] = temp;
                }
                
                [results close];
            }];
            
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
            for (NSString *title in updatedSortedTitles) {
                if ([reloadedSectionTitles containsObject:title]) {
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
                    [reloadedTags intersectSet:Btags];
                    
                    for (NSString *tag in reloadedTags) {
                        if (![self.tagCounts[tag] isEqualToString:updatedTagCounts[tag]]) {
                            NSInteger row = [previousTags indexOfObject:tag];
                            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:section]];
                        }
                    }
                }
                
                section++;
            }
            
            BOOL firstLaunch = self.tagCounts.count == 0;
            if (firstLaunch || indexPathsToDelete.count > 0 || indexPathsToInsert.count > 0 || indexPathsToReload.count > 0 || sectionIndicesToDelete.count > 0 || sectionIndicesToInsert.count > 0) {
                // We have the semaroid
                dispatch_semaphore_t sem = dispatch_semaphore_create(0);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.sectionTitles = updatedSectionTitles;
                    self.tagCounts = updatedTagCounts;
                    self.duplicates = updatedDuplicates;

                    if (firstLaunch) {
                        [self.tableView reloadData];
                    } else {
                        [self.tableView beginUpdates];
                        [self.tableView deleteSections:sectionIndicesToDelete withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertSections:sectionIndicesToInsert withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    }
                    dispatch_semaphore_signal(sem);
                });

                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            }
        });
    }
}

- (NSArray *)sortedSectionTitles:(NSDictionary *)sectionTitles {
    return [[sectionTitles allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)deleteTagWithName:(NSString *)name {
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard deleteTag:name
                success:^{
                        // Delete the tag from the database.

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                            [db executeUpdate:@"DELETE FROM tag WHERE name=?" withArgumentsInArray:@[name]];
                            
                            NSMutableArray *hashesToUpdate = [NSMutableArray array];
                            NSMutableArray *parameterPlaceholders = [NSMutableArray array];
                            FMResultSet *result = [db executeQuery:@"SELECT bookmark_hash FROM tagging WHERE tag_name=?" withArgumentsInArray:@[name]];
                            while ([result next]) {
                                // Convert the tags to a list, remove the removed tag, and then update the bookmark.
                                NSString *hash = [result stringForColumnIndex:0];
                                [hashesToUpdate addObject:hash];
                                [parameterPlaceholders addObject:@"?"];
                            }

                            [result close];
                            
                            [db executeUpdate:@"DELETE FROM tagging WHERE tag_name=?" withArgumentsInArray:@[name]];
                            
                            NSString *query = [NSString stringWithFormat:@"UPDATE bookmark SET tags=(SELECT (group_concat(tag_name, ' ') || '') FROM tagging WHERE bookmark_hash=bookmark.hash) WHERE hash IN (%@)", [parameterPlaceholders componentsJoinedByString:@", "]];
                            [db executeUpdate:query withArgumentsInArray:hashesToUpdate];
                        }];
                        
                        [self.tagCounts removeObjectForKey:name];
                        self.tagToDelete = nil;
                    });
                }];
}

- (void)showDeleteConfirmationAlertView {
    self.deleteConfirmationAlertView = [UIAlertController lhs_alertViewWithTitle:self.tagToDelete
                                                                         message:NSLocalizedString(@"Are you sure you want to delete this tag? There is no undo.", nil)];

    [self.deleteConfirmationAlertView lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
                                                         [self deleteTagWithName:self.tagToDelete];
                                                     }];
    
    [self.deleteConfirmationAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    
    [self presentViewController:self.deleteConfirmationAlertView animated:YES completion:nil];
}

- (void)showSelectTagToDeleteActionSheet {
    NSArray *duplicates = self.duplicates[self.tagToDelete];
    self.selectTagToDeleteActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"This tag has a few versions. Select the one you'd like to delete.", nil)];

    for (NSString *duplicate in duplicates) {
        [self.selectTagToDeleteActionSheet lhs_addActionWithTitle:duplicate
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              self.tagToDelete = action.title;
                                                              [self showDeleteConfirmationAlertView];
                                                          }];
    }
    
    [self.selectTagToDeleteActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];
    
    self.selectTagToDeleteActionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:self.selectTagToDeleteActionSheet animated:YES completion:nil];
}

@end

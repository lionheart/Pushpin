//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

#import <QuartzCore/QuartzCore.h>

#import "TagViewController.h"
#import "FMDatabase.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "UITableViewCellValue1.h"
#import "PPTableViewTitleView.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"TagCell";

@interface TagViewController ()

@property (nonatomic) BOOL searchInProgress;

- (NSString *)titleForSectionIndex:(NSInteger)section;

@end

@implementation TagViewController

@synthesize searchDisplayController = __searchDisplayController;
@synthesize searchBar = _searchBar;

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

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
    
    self.tableView.opaque = NO;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.sectionIndexBackgroundColor = [UIColor whiteColor];
    self.tableView.sectionIndexTrackingBackgroundColor = HEX(0xDDDDDDFF);
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];

    NSArray *letters = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    self.titleToTags = [NSMutableDictionary dictionary];

    FMResultSet *results = [db executeQuery:@"SELECT name, count FROM tag ORDER BY name ASC"];
    NSString *name, *count;
    while ([results next]) {
        name = [results stringForColumnIndex:0];
        count = [results stringForColumnIndex:1];
        if (!name || name.length == 0) {
            continue;
        }

        if (!count || count.length == 0) {
            continue;
        }

        NSString *firstLetter = [[name substringToIndex:1] uppercaseString];
        if (![letters containsObject:firstLetter]) {
            firstLetter = @"#";
        }

        NSMutableArray *temp = [self.titleToTags objectForKey:firstLetter];
        if (!temp) {
            temp = [NSMutableArray array];
        }

        [temp addObject:@{@"name": name, @"count": [results stringForColumn:@"count"]}];
        [self.titleToTags setObject:temp forKey:firstLetter];
    }

    NSArray *newSortedTitles = [[self.titleToTags allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableArray *newSortedTitlesWithSearch = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
    for (NSString *title in newSortedTitles) {
        [newSortedTitlesWithSearch addObject:title];
    }

    self.sortedTitles = newSortedTitlesWithSearch;
    self.filteredTags = [NSMutableArray array];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchBar.barTintColor = HEX(0x0096FFFF);

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened tags"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return 0;
        }
        else {
            NSString *key = self.sortedTitles[section];
            return [(NSMutableArray *)self.titleToTags[key] count];
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
        return [self.sortedTitles count];
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
        return self.sortedTitles;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchDisplayController.active && section > 0) {
        return [PPTableViewTitleView heightWithText:self.sortedTitles[section]];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchDisplayController.active && section > 0) {
        return [PPTableViewTitleView headerWithText:self.sortedTitles[section]];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSDictionary *tag;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        tag = self.filteredTags[indexPath.row];
    }
    else {
        tag = self.titleToTags[[self titleForSectionIndex:indexPath.section]][indexPath.row];
    }

    cell.textLabel.text = tag[@"name"];
    cell.textLabel.font = [PPTheme cellTextLabelFont];

    NSString *badgeCount = [NSString stringWithFormat:@"%@", tag[@"count"]];
    cell.detailTextLabel.text = badgeCount;
    cell.detailTextLabel.font = [PPTheme cellDetailLabelFont];
    return cell;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

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
                [oldTagNames addObject:tag[@"name"]];
            }
            
            while ([result next]) {
                NSString *tagName = [result stringForColumn:@"name"];
                NSString *tagCount = [result stringForColumn:@"count"];
                
                if (tagName && tagCount) {
                    [newTags addObject:@{
                                         @"name": tagName,
                                         @"count": tagCount }];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *tag;
    if (tableView == self.tableView) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.titleToTags[[self titleForSectionIndex:indexPath.section]][indexPath.row];
    }
    else {
        [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.filteredTags[indexPath.row];
    }
    
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
    pinboardDataSource.tags = @[tag[@"name"]];
    postViewController.postDataSource = pinboardDataSource;
    [self.navigationController pushViewController:postViewController animated:YES];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)titleForSectionIndex:(NSInteger)section {
    PPTableViewTitleView *titleView = (PPTableViewTitleView *)[self tableView:self.tableView viewForHeaderInSection:section];
    return titleView.text;
}

@end

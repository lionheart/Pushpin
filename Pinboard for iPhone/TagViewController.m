//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

#import "TagViewController.h"
#import "ASManagedObject.h"
#import "Tag.h"
#import "BookmarkViewController.h"

@interface TagViewController ()

@end

@implementation TagViewController

@synthesize titleToTags;
@synthesize alphabet;
@synthesize tagList;
@synthesize sortedTitles;
@synthesize searchDisplayController;
@synthesize searchBar = _searchBar;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    self.titleToTags = [NSMutableDictionary dictionary];
    self.tagList = [NSMutableArray array];

    self.titleToTags = [@{@"#": [NSMutableArray array], @"A": [NSMutableArray array], @"B": [NSMutableArray array], @"C": [NSMutableArray array], @"D": [NSMutableArray array], @"E": [NSMutableArray array], @"F": [NSMutableArray array], @"G": [NSMutableArray array], @"H": [NSMutableArray array], @"I": [NSMutableArray array], @"J": [NSMutableArray array], @"K": [NSMutableArray array], @"L": [NSMutableArray array], @"M": [NSMutableArray array], @"N": [NSMutableArray array], @"O": [NSMutableArray array], @"P": [NSMutableArray array], @"Q": [NSMutableArray array], @"R": [NSMutableArray array], @"S": [NSMutableArray array], @"T": [NSMutableArray array], @"U": [NSMutableArray array], @"V": [NSMutableArray array], @"W": [NSMutableArray array], @"X": [NSMutableArray array], @"Y": [NSMutableArray array], @"Z": [NSMutableArray array]} mutableCopy];

    for (Tag *tag in results) {
        if (!tag.name) {
            continue;
        }
        NSString *firstLetter = [[tag.name substringToIndex:1] uppercaseString];
        if (![self.titleToTags objectForKey:firstLetter]) {
            firstLetter = @"#";
        }
        
        NSLog(@"%@", firstLetter);

        NSMutableArray *temp = [self.titleToTags objectForKey:firstLetter];
        [temp addObject:tag];
        [self.tagList addObject:tag];
        [self.titleToTags setObject:temp forKey:firstLetter];
    }

    self.sortedTitles = @[UITableViewIndexSearch, @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return 0;
        }
        else {
            NSString *key = [self.sortedTitles objectAtIndex:section];
            return [(NSMutableArray *)[self.titleToTags objectForKey:key] count];
        }
    }
    else {
        return 1;
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    }
    else {
        return self.sortedTitles;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (title == UITableViewIndexSearch) {
        [tableView scrollRectToVisible:CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.height) animated:YES];
        return -1;
    }
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return nil;
        }
        return [self.sortedTitles objectAtIndex:section];
    }
    else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TagCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }

    Tag *tag = [[self.titleToTags objectForKey:[self tableView:tableView titleForHeaderInSection:indexPath.section]] objectAtIndex:indexPath.row];
    cell.textLabel.text = tag.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", tag.bookmarks.count];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    Tag *tag = [[self.titleToTags objectForKey:[self tableView:tableView titleForHeaderInSection:indexPath.section]] objectAtIndex:indexPath.row];
    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"ANY tags.name = %@", tag.name]];
    bookmarkViewController.title = tag.name;
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
}

@end

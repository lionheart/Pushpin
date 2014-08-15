//
//  LHFontSelectionViewController.m
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import "LHSFontSelectionViewController.h"
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <LHSCategoryCollection/UIFont+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";

@interface LHSFontSelectionViewController ()

@end

@implementation LHSFontSelectionViewController

- (instancetype)initWithPreferredFontNames:(NSArray *)fontNames onlyShowPreferredFonts:(BOOL)onlyShowPreferredFonts {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.preferredFontNames = [fontNames mutableCopy];
        [self.preferredFontNames sortUsingSelector:@selector(compare:)];
        self.onlyShowPreferredFonts = onlyShowPreferredFonts;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Font";
    self.currentFontName = [self.delegate fontNameForFontSelectionViewController:self];
    
    self.fonts = [NSMutableArray array];
    self.fontsForSectionIndex = [NSMutableDictionary dictionary];
    self.sectionIndexTitles = [NSMutableArray array];
    
    if (self.onlyShowPreferredFonts) {
        
    }
    else {
        for (NSString *familyName in [UIFont familyNames]) {
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                [self.fonts addObject:fontName];
                
                NSString *firstCharacter = [fontName substringToIndex:1];
                if (![self.sectionIndexTitles containsObject:firstCharacter]) {
                    [self.sectionIndexTitles addObject:firstCharacter];
                    self.fontsForSectionIndex[firstCharacter] = [NSMutableArray arrayWithObject:fontName];
                }
                else {
                    [self.fontsForSectionIndex[firstCharacter] addObject:fontName];
                }
            }
        }
        
        [self.sectionIndexTitles sortUsingSelector:@selector(compare:)];
        [self.fonts sortUsingSelector:@selector(compare:)];
        
        if (self.preferredFontNames.count > 0) {
            [self.sectionIndexTitles insertObject:@"-" atIndex:0];
            self.fontsForSectionIndex[@"-"] = self.preferredFontNames;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *indexPathForCurrentlySelectedFont = [self indexPathsForFontName:self.currentFontName];
    [self.tableView scrollToRowAtIndexPath:[indexPathForCurrentlySelectedFont firstObject]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return 1;
    }
    else {
        return self.sectionIndexTitles.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.onlyShowPreferredFonts) {
        return self.preferredFontNames.count;
    }
    else {
        NSString *sectionName = self.sectionIndexTitles[section];
        return [self.fontsForSectionIndex[sectionName] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.preferredFontNames.count > 0 && section == 0) {
        return nil;
    }
    return self.sectionIndexTitles[section];
    
    if (self.onlyShowPreferredFonts) {
        return nil;
    }
    else {
        if (self.preferredFontNames.count > 0 && section == 0) {
            return nil;
        }
        else {
            return self.sectionIndexTitles[section];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.textLabel.font = nil;
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = nil;
    
    NSString *fontName;
    if (self.onlyShowPreferredFonts) {
        fontName = self.preferredFontNames[indexPath.row];
    }
    else {
        NSString *sectionName = self.sectionIndexTitles[indexPath.section];
        fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
    }
    
    UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
    cell.textLabel.text = font.displayName;
    cell.textLabel.font = font;
    if ([fontName isEqualToString:self.currentFontName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return nil;
    }
    else {
        return self.sectionIndexTitles;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *indexPathsForPreviouslySelectedFont = [self indexPathsForFontName:self.currentFontName];
    
    NSString *fontName;
    if (self.onlyShowPreferredFonts) {
        fontName = self.preferredFontNames[indexPath.row];
    }
    else {
        NSString *sectionName = self.sectionIndexTitles[indexPath.section];
        fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
    }
    
    if (![fontName isEqualToString:self.currentFontName]) {
        self.currentFontName = fontName;
        [self.delegate setFontName:fontName forFontSelectionViewController:self];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[indexPathsForPreviouslySelectedFont arrayByAddingObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

#pragma mark - Utils

- (NSArray *)indexPathsForFontName:(NSString *)fontName {
    NSInteger row;
    NSInteger section;
    NSMutableArray *indexPaths = [NSMutableArray array];

    if (self.onlyShowPreferredFonts) {
        if ([self.preferredFontNames containsObject:fontName]) {
            row = [self.preferredFontNames indexOfObject:fontName];
            section = 0;
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    else {
        if (self.preferredFontNames.count > 0) {
            if ([self.preferredFontNames containsObject:fontName]) {
                row = [self.preferredFontNames indexOfObject:fontName];
                section = 0;
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }

        NSString *firstCharacter = [fontName substringToIndex:1];
        section = [self.sectionIndexTitles indexOfObject:firstCharacter];
        row = [self.fontsForSectionIndex[firstCharacter] indexOfObject:fontName];
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
    }
    
    return [indexPaths copy];
}
@end

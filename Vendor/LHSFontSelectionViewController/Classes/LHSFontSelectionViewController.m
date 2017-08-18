//
//  LHFontSelectionViewController.m
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

@import LHSTableViewCells;
@import LHSCategoryCollection;
@import YHRoundBorderedButton;

#import "PPAppDelegate.h"
#import "PPSettings.h"
#import "LHSFontSelectionViewController.h"

#import "UIAlertController+LHSAdditions.h"

static NSString *CellIdentifier = @"Cell";

@interface LHSFontSelectionViewController ()

- (NSAttributedString *)attributedFontNameString;

@end

@implementation LHSFontSelectionViewController

- (instancetype)initWithPreferredFontNames:(NSArray *)fontNames onlyShowPreferredFonts:(BOOL)onlyShowPreferredFonts {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.preferredFontNames = [fontNames mutableCopy];
        [self.preferredFontNames sortUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return [[LHSFontSelectionViewController fontNameToDisplayName:obj1] compare:[LHSFontSelectionViewController fontNameToDisplayName:obj2]];
        }];
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

    if (!self.onlyShowPreferredFonts) {
        NSSet *preferredFontSet = [NSSet setWithArray:self.preferredFontNames];

        for (NSString *familyName in [UIFont familyNames]) {
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                if (![preferredFontSet containsObject:fontName]) {
                    [self.fonts addObject:fontName];

                    NSString *firstCharacter = [fontName substringToIndex:1];
                    if (![self.sectionIndexTitles containsObject:firstCharacter]) {
                        [self.sectionIndexTitles addObject:firstCharacter];
                        self.fontsForSectionIndex[firstCharacter] = [NSMutableArray arrayWithObject:fontName];
                    } else {
                        [self.fontsForSectionIndex[firstCharacter] addObject:fontName];
                    }
                }
            }
        }
        
        [self.sectionIndexTitles sortUsingSelector:@selector(compare:)];
        for (NSString *sectionIndexTitle in self.sectionIndexTitles) {
            [self.fontsForSectionIndex[sectionIndexTitle] sortUsingSelector:@selector(compare:)];
        }
        [self.fonts sortUsingSelector:@selector(compare:)];
        
        if (self.preferredFontNames.count > 0) {
            [self.sectionIndexTitles insertObject:@"-" atIndex:0];
            self.fontsForSectionIndex[@"-"] = self.preferredFontNames;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView
                                             selector:@selector(reloadData)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    delegate.hideURLPrompt = YES;
    
    [self setNeedsStatusBarAppearanceUpdate];
    NSArray *indexPathForCurrentlySelectedFont = [self indexPathsForFontName:self.currentFontName];
    
    if (self.preferredFontNames.count == 0) {
        [self.tableView scrollToRowAtIndexPath:[indexPathForCurrentlySelectedFont firstObject]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    delegate.hideURLPrompt = NO;

    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return 1;
    } else {
        return self.sectionIndexTitles.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.onlyShowPreferredFonts) {
        return self.preferredFontNames.count;
    } else {
        NSString *sectionName = self.sectionIndexTitles[section];
        return [self.fontsForSectionIndex[sectionName] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.preferredFontNames.count > 0 && section == 0) {
        return NSLocalizedString(@"Recommended Fonts", nil);
    }
    return self.sectionIndexTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.font = nil;
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = nil;
    [cell.contentView lhs_removeSubviews];
    
    NSString *fontName;
    if (self.onlyShowPreferredFonts) {
        fontName = self.preferredFontNames[indexPath.row];
    } else {
        NSString *sectionName = self.sectionIndexTitles[indexPath.section];
        fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
    }

    UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self]];

    NSString *fontDisplayName;
    if ([fontName hasPrefix:@"."]) {
        fontDisplayName = [LHSFontSelectionViewController fontNameToDisplayName:fontName];
    } else {
        fontDisplayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
    }

    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = fontDisplayName;
    cell.textLabel.font = font;

    if ([fontName isEqualToString:self.currentFontName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return nil;
    } else {
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
    } else {
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
    } else {
        if (self.preferredFontNames.count > 0) {
            if ([self.preferredFontNames containsObject:fontName]) {
                row = [self.preferredFontNames indexOfObject:fontName];
                section = 0;
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
        
        if (![self.preferredFontNames containsObject:fontName]) {
            NSString *firstCharacter = [fontName substringToIndex:1];
            section = [self.sectionIndexTitles indexOfObject:firstCharacter];
            row = [self.fontsForSectionIndex[firstCharacter] indexOfObject:fontName];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    return [indexPaths copy];
}

- (NSAttributedString *)attributedFontNameString {
    static NSMutableAttributedString *string;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRange range = NSMakeRange(0, 0);
        NSMutableArray *fontNames = [NSMutableArray array];
        for (NSString *fontName in self.preferredFontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
            NSString *displayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
            [fontNames addObject:displayName];
        }

        string = [[NSMutableAttributedString alloc] initWithString:[fontNames componentsJoinedByString:@", "]];
        
        for (NSString *fontName in self.preferredFontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
            NSString *displayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
            range.length = displayName.length;
            [string addAttribute:NSFontAttributeName value:font range:range];
            range.location += displayName.length + 2;
        }
    });
    
    return string;
}

+ (NSString *)fontNameToDisplayName:(NSString *)fontName {
    if ([fontName isEqualToString:@"Lyon Text App Regular"]) {
        fontName = @"Lyon";
    }
    else if ([fontName isEqualToString:@"Avenir Next Regular"]) {
        fontName = @"Avenir Next";
    }
    else if ([fontName isEqualToString:@"Arial MT"]) {
        fontName = @"Arial";
    }
    else if ([fontName isEqualToString:@"Futura Medium"]) {
        fontName = @"Futura";
    }
    else if ([fontName isEqualToString:@"Flex Regular"]) {
        fontName = @"Flex";
    }
    else if ([fontName isEqualToString:@"Brando Regular"]) {
        fontName = @"Brando";
    } else if ([fontName isEqualToString:[UIFont systemFontOfSize:10].fontName]) {
        fontName = @"San Francisco";
    } else if ([fontName isEqualToString:[UIFont boldSystemFontOfSize:10].fontName]) {
        fontName = @"San Francisco Bold";
    }
    return fontName;
}


#pragma mark - Utils

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

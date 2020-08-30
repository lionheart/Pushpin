//
//  PPTagEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import LHSCategoryCollection;
@import ASPinboard;
@import FMDB;
@import LHSKeyboardAdjusting;
@import LHSTableViewCells;

#import "PPAppDelegate.h"
#import "PPTagEditViewController.h"
#import "PPTableViewTitleView.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "PPSettings.h"
#import "PPUtilities.h"

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPTagEditViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;
@property (nonatomic, strong) UIKeyCommand *goBackKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

- (NSArray *)indexPathsForPopularAndSuggestedRows;
- (NSArray *)indexPathsForAutocompletedRows;
- (NSArray *)indexPathsForExistingRows;
- (NSArray *)indexPathsForArray:(NSArray *)array offset:(NSInteger)offset;
- (void)deleteTagButtonTouchUpInside:(id)sender;
- (void)deleteTagWithName:(NSString *)name;
- (void)deleteTagWithName:(NSString *)name animation:(UITableViewRowAnimation)animation;
- (NSInteger)tagOffset;
- (void)intersectionBetweenStartingAmount:(NSInteger)start andFinalAmount:(NSInteger)final offset:(NSInteger)offset callback:(void (^)(NSArray *, NSArray *, NSArray *))callback;

- (void)rightBarButtonItemTouchUpInside:(id)sender;

- (NSArray *)filteredPopularAndRecommendedTags;
- (BOOL)filteredPopularAndRecommendedTagsVisible;

- (void)searchUpdatedWithString:(NSString *)string;
- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags;

@end

@implementation PPTagEditViewController

#pragma mark - UIViewController

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.tagTextField becomeFirstResponder];
    [self lhs_activateKeyboardAdjustmentWithShow:nil hide:^{
        self.autocompleteInProgress = NO;
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self lhs_deactivateKeyboardAdjustment];
    [self.tagDelegate tagEditViewControllerDidUpdateTags:self];
}

- (void)viewDidLayoutSubviews {
    NSDictionary *views = @{@"view": self.tableView,
                            @"guide": self.topLayoutGuide };
    [self.view lhs_addConstraints:@"V:[guide][view]" views:views];
    [self.view lhs_addConstraints:@"H:|[view]|" views:views];
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Edit Tags", nil);

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.autocompleteInProgress = NO;
    self.unfilteredPopularTags = [NSMutableArray array];
    self.unfilteredRecommendedTags = [NSMutableArray array];
    self.popularTags = [NSMutableArray array];
    self.recommendedTags = [NSMutableArray array];
    self.tagDescriptions = [NSMutableDictionary dictionary];
    self.tagCounts = [NSMutableDictionary dictionary];
    self.deleteTagButtons = [NSMutableDictionary dictionary];
    self.tagCompletions = [NSMutableArray array];
    self.loadingTags = NO;
    self.previousTagSuggestions = [NSMutableArray array];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
    
    UIFont *font = [UIFont systemFontOfSize:16];
    self.tagTextField = [[UITextField alloc] init];
    self.tagTextField.font = font;
    self.tagTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.tagTextField.userInteractionEnabled = YES;
    self.tagTextField.delegate = self;
    self.tagTextField.returnKeyType = UIReturnKeyDone;
    self.tagTextField.clearButtonMode = UITextFieldViewModeAlways;
    self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.tagTextField.placeholder = NSLocalizedString(@"Add new tags here.", nil);
    
    PPSettings *settings = [PPSettings sharedSettings];
    self.tagTextField.autocapitalizationType = settings.autoCapitalizationType;
    self.tagTextField.autocorrectionType = settings.autoCorrectionType;
    self.tagTextField.text = @"";
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.existingTags.count > 0 && [indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]]) {
        return 20 + [self.badgeWrapperView calculateHeightForWidth:(CGRectGetWidth(self.tableView.frame) - 20)];
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.contentView lhs_removeSubviews];
    cell.textLabel.text = @"";
    cell.textLabel.enabled = YES;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;

    if (indexPath.section == 0) {
        NSInteger index = indexPath.row - [self tagOffset];
        
        if (index >= 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            if (self.filteredPopularAndRecommendedTagsVisible) {
                cell.textLabel.text = self.filteredPopularAndRecommendedTags[index];
                cell.detailTextLabel.textColor = HEX(0x96989DFF);
                cell.detailTextLabel.text = self.tagDescriptions[cell.textLabel.text];
            } else if (self.tagCompletions.count > 0) {
                NSString *tag = self.tagCompletions[index];
                cell.textLabel.text = tag;
                cell.detailTextLabel.text = self.tagCounts[tag];
            }
        } else {
            // This is the tag entry row
            if (index == -1) {
                UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                topImageView.frame = CGRectMake(14, 12, 20, 20);
                [cell.contentView addSubview:topImageView];
                
                if (self.loadingTags) {
                    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                    [activity startAnimating];
                    cell.accessoryView = activity;
                    cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                    cell.textLabel.enabled = NO;
                }

                [cell.contentView addSubview:self.tagTextField];

                NSDictionary *views = @{@"view": self.tagTextField};
                [cell.contentView lhs_addConstraints:@"H:|-40-[view]-10-|" views:views];
                [cell.contentView lhs_addConstraints:@"V:|-10-[view]" views:views];
            } else {
                // If it's -2, it's the badge row
                [cell.contentView addSubview:self.badgeWrapperView];
                [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": self.badgeWrapperView}];
                [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:@{@"badges": self.badgeWrapperView}];
            }
        }
    } else {
        //This is because '&' was shown as '&amp;' int existingTags
        NSMutableArray *newArray = [NSMutableArray array];
        for (NSString *input in self.existingTags)
        {
            NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
                [newArray addObject:replacement];
        }
        self.existingTags = newArray;
        
        NSString *tag = self.existingTags[self.existingTags.count - indexPath.row - 1];
        cell.textLabel.text = tag;
        
        // We set this up as an image view so that the image can be centered in a large tap area.
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Delete-Button"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(deleteTagButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        [button addSubview:imageView];

        [button lhs_addConstraints:@"H:[imageView(23)]-15-|" views:NSDictionaryOfVariableBindings(imageView)];
        [button lhs_centerVerticallyForView:imageView height:23];
        self.deleteTagButtons[tag] = button;

        [cell.contentView addSubview:button];
        [cell lhs_addConstraints:@"H:[button(70)]|" views:NSDictionaryOfVariableBindings(button)];
        [cell lhs_addConstraints:@"V:|[button]|" views:NSDictionaryOfVariableBindings(button)];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.filteredPopularAndRecommendedTagsVisible) {
            return self.filteredPopularAndRecommendedTags.count + [self tagOffset];
        } else if (self.tagCompletions.count > 0) {
            return self.tagCompletions.count + [self tagOffset];
        } else {
            return [self tagOffset];
        }
    } else {
        return self.existingTags.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.existingTags.count == 0) {
        return 1;
    }
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Current Tags";
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    if (row >= [self tagOffset] && indexPath.section == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *completion;
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            
            // Add the row to the bookmark list below
            
            if (self.existingTags.count == 0) {
                [indexSetsToInsert addIndex:1];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            } else {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            
            NSInteger index = row - [self tagOffset];
            
            if (self.tagCompletions.count > 0) {
                completion = self.tagCompletions[index];
                [indexPathsToDelete addObjectsFromArray:[self indexPathsForAutocompletedRows]];
                [self.tagCompletions removeAllObjects];
                [self.existingTags addObject:completion];
            } else if (self.filteredPopularAndRecommendedTagsVisible) {
                completion = self.filteredPopularAndRecommendedTags[index];
                
                if (index < self.popularTags.count) {
                    completion = self.popularTags[index];

#warning http://crashes.to/s/4988f817e3d
                    [self.popularTags removeObjectAtIndex:index];
                } else {
                    completion = self.recommendedTags[index];
                    [self.recommendedTags removeObjectAtIndex:(index - self.popularTags.count)];
                }
                
                [self.existingTags addObject:completion];
                [indexPathsToDelete addObject:indexPath];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                self.tagTextField.text = @"";
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        });
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *invalidCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (string.length > 0) {
        NSRange range = [string rangeOfCharacterFromSet:invalidCharacterSet];
        BOOL containsInvalidCharacters = range.location != NSNotFound;
        if (containsInvalidCharacters) {
            [self textFieldShouldReturn:textField];
            return NO;
        }
    }
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (finalString.length == 0) {
        self.searchString = nil;
        NSInteger finalAmount;
        if (self.filteredPopularAndRecommendedTagsVisible) {
            finalAmount = self.filteredPopularAndRecommendedTags.count;
            self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Suggest", nil);
        } else {
            finalAmount = 0;
        }
        
        [self intersectionBetweenStartingAmount:self.tagCompletions.count
                                 andFinalAmount:finalAmount
                                         offset:[self tagOffset]
                                       callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                           [self.tagCompletions removeAllObjects];
                                           [self.popularTags removeAllObjects];
                                           [self.recommendedTags removeAllObjects];
                                           
                                           [self.tableView beginUpdates];
                                           [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
                                           [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                                           [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                                           [self.tableView endUpdates];
                                       }];
    } else {
        self.searchString = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:string];
        [self searchUpdatedWithString:self.searchString];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *tag = self.tagTextField.text;
    if (tag.length > 0) {
        if (![self.existingTags containsObject:tag]) {
            self.tagTextField.text = @"";
            
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
            
            if (self.existingTags.count == 0) {
                [indexSetsToInsert addIndex:1];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            } else {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            
            if (self.filteredPopularAndRecommendedTagsVisible) {
                [indexPathsToDelete addObjectsFromArray:[self indexPathsForPopularAndSuggestedRows]];
                [self.popularTags removeAllObjects];
                [self.recommendedTags removeAllObjects];
            } else {
                [indexPathsToDelete addObjectsFromArray:[self indexPathsForAutocompletedRows]];
                [self.tagCompletions removeAllObjects];
            }
            
            [self.existingTags addObject:tag];
            self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    NSArray *indexPathsToDelete;
    if (self.filteredPopularAndRecommendedTagsVisible) {
        indexPathsToDelete = [self indexPathsForPopularAndSuggestedRows];
        [self.popularTags removeAllObjects];
        [self.recommendedTags removeAllObjects];
    } else if (self.tagCompletions.count > 0) {
        indexPathsToDelete = [self indexPathsForAutocompletedRows];
        [self.tagCompletions removeAllObjects];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    return YES;
}

#pragma mark - Utils

- (void)intersectionBetweenStartingAmount:(NSInteger)start
                           andFinalAmount:(NSInteger)final
                                   offset:(NSInteger)offset
                                 callback:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    
    if (final >= start) {
        for (NSInteger i=0; i<start; i++) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
        
        for (NSInteger i=start; i<final; i++) {
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
    } else {
        for (NSInteger i=0; i<final; i++) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
        
        for (NSInteger i=final; i<start; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
        }
    }
    
    callback(indexPathsToInsert, indexPathsToReload, indexPathsToDelete);
}

- (NSArray *)filteredPopularAndRecommendedTags {
    return [self.popularTags arrayByAddingObjectsFromArray:self.recommendedTags];
}

- (BOOL)filteredPopularAndRecommendedTagsVisible {
    return self.filteredPopularAndRecommendedTags.count > 0;
}

- (void)handleTagSuggestions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.filteredPopularAndRecommendedTagsVisible) {
            [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
            
            NSInteger previousCount;
            if (self.filteredPopularAndRecommendedTagsVisible) {
                previousCount = self.filteredPopularAndRecommendedTags.count;
            } else if (self.tagCompletions.count > 0) {
                previousCount = self.tagCompletions.count;
                [self.tagCompletions removeAllObjects];
            } else {
                previousCount = 0;
            }
            
            [self.popularTags removeAllObjects];
            [self.recommendedTags removeAllObjects];
            
            NSArray *existingTags = [self existingTags];
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
            
            [self intersectionBetweenStartingAmount:previousCount
                                     andFinalAmount:self.filteredPopularAndRecommendedTags.count
                                             offset:[self tagOffset]
                                           callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   self.tagTextField.text = @"";

                                                   [self.tableView beginUpdates];
                                                   
                                                   if (self.loadingTags) {
                                                       self.loadingTags = NO;
                                                   }
                                                   
                                                   [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                                                   [self.tableView endUpdates];
                                               });
                                           }];
        }
    });
}

- (void)prefillPopularTags {
    NSURL *url = [NSURL URLWithString:self.bookmarkData[@"url"]];
    BOOL shouldPrefillTags = !self.loadingTags
    && !self.filteredPopularAndRecommendedTagsVisible
    && [[UIApplication sharedApplication] canOpenURL:url]
    && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTags) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingTags = YES;
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [self.unfilteredPopularTags removeAllObjects];
            [self.unfilteredRecommendedTags removeAllObjects];
            
            [pinboard tagSuggestionsForURL:self.bookmarkData[@"url"]
                                   success:^(NSArray *popular, NSArray *recommended) {
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                           [self.unfilteredPopularTags addObjectsFromArray:popular];
                                           [self.unfilteredRecommendedTags addObjectsFromArray:recommended];
                                           [self handleTagSuggestions];
                                       });
                                   }];
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self handleTagSuggestions];
        });
    }
}

- (void)searchUpdatedWithString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        self.autocompleteInProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *newTagCompletions = [NSMutableArray array];
            NSMutableArray *oldTagCompletions = [self.tagCompletions copy];
            if (string.length > 0) {
                NSString *searchString = [string stringByAppendingString:@"*"];
                NSArray *existingTags = [self existingTags];
                __block NSInteger skipPivot = 0;
                
                void (^DatabaseBlock)(FMDatabase *db) = ^(FMDatabase *db) {
                    NSMutableArray *queryComponents = [NSMutableArray array];
                    NSMutableArray *arguments = [NSMutableArray array];
                    [arguments addObject:searchString];
                    
                    [queryComponents addObject:@"SELECT DISTINCT tag_fts.name, tag.count FROM tag_fts, tag WHERE tag_fts.name MATCH ? AND tag_fts.name = tag.name"];
                    
                    for (NSString *tag in self.existingTags) {
                        [queryComponents addObject:@"AND tag.name != ?"];
                        [arguments addObject:tag];
                    }
                    
                    [queryComponents addObject:@"ORDER BY tag.count DESC LIMIT ?"];
                    [arguments addObject:@(MAX([self minTagsToAutocomplete], (NSInteger)([self maxTagsToAutocomplete] - self.existingTags.count)))];
                    
#warning XXX For some reason, getting double results here sometimes. Search duplication?
                    FMResultSet *result = [db executeQuery:[queryComponents componentsJoinedByString:@" "] withArgumentsInArray:arguments];
                    
                    NSString *tag, *count;
                    NSInteger index = [self tagOffset];
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
                                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(j+[self tagOffset]) inSection:0]];
                                    }
                                    
                                    tagFound = YES;
                                    skipPivot = i+1;
                                    break;
                                }
                            }
                            
                            if (!tagFound) {
                                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                            }
                            
                            index++;
                            [newTagCompletions addObject:tag];
                        }
                    }
                    
                    [result close];
                };
                
                if (self.presentedFromShareSheet) {
                    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
                    [[FMDatabaseQueue databaseQueueWithPath:[containerURL URLByAppendingPathComponent:@"shared.db"].path] inDatabase:DatabaseBlock];
                } else {
                    [[PPUtilities databaseQueue] inDatabase:DatabaseBlock];
                }

                if (self.filteredPopularAndRecommendedTagsVisible) {
                    [indexPathsToDelete addObjectsFromArray:self.indexPathsForPopularAndSuggestedRows];
                } else if (oldTagCompletions.count > 0) {
                    for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+[self tagOffset]) inSection:0]];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.popularTags removeAllObjects];
                    [self.recommendedTags removeAllObjects];
                    
                    self.tagCompletions = newTagCompletions;
                    //This is because '&' was shown as '&amp;' int tagCompletions
                    NSMutableArray *newArray = [NSMutableArray array];
                    for (NSString *input in self.tagCompletions)
                    {
                        NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
                            [newArray addObject:replacement];
                    }
                    self.tagCompletions = newArray;
                    
                    @try {
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    }
                    @catch (NSException *exception) {
                        [self.tableView reloadData];
                    }

                    self.autocompleteInProgress = NO;
                });
            } else if (!self.filteredPopularAndRecommendedTagsVisible) {
                self.autocompleteInProgress = NO;
            } else {
                self.autocompleteInProgress = NO;
            }
        });
    }
}

- (void)deleteTagWithName:(NSString *)name {
    [self deleteTagWithName:name animation:UITableViewRowAnimationFade];
}

- (void)deleteTagWithName:(NSString *)name animation:(UITableViewRowAnimation)animation {
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    NSMutableIndexSet *sectionIndicesToDelete = [NSMutableIndexSet indexSet];
    
    NSInteger index = [self.existingTags indexOfObject:name];
    
    if (self.existingTags.count > 1) {
        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(self.existingTags.count - index - 1) inSection:1]];
    } else {
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [sectionIndicesToDelete addIndex:1];
    }
    
    [self.existingTags removeObject:name];
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    
    [indexPathsToDelete addObjectsFromArray:self.indexPathsForAutocompletedRows];
    self.tagTextField.text = @"";
    self.searchString = @"";
    [self.tagCompletions removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:sectionIndicesToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:animation];
        [self.tableView endUpdates];
        
        if (self.searchString) {
            [self searchUpdatedWithString:self.searchString];
        }
    });
}

- (void)deleteTagButtonTouchUpInside:(id)sender {
    NSString *tag = [[self.deleteTagButtons allKeysForObject:sender] firstObject];
    [self deleteTagWithName:tag animation:UITableViewRowAnimationFade];
}

- (NSArray *)indexPathsForAutocompletedRows {
    return [self indexPathsForArray:self.tagCompletions offset:[self tagOffset]];
}

- (NSArray *)indexPathsForPopularAndSuggestedRows {
    return [self indexPathsForArray:self.filteredPopularAndRecommendedTags offset:[self tagOffset]];
}

- (NSInteger)tagOffset {
    if (self.existingTags.count > 0) {
        return 2;
    }
    return 1;
}

- (NSArray *)indexPathsForExistingRows {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i=0; i<self.existingTags.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:(i+[self tagOffset]) inSection:1]];
    }
    return [indexPaths copy];
}

- (NSArray *)indexPathsForArray:(NSArray *)array
                         offset:(NSInteger)offset {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i=0; i<array.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:(i+offset) inSection:0]];
    }
    return indexPaths;
}

#pragma mark - Notification Handlers

- (NSInteger)maxTagsToAutocomplete {
    if ([UIApplication isIPad]) {
        return 8;
    } else {
        return 6;
    }
}

- (NSInteger)minTagsToAutocomplete {
    if ([UIApplication isIPad]) {
        return 8;
    } else {
        return 4;
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
    
    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges
                                                                     options:@{
                                                                               PPBadgeFontSize: @([PPTheme staticBadgeFontSize]) }];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    wrapper.delegate = self;
    return wrapper;
}

#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    NSString *tag = badge.textLabel.text;
    self.currentlySelectedTag = tag;

    self.removeTagActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];

    [self.removeTagActionSheet lhs_addActionWithTitle:[NSString stringWithFormat:@"Remove '%@'", tag]
                                                style:UIAlertActionStyleDestructive
                                              handler:^(UIAlertAction *action) {
                                                  self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                                                  
                                                  NSIndexPath *indexPathToReload;
                                                  indexPathToReload = [NSIndexPath indexPathForRow:0 inSection:0];
                                                  
                                                  [self.tableView beginUpdates];
                                                  [self.tableView reloadRowsAtIndexPaths:@[indexPathToReload] withRowAnimation:UITableViewRowAnimationFade];
                                                  [self.tableView endUpdates];
                                                  
                                                  [self deleteTagWithName:self.currentlySelectedTag];
                                              }];

    [self.removeTagActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    CGRect rect = [badge lhs_centerRect];
    self.removeTagActionSheet.popoverPresentationController.sourceRect = [self.view convertRect:rect fromView:badge];
    self.removeTagActionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:self.removeTagActionSheet animated:YES completion:nil];
}

#pragma mark - UIKeyCommand

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.goBackKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.goBackKeyCommand) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - LHSKeyboardAdjusting

- (UIView *)keyboardAdjustingView {
    return self.tableView;
}

@end

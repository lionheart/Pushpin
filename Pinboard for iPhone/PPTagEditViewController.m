//
//  PPTagEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

#import "AppDelegate.h"
#import "PPTagEditViewController.h"
#import "PPTableViewHeader.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "UITableViewCellValue1.h"

#import <FMDB/FMDatabase.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPTagEditViewController ()

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
- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags;
- (void)keyboardDidHide:(NSNotification *)sender;

@end

@implementation PPTagEditViewController

#pragma mark - UIViewController

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tagTextField becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    NSDictionary *views = @{@"view": self.tableView,
                            @"guide": self.topLayoutGuide };
    [self.view lhs_addConstraints:@"V:[guide][view]|" views:views];
    [self.view lhs_addConstraints:@"H:|[view]|" views:views];
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Edit Tags";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Suggest" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonItemTouchUpInside:)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
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
    
    UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
    self.tagTextField = [[UITextField alloc] init];
    self.tagTextField.font = font;
    self.tagTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.tagTextField.userInteractionEnabled = YES;
    self.tagTextField.delegate = self;
    self.tagTextField.returnKeyType = UIReturnKeyDone;
    self.tagTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
#warning Set to the user defaults
    self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tagTextField.text = @"";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)keyboardDidHide:(NSNotification *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.autocompleteInProgress = NO;
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return MAX(44, [self.badgeWrapperView calculateHeightForWidth:300] + 20);
        }
        else {
            return 44;
        }
    }
    else {
        return 44;
    }
    
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        NSURL *url = [NSURL URLWithString:self.bookmarkData[@"url"]];
        return 30 + [PPTableViewHeader heightWithText:[NSString stringWithFormat:@"%@ (%@)", self.bookmarkData[@"title"], url.host] fontSize:15];
    }
    else {
        return 10 + [PPTableViewHeader heightWithText:@"Current Tags" fontSize:15];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger row = indexPath.row;
    
    if (row >= [self tagOffset] && indexPath.section == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *completion;
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            NSMutableIndexSet *indexSetsToInsert = [NSMutableIndexSet indexSet];
            
            // Add the row to the bookmark list below
            
            if (self.existingTags.count == 0) {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                [indexSetsToInsert addIndex:1];
            }
            else {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
            }
            
            NSInteger index = row - [self tagOffset];
            
            BOOL shouldRefreshAutocompletion = NO;
            if (self.tagCompletions.count > 0) {
                completion = self.tagCompletions[index];
                [indexPathsToDelete addObject:indexPath];
                [self.tagCompletions removeObjectAtIndex:index];
                [self.existingTags addObject:completion];
                
                shouldRefreshAutocompletion = self.tagCompletions.count > 0;
                if (!shouldRefreshAutocompletion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagTextField.text = @"";
                    });
                }
            }
            else if (self.filteredPopularAndRecommendedTagsVisible) {
                completion = self.filteredPopularAndRecommendedTags[index];
                
                if (index < self.popularTags.count) {
                    completion = self.popularTags[index];
                    [self.popularTags removeObjectAtIndex:index];
                }
                else {
                    completion = self.recommendedTags[index];
                    [self.recommendedTags removeObjectAtIndex:(index - self.popularTags.count)];
                }
                
                if (!self.filteredPopularAndRecommendedTagsVisible) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagTextField.text = @"";
                    });
                }
                
                [self.existingTags addObject:completion];
                [indexPathsToDelete addObject:indexPath];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertSections:indexSetsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
                if (shouldRefreshAutocompletion) {
                    [self searchUpdatedWithRange:NSMakeRange(0, 0) andString:@""];
                }

                [self.tagDelegate tagEditViewControllerDidUpdateTags:self];
            });
        });
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

    if (indexPath.section == 0) {
        NSInteger index = indexPath.row - [self tagOffset];
        
        if (index >= 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            if (self.filteredPopularAndRecommendedTagsVisible) {
                cell.textLabel.text = self.filteredPopularAndRecommendedTags[index];
                cell.detailTextLabel.textColor = HEX(0x96989DFF);
                cell.detailTextLabel.text = self.tagDescriptions[cell.textLabel.text];
            }
            else if (self.tagCompletions.count > 0) {
                NSString *tag = self.tagCompletions[index];
                cell.textLabel.text = tag;
                cell.detailTextLabel.text = self.tagCounts[tag];
            }
        }
        else {
            if ([self tagOffset] == 2 && indexPath.row == 0) {
                [cell.contentView addSubview:self.badgeWrapperView];
                [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": self.badgeWrapperView}];
                [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:@{@"badges": self.badgeWrapperView}];
            }
            else {
                UIImageView *topImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"toolbar-tag"] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                topImageView.frame = CGRectMake(14, 12, 20, 20);
                [cell.contentView addSubview:topImageView];
                
                if (self.loadingTags) {
                    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activity startAnimating];
                    cell.accessoryView = activity;
                    cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                    cell.textLabel.enabled = NO;
                }

                [cell.contentView addSubview:self.tagTextField];

                NSDictionary *views = @{@"view": self.tagTextField};
                [cell.contentView lhs_addConstraints:@"H:|-40-[view]-10-|" views:views];
                [cell.contentView lhs_addConstraints:@"V:|-10-[view]" views:views];
            }
        }
    }
    else {
        NSString *tag = self.existingTags[self.existingTags.count - indexPath.row - 1];
        cell.textLabel.text = tag;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 23, 23);
        [button setImage:[UIImage imageNamed:@"Delete-Button"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(deleteTagButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        self.deleteTagButtons[tag] = button;
        cell.accessoryView = button;
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.filteredPopularAndRecommendedTagsVisible) {
            return self.filteredPopularAndRecommendedTags.count + [self tagOffset];
        }
        else if (self.tagCompletions.count > 0) {
            return self.tagCompletions.count + [self tagOffset];
        }
        else {
            return [self tagOffset];
        }
    }
    else {
        return self.existingTags.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.existingTags.count == 0) {
        return 1;
    }
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [PPTableViewHeader headerWithText:@"Current Tags" fontSize:15];
    }
    else {
        NSURL *url = [NSURL URLWithString:self.bookmarkData[@"url"]];
        return [PPTableViewHeader headerWithText:[NSString stringWithFormat:@"%@ (%@)", self.bookmarkData[@"title"], url.host] fontSize:15];
    }
}

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
    }
    else {
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

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags {
    NSMutableArray *badges = [NSMutableArray array];
    NSArray *existingTags = [self existingTags];
    for (NSString *tag in existingTags) {
        if (![tag isEqualToString:@""]) {
            [badges addObject:@{ @"type": @"tag", @"tag": tag }];
        }
    }
    
    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme tagFontSize]) }];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    wrapper.delegate = self;
    return wrapper;
}


- (void)handleTagSuggestions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.filteredPopularAndRecommendedTagsVisible) {
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            
            NSInteger previousCount;
            if (self.filteredPopularAndRecommendedTagsVisible) {
                previousCount = self.filteredPopularAndRecommendedTags.count;
            }
            else if (self.tagCompletions.count > 0) {
                previousCount = self.tagCompletions.count;
                [self.tagCompletions removeAllObjects];
            }
            else {
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
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self handleTagSuggestions];
        });
    }
}


- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        self.autocompleteInProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *newTagCompletions = [NSMutableArray array];
            NSMutableArray *oldTagCompletions = [self.tagCompletions copy];
            
            NSString *newString = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (string && newString.length > 0) {
                NSString *searchString = [newString stringByAppendingString:@"*"];
                NSArray *existingTags = [self existingTags];
                
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];
                
                NSMutableArray *queryComponents = [NSMutableArray array];
                NSMutableArray *arguments = [NSMutableArray array];
                [arguments addObject:searchString];
                
                [queryComponents addObject:@"SELECT DISTINCT tag_fts.name, tag.count FROM tag_fts, tag WHERE tag_fts.name MATCH ? AND tag_fts.name = tag.name"];
                
                for (NSString *tag in self.existingTags) {
                    [queryComponents addObject:@"AND tag.name != ?"];
                    [arguments addObject:tag];
                }
                
                [queryComponents addObject:@"ORDER BY tag.count DESC LIMIT 6"];
                
#warning XXX For some reason, getting double results here sometimes. Search duplication?
                FMResultSet *result = [db executeQuery:[queryComponents componentsJoinedByString:@" "] withArgumentsInArray:arguments];
                
                NSString *tag, *count;
                NSInteger index = [self tagOffset];
                NSInteger skipPivot = 0;
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
                
                [db close];
                
                if (self.filteredPopularAndRecommendedTagsVisible) {
                    [indexPathsToDelete addObjectsFromArray:self.indexPathsForPopularAndSuggestedRows];
                }
                else if (oldTagCompletions.count > 0) {
                    for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+[self tagOffset]) inSection:0]];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.popularTags removeAllObjects];
                    [self.recommendedTags removeAllObjects];
                    
                    self.tagCompletions = newTagCompletions;
                    
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    self.autocompleteInProgress = NO;
                });
            }
            else if (!self.filteredPopularAndRecommendedTagsVisible) {
                self.autocompleteInProgress = NO;
            }
            else {
                self.autocompleteInProgress = NO;
            }
        });
    }
}

#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    NSString *tag = badge.textLabel.text;
    self.currentlySelectedTag = tag;
    
    NSString *prompt = [NSString stringWithFormat:@"Remove '%@'", tag];
    self.removeTagActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:prompt otherButtonTitles:nil];
    [self.removeTagActionSheet showFromRect:CGRectMake(0, 0, 0, 0) inView:self.view animated:YES];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.removeTagActionSheet) {
        if (buttonIndex == 0) {
            self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
            
            NSIndexPath *indexPathToReload;
            indexPathToReload = [NSIndexPath indexPathForRow:0 inSection:0];
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPathToReload] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            
            [self deleteTagWithName:self.currentlySelectedTag];
        }
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *invalidCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (string.length > 0) {
        NSRange range = [string rangeOfCharacterFromSet:invalidCharacterSet];
        BOOL containsInvalidCharacters = range.location != NSNotFound;
        if (containsInvalidCharacters) {
            return NO;
        }
    }
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (finalString.length == 0) {
        NSInteger finalAmount;
        if (self.filteredPopularAndRecommendedTagsVisible) {
            finalAmount = self.filteredPopularAndRecommendedTags.count;
            self.navigationItem.rightBarButtonItem.title = @"Suggest";
        }
        else {
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
    }
    else {
        [self searchUpdatedWithRange:range andString:string];
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
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                [indexSetsToInsert addIndex:1];
            }
            else {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:0 inSection:1]];
            }
            
            if (self.filteredPopularAndRecommendedTagsVisible) {
                [indexPathsToDelete addObjectsFromArray:[self indexPathsForPopularAndSuggestedRows]];
                [self.popularTags removeAllObjects];
                [self.recommendedTags removeAllObjects];
            }
            else {
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

            [self.tagDelegate tagEditViewControllerDidUpdateTags:self];
        }
    }
    else {
        [self.tagTextField resignFirstResponder];
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
    }
    else if (self.tagCompletions.count > 0) {
        indexPathsToDelete = [self indexPathsForAutocompletedRows];
        [self.tagCompletions removeAllObjects];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    return YES;
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
    }
    else {
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [sectionIndicesToDelete addIndex:1];
    }
    
    [self.existingTags removeObject:name];
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:sectionIndicesToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:animation];
        [self.tableView endUpdates];
        
        [self.tagDelegate tagEditViewControllerDidUpdateTags:self];
    });
}

- (void)rightBarButtonItemTouchUpInside:(id)sender {
    self.navigationItem.rightBarButtonItem.title = @"Suggest";
    
    if (self.filteredPopularAndRecommendedTagsVisible) {
        // Hide them if they're already showing
        NSInteger finalAmount;
        if (self.tagCompletions.count > 0) {
            finalAmount = self.tagCompletions.count;
        }
        else {
            finalAmount = 0;
        }
        
        [self intersectionBetweenStartingAmount:self.filteredPopularAndRecommendedTags.count
                                 andFinalAmount:finalAmount
                                         offset:[self tagOffset]
                                       callback:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                                           [self.popularTags removeAllObjects];
                                           [self.recommendedTags removeAllObjects];
                                           
                                           [self.tableView beginUpdates];
                                           [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                                           [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                                           [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                                           [self.tableView endUpdates];
                                       }];
    }
    else {
        self.navigationItem.rightBarButtonItem.title = @"Hide";
        [self prefillPopularTags];
    }
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
    if (self.existingTags.count == 0) {
        return 1;
    }
    return 2;
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

@end

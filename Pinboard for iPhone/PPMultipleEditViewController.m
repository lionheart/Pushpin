//
//  PPMultipleEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "PPMultipleEditViewController.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "UITableViewCellValue1.h"

#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSInteger kMultipleEditViewControllerTagIndexOffset = 1;
static NSString *CellIdentifier = @"Cell";

@interface PPMultipleEditViewController ()

@end

@implementation PPMultipleEditViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tagsToAdd = [NSMutableArray array];
        self.tagsToRemove = [NSMutableArray array];
        
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
        self.tagsToAddTextField = [[UITextField alloc] init];
        self.tagsToAddTextField.font = font;
        self.tagsToAddTextField.delegate = self;
        self.tagsToAddTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagsToAddTextField.placeholder = NSLocalizedString(@"Tap here to add tags", nil);
        self.tagsToAddTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagsToAddTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagsToAddTextField.text = @"";
        
        self.tagCounts = [NSMutableDictionary dictionary];
        self.tagsToAddCompletions = [NSMutableArray array];
        self.autocompleteInProgress = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (id)initWithTags:(NSArray *)tags {
    _existingTags = [NSMutableArray arrayWithArray:tags];
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.existingTags.count > 0 || self.tagsToAdd.count > 0) {
            return 2 + self.tagsToAddCompletions.count;
        } else {
            return 1 + self.tagsToAddCompletions.count;
        }
    } else if (section == 1) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.contentView lhs_removeSubviews];
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.textLabel.font = [PPTheme cellTextLabelFont];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [PPTheme cellTextLabelFont];
    
    CGRect frame = cell.frame;
    
    // TODO: This is a bit of a hack, and could be updated to reuse the views
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[PPBadgeWrapperView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.imageView.image = [[UIImage imageNamed:@"navigation-tags"] lhs_imageWithColor:HEX(0x1a98fcff)];
            self.tagsToAddTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
            [cell.contentView addSubview:self.tagsToAddTextField];
            cell.accessoryView = nil;
        } else if (indexPath.row == (1 + self.tagsToAddCompletions.count)) {
            // Bottom badge view
            NSMutableArray *badges = [NSMutableArray array];
            [self.existingTags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([self.tagsToRemove containsObject:obj]) {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj, @"options": @{ PPBadgeNormalBackgroundColor: HEX(0xCCCCCCFF) } }];
                } else {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj }];
                }
            }];
            
            [self.tagsToAdd enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([self.tagsToRemove containsObject:obj]) {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj, @"options": @{ PPBadgeNormalBackgroundColor: HEX(0xCCCCCCFF) } }];
                } else {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj, @"options": @{ PPBadgeNormalBackgroundColor: HEX(0xa8db4cff) } }];
                }
            }];
            
            PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @(14.0f) }];
            badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
            [cell.contentView addSubview:badgeWrapperView];
            [cell.contentView lhs_addConstraints:@"H:|-40-[badges]-10-|" views:@{@"badges": badgeWrapperView }];
            [cell.contentView lhs_addConstraints:@"V:|-10-[badges]-10-|" views:@{ @"badges": badgeWrapperView }];
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            NSString *tag = self.tagsToAddCompletions[indexPath.row - kMultipleEditViewControllerTagIndexOffset];
            cell.textLabel.text = tag;
            cell.detailTextLabel.text = self.tagCounts[tag];
        }
    } else if (indexPath.section == 1) {
        NSMutableArray *badges = [NSMutableArray array];
        [self.tagsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [badges addObject:@{ @"type": @"tag", @"tag": obj }];
        }];
        PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @(14.0f), PPBadgeNormalBackgroundColor: HEX(0xfc5579ff) }];
        badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:badgeWrapperView];
        [cell.contentView lhs_addConstraints:@"H:|-40-[badges]-10-|" views:@{@"badges": badgeWrapperView }];
        [cell.contentView lhs_addConstraints:@"V:|-10-[badges]-10-|" views:@{ @"badges": badgeWrapperView }];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (1 + self.tagsToAddCompletions.count)) {
        NSMutableArray *badges = [NSMutableArray array];
        [self.existingTags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [badges addObject:@{ @"type": @"tag", @"tag": obj }];
        }];
        
        PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @(14.0f) }];
        CGFloat totalHeight = [badgeWrapperView calculateHeight] + 20.0f;
        NSLog(@"Total height is %f", totalHeight);
        return totalHeight;
    }
    
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0 || indexPath.row == (1 + self.tagsToAddCompletions.count)) {
        return;
    }
    
    UITextField *textField;
    NSMutableArray *tagCompletions;
    if (indexPath.section == 0) {
        textField = self.tagsToAddTextField;
        tagCompletions = self.tagsToAddCompletions;
    }

    NSInteger row = indexPath.row;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *completion;
        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
        
        if (tagCompletions.count > 0) {
            completion = tagCompletions[row - kMultipleEditViewControllerTagIndexOffset];
            
            for (NSInteger i=0; i<tagCompletions.count; i++) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i + kMultipleEditViewControllerTagIndexOffset) inSection:indexPath.section]];
            }
            
            [tagCompletions removeAllObjects];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            
            [self.tagsToAdd addObject:completion];
            textField.text = @"";
            [self.tableView reloadData];
        });
    });
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if (self.tagsToRemove.count > 0 || self.tagsToAdd.count > 0) {
            NSMutableString *footerString = [NSMutableString string];
            if (self.tagsToRemove.count == 1) {
                [footerString appendString:NSLocalizedString(@"1 tag will be deleted", nil)];
            } else if (self.tagsToRemove.count >= 2) {
                [footerString appendString:[NSString stringWithFormat:@"%lu %@", (unsigned long)self.tagsToRemove.count, NSLocalizedString(@"tags will be deleted", nil)]];
            }
            
            if (self.tagsToRemove.count > 0 && self.tagsToAdd.count > 0) {
                [footerString appendString:@", "];
            }
            
            if (self.tagsToAdd.count == 1) {
                [footerString appendString:NSLocalizedString(@"1 tag will be added", nil)];
            } else if (self.tagsToAdd.count >= 2) {
                [footerString appendString:[NSString stringWithFormat:@"%lu %@", (unsigned long)self.tagsToAdd.count, NSLocalizedString(@"tags will be added", nil)]];
            }
            
            return footerString;
        } else if (self.existingTags.count > 0 || self.tagsToAdd.count > 0) {
            return @"Tap an existing tag to remove it";
        }
    }
    
    return @"";
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagsToAddTextField) {
        if (textField.text.length > 0 && [textField.text characterAtIndex:textField.text.length-1] == ' ' && [string isEqualToString:@" "]) {
            return NO;
        }
        else {
            [self tagsToAddTextFieldUpdatedWithRange:range andString:string];
        }
    }
    return YES;
}

- (void)tagsToAddTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound) {
            self.autocompleteInProgress = YES;
            NSString *tagTextFieldText = self.tagsToAddTextField.text;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                NSMutableArray *indexPathsToReload = [NSMutableArray array];
                NSMutableArray *indexPathsToAdd = [NSMutableArray array];
                NSMutableArray *newTagCompletions = [NSMutableArray array];
                NSMutableArray *oldTagCompletions = [self.tagsToAddCompletions copy];
                
                NSString *newString = [tagTextFieldText stringByReplacingCharactersInRange:range withString:string];
                if (string && newString.length > 0) {
                    NSString *newTextFieldContents;
                    if (range.length > string.length) {
                        newTextFieldContents = [tagTextFieldText substringToIndex:tagTextFieldText.length - range.length];
                    }
                    else {
                        newTextFieldContents = [NSString stringWithFormat:@"%@", tagTextFieldText];
                    }
                    
                    NSString *searchString = [[[newTextFieldContents componentsSeparatedByString:@" "] lastObject] stringByAppendingFormat:@"%@*", string];
                    NSArray *existingTags = [tagTextFieldText componentsSeparatedByString:@" "];
                    
                    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                    [db open];
                    
                    #warning XXX For some reason, getting double results here sometimes. Search duplication?
                    FMResultSet *result = [db executeQuery:@"SELECT DISTINCT tag_fts.name, tag.count FROM tag_fts, tag WHERE tag_fts.name MATCH ? AND tag_fts.name = tag.name ORDER BY tag.count DESC LIMIT 6" withArgumentsInArray:@[searchString]];
                    
                    NSString *tag;
                    NSInteger index = kMultipleEditViewControllerTagIndexOffset;
                    NSInteger skipPivot = 0;
                    BOOL tagFound = NO;
                    
                    while ([result next]) {
                        tagFound = NO;
                        tag = [result stringForColumnIndex:0];
                        self.tagCounts[tag] = [result stringForColumnIndex:1];
                        if (![existingTags containsObject:tag]) {
                            for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                                if ([oldTagCompletions[i] isEqualToString:tag]) {
                                    // Delete all posts that were skipped
                                    for (NSInteger j=skipPivot; j<i; j++) {
                                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(j+kMultipleEditViewControllerTagIndexOffset) inSection:0]];
                                    }
                                    
                                    tagFound = YES;
                                    skipPivot = i+1;
                                    break;
                                }
                            }
                            
                            if (!tagFound) {
                                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                            }
                            
                            index++;
                            [newTagCompletions addObject:tag];
                        }
                    }
                    
                    [db close];
                    
                    for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i+kMultipleEditViewControllerTagIndexOffset inSection:0]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagsToAddCompletions = newTagCompletions;

                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                        self.autocompleteInProgress = NO;
                    });
                }
                else {
                    if (self.tagsToAddCompletions.count > 0) {
                        NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                        NSMutableArray *indexPathsToAdd = [NSMutableArray array];

                        for (NSInteger i=0; i<self.tagsToAddCompletions.count; i++) {
                            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i+kMultipleEditViewControllerTagIndexOffset inSection:0]];
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tagsToAddCompletions removeAllObjects];
                            [self.tableView beginUpdates];
                            [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];
                            self.autocompleteInProgress = NO;
                        });
                    }
                    else {
                        self.autocompleteInProgress = NO;
                    }
                }
            });
        }
    }
}

@end

//
//  PPMultipleEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPMultipleEditViewController.h"
#import "PPGroupedTableViewCell.h"
#import "PPCoreGraphics.h"
#import "FMDatabase.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

static NSInteger kMultipleEditViewControllerTagIndexOffset = 1;

@interface PPMultipleEditViewController ()

@end

@implementation PPMultipleEditViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        self.tagsToAddTextField = [[UITextField alloc] init];
        self.tagsToAddTextField.font = font;
        self.tagsToAddTextField.delegate = self;
        self.tagsToAddTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagsToAddTextField.placeholder = NSLocalizedString(@"Enter tags to add.", nil);
        self.tagsToAddTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagsToAddTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagsToAddTextField.text = @"";
        
        self.tagsToRemoveTextField = [[UITextField alloc] init];
        self.tagsToRemoveTextField.font = font;
        self.tagsToRemoveTextField.delegate = self;
        self.tagsToRemoveTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagsToRemoveTextField.placeholder = NSLocalizedString(@"Enter tags to remove.", nil);
        self.tagsToRemoveTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagsToRemoveTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagsToRemoveTextField.text = @"";
        
        self.tagCounts = [NSMutableDictionary dictionary];
        self.tagsToAddCompletions = [NSMutableArray array];
        self.autocompleteInProgress = NO;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tagsToAddCompletions.count > 0) {
        return 1 + self.tagsToAddCompletions.count;
    }
    return 2 + self.tagsToAddCompletions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSArray *subviews = [cell.contentView subviews];
    for (UIView *view in subviews) {
        [view removeFromSuperview];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
    }
    
    if (indexPath.row < 5) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
    }
    
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];
    
    CGRect frame = cell.frame;
    
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"tag-plus-dash"];
        self.tagsToAddTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
        [cell.contentView addSubview:self.tagsToAddTextField];
        cell.accessoryView = nil;
    }
    else {
        if (self.tagsToAddCompletions.count > 0) {
            NSString *tag = self.tagsToAddCompletions[indexPath.row - kMultipleEditViewControllerTagIndexOffset];
            cell.textLabel.text = tag;
            UIImage *pillImage = [PPCoreGraphics pillImage:self.tagCounts[tag]];
            UIImageView *pillView = [[UIImageView alloc] initWithImage:pillImage];
            pillView.frame = CGRectMake(320 - pillImage.size.width - 30, (cell.contentView.frame.size.height - pillImage.size.height) / 2, pillImage.size.width, pillImage.size.height);
            [cell.contentView addSubview:pillView];
        }
        else {
            cell.imageView.image = [UIImage imageNamed:@"tag-minus-dash"];
            self.tagsToRemoveTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
            [cell.contentView addSubview:self.tagsToRemoveTextField];
            cell.accessoryView = nil;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

                    if (oldTagCompletions.count > 0 && newTagCompletions.count == 0) {
                        [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:1 inSection:0]];
                    }

                    if (newTagCompletions.count > 0 && oldTagCompletions.count == 0) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:1 inSection:0]];
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
                        [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:1 inSection:0]];

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

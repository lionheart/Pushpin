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
        UIFont *font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
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
        self.existingTags = [NSMutableArray arrayWithArray:@[@"one", @"onnnnn", @"two", @"three"]];
        self.autocompleteInProgress = NO;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1 + self.tagsToAddCompletions.count;
    }
    else {
        return 1 + self.tagsToRemoveCompletions.count;
    }
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
    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    
    CGRect frame = cell.frame;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [UIImage imageNamed:@"tag-plus-dash"];
                self.tagsToAddTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
                [cell.contentView addSubview:self.tagsToAddTextField];
                cell.accessoryView = nil;
                break;
                
            default: {
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                NSString *tag = self.tagsToAddCompletions[indexPath.row - kMultipleEditViewControllerTagIndexOffset];
                cell.textLabel.text = tag;
                UIImage *pillImage = [PPCoreGraphics pillImage:self.tagCounts[tag]];
                UIImageView *pillView = [[UIImageView alloc] initWithImage:pillImage];
                pillView.frame = CGRectMake(320 - pillImage.size.width - 30, (cell.contentView.frame.size.height - pillImage.size.height) / 2, pillImage.size.width, pillImage.size.height);
                [cell.contentView addSubview:pillView];
                break;
            }
        }
    }
    else {
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [UIImage imageNamed:@"tag-minus-dash"];
                self.tagsToRemoveTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
                [cell.contentView addSubview:self.tagsToRemoveTextField];
                cell.accessoryView = nil;
                break;
                
            default: {
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                NSString *tag = self.tagsToRemoveCompletions[indexPath.row - kMultipleEditViewControllerTagIndexOffset];
                cell.textLabel.text = tag;
                break;
            }
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITextField *textField;
    NSMutableArray *tagCompletions;
    if (indexPath.section == 0) {
        textField = self.tagsToAddTextField;
        tagCompletions = self.tagsToAddCompletions;
    }
    else {
        textField = self.tagsToRemoveTextField;
        tagCompletions = self.tagsToRemoveCompletions;
    }

    NSString *tagText = textField.text;
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
            
            NSString *stringToReplace = [[tagText componentsSeparatedByString:@" "] lastObject];
            NSRange range = NSMakeRange(tagText.length - stringToReplace.length, stringToReplace.length);
            textField.text = [tagText stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", completion]];
        });
    });
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
    else if (textField == self.tagsToRemoveTextField) {
        if (textField.text.length > 0 && [textField.text characterAtIndex:textField.text.length-1] == ' ' && [string isEqualToString:@" "]) {
            return NO;
        }
        else {
            [self tagsToRemoveTextFieldUpdatedWithRange:range andString:string];
        }
    }
    return YES;
}

- (void)tagsToRemoveTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    if (!self.autocompleteInProgress) {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound) {
            self.autocompleteInProgress = YES;
            NSString *tagTextFieldText = self.tagsToRemoveTextField.text;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                NSMutableArray *indexPathsToReload = [NSMutableArray array];
                NSMutableArray *indexPathsToAdd = [NSMutableArray array];
                NSMutableArray *newTagCompletions = [NSMutableArray array];
                NSMutableArray *oldTagCompletions = [self.tagsToRemoveCompletions copy];
                
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
                    
                    FMDatabase *db = [FMDatabase databaseWithPath:@":memory:"];
                    [db open];
                    [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts4(name);"];
                    
                    for (NSString *tag in self.existingTags) {
                        if (![existingTags containsObject:tag]) {
                            [db executeUpdate:@"INSERT INTO tag_fts (name) VALUES(?)" withArgumentsInArray:@[tag]];
                        }
                    }

                    FMResultSet *result = [db executeQuery:@"SELECT name FROM tag_fts WHERE name MATCH ? ORDER BY name ASC LIMIT 6" withArgumentsInArray:@[searchString]];
                    
                    NSString *tag;
                    NSInteger index = kMultipleEditViewControllerTagIndexOffset;
                    NSInteger skipPivot = 0;
                    BOOL tagFound = NO;
                    
                    while ([result next]) {
                        tagFound = NO;
                        tag = [result stringForColumnIndex:0];

                        for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                            if ([oldTagCompletions[i] isEqualToString:tag]) {
                                // Delete all posts that were skipped
                                for (NSInteger j=skipPivot; j<i; j++) {
                                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(j+kMultipleEditViewControllerTagIndexOffset) inSection:1]];
                                }
                                
                                tagFound = YES;
                                skipPivot = i + 1;
                                break;
                            }
                        }
                        
                        if (!tagFound) {
                            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:1]];
                        }
                        
                        index++;
                        [newTagCompletions addObject:tag];
                    }
                    
                    [db close];
                    
                    for (NSInteger i=skipPivot; i<oldTagCompletions.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i+kMultipleEditViewControllerTagIndexOffset inSection:1]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagsToRemoveCompletions = newTagCompletions;
                        
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                        self.autocompleteInProgress = NO;
                    });
                }
                else {
                    if (self.tagsToRemoveCompletions.count > 0) {
                        NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                        NSMutableArray *indexPathsToAdd = [NSMutableArray array];
                        
                        for (NSInteger i=0; i<self.tagsToRemoveCompletions.count; i++) {
                            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i+kMultipleEditViewControllerTagIndexOffset inSection:1]];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tagsToRemoveCompletions removeAllObjects];
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

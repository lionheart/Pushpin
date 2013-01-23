//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "AddBookmarkViewController.h"
#import "NSString+URLEncoding.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface AddBookmarkViewController ()

@end

@implementation AddBookmarkViewController

@synthesize modalDelegate;
@synthesize urlTextField;
@synthesize descriptionTextField;
@synthesize titleTextField;
@synthesize tagTextField;
@synthesize privateSwitch;
@synthesize readSwitch;
@synthesize markAsRead;
@synthesize setAsPrivate;
@synthesize tagCompletions;
@synthesize currentTextField;
@synthesize callback;
@synthesize loadingTitle;
@synthesize previousURLContents;
@synthesize titleGestureRecognizer;
@synthesize descriptionGestureRecognizer;
@synthesize tagGestureRecognizer;
@synthesize loadingTags;
@synthesize popularTagSuggestions;
@synthesize leftSwipeTagGestureRecognizer;
@synthesize suggestedTagsVisible;
@synthesize previousTagSuggestions;
@synthesize suggestedTagsPayload;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.urlTextField = [[UITextField alloc] init];
        self.urlTextField.font = [UIFont systemFontOfSize:16];
        self.urlTextField.delegate = self;
        self.urlTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.urlTextField.placeholder = @"https://pinboard.in/";
        self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.urlTextField.text = @"";
        self.previousURLContents = @"";
        
        self.descriptionTextField = [[UITextField alloc] init];
        self.descriptionTextField.font = [UIFont systemFontOfSize:16];
        self.descriptionTextField.delegate = self;
        self.descriptionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.descriptionTextField.placeholder = @"";
        self.descriptionTextField.text = @"";
        
        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.font = [UIFont systemFontOfSize:16];
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Add bookmark title example", nil);
        self.titleTextField.text = @"";
        
        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = [UIFont systemFontOfSize:16];
        self.tagTextField.delegate = self;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.placeholder = NSLocalizedString(@"Add bookmark tag example", nil);
        self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagTextField.text = @"";
        
        self.markAsRead = @(NO);
        self.loadingTitle = NO;
        self.loadingTags = NO;
        self.suggestedTagsVisible = NO;
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
        self.popularTagSuggestions = [[NSMutableArray alloc] init];
        self.previousTagSuggestions = [[NSMutableArray alloc] init];
        self.suggestedTagsPayload = nil;

        self.callback = ^(void) {};
        self.titleGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.titleGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.titleTextField addGestureRecognizer:self.titleGestureRecognizer];

        self.descriptionGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.descriptionGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.descriptionTextField addGestureRecognizer:self.descriptionGestureRecognizer];

        self.tagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.tagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.tagTextField addGestureRecognizer:self.tagGestureRecognizer];
        
        self.leftSwipeTagGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.leftSwipeTagGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.tagTextField addGestureRecognizer:self.leftSwipeTagGestureRecognizer];
    }
    return self;
}

- (void)handleGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.tagGestureRecognizer) {
        [self prefillPopularTags];
    }
    else if (gestureRecognizer == self.titleGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.descriptionGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.leftSwipeTagGestureRecognizer) {
        if (self.popularTagSuggestions.count > 0) {
            if (self.suggestedTagsVisible) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableArray *indexPathsToRemove = [[NSMutableArray alloc] init];
                    NSInteger index = 1;
                    while (index <= self.popularTagSuggestions.count) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                        index++;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                        [self.popularTagSuggestions removeAllObjects];
                        self.suggestedTagsVisible = NO;
                        [self.tableView endUpdates];
                    });
                });
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tagCompletions = [NSMutableArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.urlTextField];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 4) {
        return 2;
    }
    else if (section == 3) {
        if (self.suggestedTagsVisible) {
            return 1 + self.popularTagSuggestions.count;
        }
        else {
            return 1 + self.tagCompletions.count;
        }
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 && indexPath.row > 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        unichar space = ' ';
        if (self.tagTextField.text.length > 0 && [self.tagTextField.text characterAtIndex:self.tagTextField.text.length - 1] != space) {
            self.tagTextField.text = [NSString stringWithFormat:@"%@ ", self.tagTextField.text];
        }
        NSString *stringToReplace = [[self.tagTextField.text componentsSeparatedByString:@" "] lastObject];
        NSRange range = NSMakeRange([self.tagTextField.text length] - [stringToReplace length], [stringToReplace length]);
        NSString *completion;

        if (self.tagCompletions.count > 0) {
            completion = self.tagCompletions[indexPath.row - 1];
            [self.tagCompletions removeObjectAtIndex:indexPath.row - 1];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else if (self.popularTagSuggestions.count > 0) {
            completion = self.popularTagSuggestions[indexPath.row - 1];
            self.previousTagSuggestions = [[NSMutableArray alloc] initWithArray:self.popularTagSuggestions];
            [self.popularTagSuggestions removeObjectAtIndex:indexPath.row - 1];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        self.tagTextField.text = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", completion]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return NSLocalizedString(@"Separate tags with spaces", nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"URL", nil);
            break;
        case 1:
            return NSLocalizedString(@"Title", nil);
            break;
        case 2:
            return NSLocalizedString(@"Description", nil);
            break;
        case 3:
            return NSLocalizedString(@"Tags", nil);
            break;
        case 4:
            return NSLocalizedString(@"Other", nil);
            break;
        default:
            break;
    }
    return @"";
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;

    if (self.currentTextField == self.tagTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.descriptionTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.urlTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    return YES;
}

- (void)keyboardDidShow:(NSNotification *)sender {
    if (self.currentTextField == self.tagTextField) {
        CGSize kbSize = [[[sender userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.bottom = kbSize.height;
        self.tableView.contentInset = insets;
    }

    if (self.currentTextField == self.tagTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.descriptionTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.urlTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)keyboardDidHide:(NSNotification *)sender {
    self.tableView.contentInset = UIEdgeInsetsZero;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.callback();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    NSMutableArray *indexPathsToRemove = [[NSMutableArray alloc] init];
    NSMutableArray *indexPathsToAdd = [[NSMutableArray alloc] init];
    NSMutableArray *newTagCompletions = [NSMutableArray array];
    NSMutableArray *oldTagCompletions = [self.tagCompletions copy];

    DLog(@"STRING %@", string);
    NSString *newString = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:string];
    if (string != nil && newString.length > 0 && [newString characterAtIndex:newString.length-1] != ' ') {
        NSString *newTextFieldContents;
        if (range.length > string.length) {
            newTextFieldContents = [self.tagTextField.text substringToIndex:self.tagTextField.text.length - range.length];
        }
        else {
            newTextFieldContents = [NSString stringWithFormat:@"%@", self.tagTextField.text];
        }

        NSString *searchString = [[[newTextFieldContents componentsSeparatedByString:@" "] lastObject] stringByAppendingFormat:@"%@*", string];
        NSArray *existingTags = [self.tagTextField.text componentsSeparatedByString:@" "];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *result = [db executeQuery:@"SELECT tag_fts.name FROM tag_fts, tag WHERE tag.id=tag_fts.id AND tag_fts.name MATCH ? ORDER BY tag.count DESC LIMIT 6" withArgumentsInArray:@[searchString]];

            NSString *currentTag;
            NSInteger index = 1;
            while ([result next]) {
                currentTag = [result stringForColumn:@"name"];
                if (![existingTags containsObject:currentTag]) {
                    [newTagCompletions addObject:currentTag];
                    if (![oldTagCompletions containsObject:currentTag]) {
                        [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                        [self.tagCompletions addObject:currentTag];
                    }
                    index++;
                }
            }
            [db close];
            
            if (self.suggestedTagsVisible) {
                index = 1;
                while (index <= self.popularTagSuggestions.count) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                    index++;
                }
                self.suggestedTagsVisible = NO;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                
                for (int i=0; i<oldTagCompletions.count; i++) {
                    if (![newTagCompletions containsObject:oldTagCompletions[i]]) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:1+[self.tagCompletions indexOfObject:oldTagCompletions[i]] inSection:3]];
                    }
                }

                DLog(@"OLD %d", oldTagCompletions.count);
                DLog(@"ADD %d", indexPathsToAdd.count);
                
                self.tagCompletions = newTagCompletions;
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];

                DLog(@"REMOVE %d", indexPathsToRemove.count);
                DLog(@"NEW %d", newTagCompletions.count);
                
                DLog(@"%@", newTagCompletions);
                
                [self.tableView endUpdates];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            });
        });
    }
    else if (!self.suggestedTagsVisible) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger index = 1;

            while (index <= self.tagCompletions.count) {
                [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                index++;
            }
            
            index = 1;
            while (index <= self.popularTagSuggestions.count) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                index++;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                
                if ([indexPathsToRemove count] > 0) {
                    DLog(@"LL REMOVE %d", indexPathsToRemove.count);
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                }
                
                if ([indexPathsToAdd count] > 0) {
                    DLog(@"LL ADD %d", indexPathsToAdd.count);
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                }
                
                DLog(@"%@", self.popularTagSuggestions);
                
                self.suggestedTagsVisible = YES;
                [self.tagCompletions removeAllObjects];
                
                [self.tableView endUpdates];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            });

        });
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagTextField) {
        [self searchUpdatedWithRange:range andString:string];
    }
    else if (textField == self.urlTextField) {
        if ([string isEqualToString:@" "]) {
            return NO;
        }
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.textLabel.enabled = YES;
    
    for (UIView *view in [cell.contentView subviews]) {
        [view removeFromSuperview];
    }

    if (indexPath.section < 5) {
        CGRect frame = cell.frame;

        switch (indexPath.section) {
            case 0:
                self.urlTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 280, 31);
                [cell.contentView addSubview:self.urlTextField];
                break;
                
            case 1:
                if (self.loadingTitle) {
                    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activity startAnimating];
                    cell.accessoryView = activity;
                    cell.textLabel.text = @"Loading";
                    cell.textLabel.enabled = NO;
                }
                else {
                    self.titleTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 280, 31);
                    [cell.contentView addSubview:self.titleTextField];
                }
                break;
                
            case 2:
                if (self.loadingTitle) {
                    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activity startAnimating];
                    cell.accessoryView = activity;
                    cell.textLabel.text = @"Loading";
                    cell.textLabel.enabled = NO;
                }
                else {
                    self.descriptionTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 280, 31);
                    cell.accessoryView = nil;
                    [cell.contentView addSubview:self.descriptionTextField];
                }
                break;
                
            case 3:
                if (indexPath.row == 0) {
                    if (self.loadingTags) {
                        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                        [activity startAnimating];
                        cell.accessoryView = activity;
                        cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                        cell.textLabel.enabled = NO;
                    }
                    else {
                        self.tagTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 280, 31);
                        cell.accessoryView = nil;
                        [cell.contentView addSubview:self.tagTextField];
                    }
                }
                else {
                    if (self.tagCompletions.count > 0) {
                        cell.textLabel.text = self.tagCompletions[indexPath.row - 1];
                    }
                    else {
                        cell.textLabel.text = self.popularTagSuggestions[indexPath.row - 1];
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.editing = NO;
                }
                break;
                
            case 4: {
                if (indexPath.row == 0) {
                    if (self.setAsPrivate.boolValue) {
                        cell.textLabel.text = [NSString stringWithFormat:@"🔒 %@", NSLocalizedString(@"Set as private?", nil)];
                    }
                    else {
                        cell.textLabel.text = [NSString stringWithFormat:@"🔓 %@", NSLocalizedString(@"Set as private?", nil)];
                    }

                    self.privateSwitch = [[UISwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.privateSwitch.frame.size;
                    self.privateSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateSwitch.on = self.setAsPrivate.boolValue;
                    [self.privateSwitch addTarget:self action:@selector(privateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateSwitch;
                }
                else if (indexPath.row == 1) {
                    if (self.markAsRead.boolValue) {
                        cell.textLabel.text = [NSString stringWithFormat:@"👏 %@", NSLocalizedString(@"Mark as read?", nil)];
                    }
                    else {
                        cell.textLabel.text = [NSString stringWithFormat:@"📦 %@", NSLocalizedString(@"Mark as read?", nil)];
                    }

                    self.readSwitch = [[UISwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.readSwitch.frame.size;
                    self.readSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.readSwitch.on = self.markAsRead.boolValue;
                    [self.readSwitch addTarget:self action:@selector(readSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.readSwitch;
                }
                break;
            }

            default:
                break;
        }
    }

    return cell;
}

- (void)privateSwitchChanged:(id)sender {
    self.setAsPrivate = @(self.privateSwitch.on);
    [self.tableView reloadData];
}

- (void)readSwitchChanged:(id)sender {
    self.markAsRead = @(self.readSwitch.on);
    [self.tableView reloadData];
}

- (void)urlTextFieldDidChange:(NSNotification *)notification {
    if ([UIPasteboard generalPasteboard].string == self.urlTextField.text) {
        [self prefillTitleAndForceUpdate:NO];
    }
}

- (void)handleTagSuggestions {
    self.loadingTags = NO;
    NSString *tagText = self.tagTextField.text;
    NSMutableArray *indexPathsToRemove = [[NSMutableArray alloc] init];
    NSMutableArray *indexPathsToAdd = [[NSMutableArray alloc] init];
    NSMutableArray *newPopularTagSuggestions = [[NSMutableArray alloc] init];
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    
    NSInteger previousRowCount = self.suggestedTagsVisible ? self.popularTagSuggestions.count : self.tagCompletions.count;
    NSInteger index = 1;
    while (index <= previousRowCount) {
        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:index inSection:3]];
        index++;
    }
    
    NSArray *popularTags = self.suggestedTagsPayload[0][@"popular"];
    NSArray *recommendedTags = self.suggestedTagsPayload[1][@"recommended"];
    NSArray *existingTags = [tagText componentsSeparatedByString:@" "];

    for (id tag in popularTags) {
        if (![existingTags containsObject:tag]) {
            [newPopularTagSuggestions addObject:tag];
        }
    }
    for (id tag in recommendedTags) {
        if (![existingTags containsObject:tag] && ![popularTags containsObject:tag]) {
            [newPopularTagSuggestions addObject:tag];
        }
    }
    [newPopularTagSuggestions filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF MATCHES '^[ ]?$'"]];

    index = 1;
    while (index <= newPopularTagSuggestions.count) {
        [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:3]];
        index++;
    }
    DLog(@"%d", self.popularTagSuggestions.count);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
        
        self.popularTagSuggestions = newPopularTagSuggestions;
        self.suggestedTagsVisible = YES;
        
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

- (void)prefillPopularTags {
    if (self.suggestedTagsPayload == nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/suggest?url=%@&auth_token=%@&format=json", [self.urlTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [[AppDelegate sharedDelegate] token]]]];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                self.loadingTags = YES;
                [self.tableView endUpdates];
            });
        });

        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                               [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                                       if (!error) {
                                           self.suggestedTagsPayload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                           [self handleTagSuggestions];
                                       }

                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [self.tableView beginUpdates];
                                               [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                                               self.loadingTags = NO;
                                               [self.tableView endUpdates];
                                           });
                                       });
                                   });
                               }];
    }
    else {
        [self handleTagSuggestions];
    }
}

- (void)prefillTitleAndForceUpdate:(BOOL)forceUpdate {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    self.previousURLContents = self.urlTextField.text;

    BOOL shouldPrefillTitle = !self.loadingTitle
        && (forceUpdate || self.titleTextField == nil || [self.titleTextField.text isEqualToString:@""])
        && [[UIApplication sharedApplication] canOpenURL:url]
        && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTitle) {
        [self.urlTextField resignFirstResponder];
        self.loadingTitle = YES;

        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:0 inSection:2]];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [[AppDelegate sharedDelegate] retrievePageTitle:url
                                               callback:^(NSString *title, NSString *description) {
                                                   self.titleTextField.text = title;
                                                   self.descriptionTextField.text = description;
                                                   self.loadingTitle = NO;
                                                   [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                                               }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.urlTextField) {
        [self prefillTitleAndForceUpdate:NO];
    }
    return YES;
}

- (void)close {
    [self.modalDelegate closeModal:self];
}

- (void)addBookmark {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
        #warning Should display a message to the user
        return;
    }

    if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:NSLocalizedString(@"Add bookmark missing url or title", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
        return;
    }

    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&tags=%@&shared=%@&toread=%@", [[AppDelegate sharedDelegate] token], [self.urlTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.titleTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.descriptionTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.tagTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], self.privateSwitch.on ? @"no" : @"yes", self.readSwitch.on ? @"no" : @"yes"]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [delegate setNetworkActivityIndicatorVisible:NO];

                               if (!error) {
                                   [self.modalDelegate closeModal:self];
                                   
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                       [db open];
                                       [db beginTransaction];

                                       FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url = ?" withArgumentsInArray:@[self.urlTextField.text]];
                                       [results next];
                                       
                                       NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                          @"url": self.urlTextField.text,
                                                                          @"title": self.titleTextField.text,
                                                                          @"description": self.descriptionTextField.text,
                                                                          @"tags": self.tagTextField.text,
                                                                          @"unread": @(!self.readSwitch.on),
                                                                          @"private": @(self.privateSwitch.on)
                                                                      }];

                                       if ([results intForColumnIndex:0] > 0) {
                                           [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                           [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private WHERE url=:url" withParameterDictionary:params];
                                           delegate.bookmarksUpdatedMessage = NSLocalizedString(@"Bookmark Updated Message", nil);
                                       }
                                       else {
                                           params[@"created_at"] = [NSDate date];
                                           [mixpanel track:@"Added bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                           [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, tags, created_at) VALUES (:title, :description, :url, :private, :unread, :tags, :created_at);" withParameterDictionary:params];
                                           delegate.bookmarksUpdatedMessage = NSLocalizedString(@"Bookmark Added Message", nil);
                                       }
                                       
                                       delegate.bookmarksUpdated = @(YES);
                                       [db commit];
                                       [db close];
                                   });
                               }
                               self.navigationItem.leftBarButtonItem.enabled = YES;
                               self.navigationItem.rightBarButtonItem.enabled = YES;
                               
                               
    }];

}

@end

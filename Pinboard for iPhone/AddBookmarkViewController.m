//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "NSString+URLEncoding2.h"
#import <ASPinboard/ASPinboard.h>

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
@synthesize autocompleteInProgress;
@synthesize popularTags;
@synthesize recommendedTags;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);

        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        self.urlTextField = [[UITextField alloc] init];
        self.urlTextField.font = font;
        self.urlTextField.delegate = self;
        self.urlTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.urlTextField.placeholder = @"https://pinboard.in/";
        self.urlTextField.keyboardType = UIKeyboardTypeURL;
        self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.urlTextField.text = @"";
        self.previousURLContents = @"";
        
        self.descriptionTextField = [[UITextField alloc] init];
        self.descriptionTextField.font = font;
        self.descriptionTextField.delegate = self;
        self.descriptionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.descriptionTextField.placeholder = @"";
        self.descriptionTextField.text = @"";
        self.descriptionTextField.userInteractionEnabled = NO;

        self.postDescriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, SCREEN.bounds.size.height - 44)];
        self.postDescriptionTextView.font = font;
        self.postDescriptionTextView.text = @"";
        self.postDescriptionTextView.delegate = self;

        self.postDescription = @"";
        
        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.font = font;
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Swipe right to prefill", nil);
        self.titleTextField.text = @"";
        
        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = font;
        self.tagTextField.delegate = self;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.placeholder = NSLocalizedString(@"pinboard .bookmarking", nil);
        self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagTextField.text = @"";
        
        self.markAsRead = @(NO);
        self.loadingTitle = NO;
        self.loadingTags = NO;
        self.suggestedTagsVisible = NO;
        self.autocompleteInProgress = NO;
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
        self.popularTagSuggestions = [[NSMutableArray alloc] init];
        self.previousTagSuggestions = [[NSMutableArray alloc] init];
        self.suggestedTagsPayload = nil;
        self.popularTags = @[];
        self.recommendedTags = @[];

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
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonItemStylePlain target:nil action:nil];

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
    if (indexPath.section == 2) {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.title = NSLocalizedString(@"Description", nil);
        vc.view = [[UIView alloc] initWithFrame:SCREEN.bounds];
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(finishEditingDescription)];
        [vc.view addSubview:self.postDescriptionTextView];
        [self.postDescriptionTextView becomeFirstResponder];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.section == 3 && indexPath.row > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                
                NSString *completion;
                
                if (self.tagCompletions.count > 0) {
                    completion = self.tagCompletions[indexPath.row - 1];
                    
                    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
                    NSInteger index = 1;
                    while (index <= self.tagCompletions.count) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                        index++;
                    }

                    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                    [self.tagCompletions removeAllObjects];
                }
                else if (self.popularTagSuggestions.count > 0) {
                    completion = self.popularTagSuggestions[indexPath.row - 1];
                    [self.popularTagSuggestions removeObjectAtIndex:indexPath.row - 1];
                    
                    unichar space = ' ';
                    if (self.tagTextField.text.length > 0 && [self.tagTextField.text characterAtIndex:self.tagTextField.text.length - 1] != space) {
                        self.tagTextField.text = [NSString stringWithFormat:@"%@ ", self.tagTextField.text];
                    }
                    
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                }
                NSString *stringToReplace = [[self.tagTextField.text componentsSeparatedByString:@" "] lastObject];
                NSRange range = NSMakeRange([self.tagTextField.text length] - [stringToReplace length], [stringToReplace length]);
                [tableView deselectRowAtIndexPath:indexPath animated:YES];

                [self.tableView endUpdates];
                self.tagTextField.text = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", completion]];
            });
        });
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 3) {
        UIView *view = [[UIView alloc] init];
        view.clipsToBounds = YES;
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, 5, 280, [self tableView:tableView heightForFooterInSection:3]);
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Avenir-Medium" size:13];
        label.textColor = HEX(0x4C586AFF);
        label.numberOfLines = 0;
        label.backgroundColor = HEX(0xF7F9FDff);
        label.text = NSLocalizedString(@"Separate tags with spaces", nil);
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3) {
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:13];
        return [NSLocalizedString(@"Separate tags with spaces", nil) sizeWithFont:font constrainedToSize:CGSizeMake(280, CGFLOAT_MAX)].height + 10;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.clipsToBounds = YES;
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(10, 0, 320, 44);
    label.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    label.textColor = HEX(0x4C586AFF);
    label.backgroundColor = HEX(0xF7F9FDff);
    switch (section) {
        case 1:
            label.text = NSLocalizedString(@"Title", nil);
            break;
        case 2:
            label.text = NSLocalizedString(@"Description", nil);
            break;
        case 3:
            label.text = NSLocalizedString(@"Tags", nil);
            break;
        case 4:
            label.text = NSLocalizedString(@"Other", nil);
            break;
        default:
            break;
    }
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 40;
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
    if (!self.autocompleteInProgress) {
        self.autocompleteInProgress = YES;
        NSMutableArray *indexPathsToRemove = [[NSMutableArray alloc] init];
        NSMutableArray *indexPathsToAdd = [[NSMutableArray alloc] init];
        NSMutableArray *newTagCompletions = [NSMutableArray array];
        NSMutableArray *oldTagCompletions = [self.tagCompletions copy];

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
            
            DLog(@"%@ %@", newString, newTagCompletions);
            
            if (self.suggestedTagsVisible) {
                index = 1;
                while (index <= self.popularTagSuggestions.count) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:index inSection:3]];
                    index++;
                }
                
            }
            else {
                for (int i=0; i<oldTagCompletions.count; i++) {
                    if (![newTagCompletions containsObject:oldTagCompletions[i]]) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:1+[self.tagCompletions indexOfObject:oldTagCompletions[i]] inSection:3]];
                    }
                }
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];

                    DLog(@"OLD %d", oldTagCompletions.count);
                    DLog(@"ADD %d", indexPathsToAdd.count);

                    self.suggestedTagsVisible = NO;
                    self.tagCompletions = newTagCompletions;
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];

                    DLog(@"REMOVE %d", indexPathsToRemove.count);
                    DLog(@"NEW %d", newTagCompletions.count);
                    
                    DLog(@"%@ %@", newString, newTagCompletions);

                    [self.tableView endUpdates];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    self.autocompleteInProgress = NO;
                });
            });
        }
        else if (!self.suggestedTagsVisible) {
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

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    
                    if ([indexPathsToRemove count] > 0) {
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                    }
                    
                    if ([indexPathsToAdd count] > 0) {
                        [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                    }
                    
                    self.suggestedTagsVisible = YES;
                    [self.tagCompletions removeAllObjects];
                    
                    [self.tableView endUpdates];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    self.autocompleteInProgress = NO;
                });
            });
        }
        else {
            self.autocompleteInProgress = NO;
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagTextField) {
        if (textField.text.length > 0 && [textField.text characterAtIndex:textField.text.length-1] == ' ' && [string isEqualToString:@" "]) {
            return NO;
        }
        else {
            [self searchUpdatedWithRange:range andString:string];
        }
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
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.enabled = YES;
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    
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
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    self.descriptionTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 280, 31);
                    self.descriptionTextField.text = self.postDescription;
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
                    cell.textLabel.text = NSLocalizedString(@"Set as private?", nil);
                    self.privateSwitch = [[PPSwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.privateSwitch.frame.size;
                    self.privateSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateSwitch.on = self.setAsPrivate.boolValue;
                    [self.privateSwitch addTarget:self action:@selector(privateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateSwitch;
                }
                else if (indexPath.row == 1) {
                    cell.textLabel.text = NSLocalizedString(@"Mark as read?", nil);
                    self.readSwitch = [[PPSwitch alloc] init];
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
}

- (void)readSwitchChanged:(id)sender {
    self.markAsRead = @(self.readSwitch.on);
}

- (void)urlTextFieldDidChange:(NSNotification *)notification {
    if ([UIPasteboard generalPasteboard].string == self.urlTextField.text) {
        self.suggestedTagsPayload = nil;
        [self prefillTitleAndForceUpdate:NO];
    }
}

- (void)handleTagSuggestions {
    if (self.tagCompletions.count == 0) {
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
    
        NSArray *existingTags = [tagText componentsSeparatedByString:@" "];
        
        for (id tag in self.popularTags) {
            if (![existingTags containsObject:tag]) {
                [newPopularTagSuggestions addObject:tag];
            }
        }
        for (id tag in self.recommendedTags) {
            if (![existingTags containsObject:tag] && ![self.popularTags containsObject:tag]) {
                [newPopularTagSuggestions addObject:tag];
            }
        }
        [newPopularTagSuggestions filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF MATCHES '^[ ]?$'"]];
        
        if (newPopularTagSuggestions.count > 0) {
            if (self.tagTextField.text.length > 0 && [self.tagTextField.text characterAtIndex:self.tagTextField.text.length-1] != ' ') {
                self.tagTextField.text = [NSString stringWithFormat:@"%@ ", self.tagTextField.text];
            }
        }
        
        index = 1;
        while (index <= newPopularTagSuggestions.count) {
            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:3]];
            index++;
        }
        DLog(@"%d", self.popularTagSuggestions.count);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                
                self.popularTagSuggestions = newPopularTagSuggestions;
                self.suggestedTagsVisible = YES;
                
                [self.tableView endUpdates];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                
                [self.tagTextField becomeFirstResponder];
            });
        });
    }
}

- (void)prefillPopularTags {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    BOOL shouldPrefillTags = !self.loadingTags
        && self.suggestedTagsPayload == nil
        && [[UIApplication sharedApplication] canOpenURL:url]
        && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTags) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                self.loadingTags = YES;
                [self.tableView endUpdates];
            });
        });

        ASPinboard *pinboard = [ASPinboard sharedInstance];
        [pinboard tagSuggestionsForURL:self.urlTextField.text
                               success:^(NSArray *popular, NSArray *recommended) {
                                   self.popularTags = popular;
                                   self.recommendedTags = recommended;
                                   [self handleTagSuggestions];

                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self.tableView beginUpdates];
                                           [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                                           self.loadingTags = NO;
                                           [self.tableView endUpdates];
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
                                                   self.postDescription = description;
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
        WCAlertView *alert = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"You can't add a bookmark without a URL or title.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
        return;
    }

    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard addBookmarkWithURL:self.urlTextField.text
                           title:self.titleTextField.text
                     description:self.postDescription
                            tags:self.tagTextField.text
                          shared:!self.privateSwitch.on
                          unread:!self.readSwitch.on
                         success:^{
                             [self.modalDelegate closeModal:self];

                             FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                             [db open];
                             [db beginTransaction];
                             
                             FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url = ?" withArgumentsInArray:@[self.urlTextField.text]];
                             [results next];
                             
                             UILocalNotification *notification = [[UILocalNotification alloc] init];
                             notification.alertAction = @"Open Pushpin";
                             notification.userInfo = @{@"success": @YES, @"updated": @YES};
                             
                             NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                            @"url": self.urlTextField.text,
                                                            @"title": self.titleTextField.text,
                                                            @"description": self.postDescription,
                                                            @"tags": self.tagTextField.text,
                                                            @"unread": @(!self.readSwitch.on),
                                                            @"private": @(self.privateSwitch.on)
                                                            }];
                             
                             if ([results intForColumnIndex:0] > 0) {
                                 [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                 [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private WHERE url=:url" withParameterDictionary:params];
                                 notification.alertBody = NSLocalizedString(@"Your bookmark was updated.", nil);
                             }
                             else {
                                 params[@"created_at"] = [NSDate date];
                                 [mixpanel track:@"Added bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                 [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, tags, created_at) VALUES (:title, :description, :url, :private, :unread, :tags, :created_at);" withParameterDictionary:params];
                                 notification.alertBody = NSLocalizedString(@"Your bookmark was added.", nil);
                             }
                             [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                             
                             [db commit];
                             [db close];
                             self.navigationItem.leftBarButtonItem.enabled = YES;
                             self.navigationItem.rightBarButtonItem.enabled = YES;
                             
                         }
                         failure:^(NSError *error) {
                             self.navigationItem.leftBarButtonItem.enabled = YES;
                             self.navigationItem.rightBarButtonItem.enabled = YES;
                             WCAlertView *alert = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"There was an error adding your bookmark.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                             [alert show];
                         }];
}

+ (UINavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];
    
    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark", nil);
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    else {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark", nil);
    }
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:delegate action:@selector(closeModal:)];

    if (bookmark[@"title"]) {
        addBookmarkViewController.titleTextField.text = bookmark[@"title"];
    }
    
    if (bookmark[@"url"]) {
        addBookmarkViewController.urlTextField.text = bookmark[@"url"];
        
        if (isUpdate.boolValue) {
            addBookmarkViewController.urlTextField.enabled = NO;
        }
    }
    
    if (bookmark[@"tags"]) {
        addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    }
    
    if (bookmark[@"description"]) {
        addBookmarkViewController.postDescription = bookmark[@"description"];
        addBookmarkViewController.postDescriptionTextView.text = bookmark[@"description"];
        addBookmarkViewController.descriptionTextField.text = bookmark[@"description"];
    }
    
    if (delegate) {
        addBookmarkViewController.modalDelegate = delegate;
    }
    
    if (callback) {
        addBookmarkViewController.callback = callback;
    }
    
    if (bookmark[@"private"]) {
        addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    }
    else {
        addBookmarkViewController.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
    }
    
    if (bookmark[@"unread"]) {
        addBookmarkViewController.markAsRead = @(!([bookmark[@"unread"] boolValue]));
    }
    else {
        addBookmarkViewController.markAsRead = [[AppDelegate sharedDelegate] readByDefault];
    }
    
    return addBookmarkViewNavigationController;
}

#pragma mark Text View Delegate

- (void)finishEditingDescription {
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.postDescription = textView.text;
}

@end


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
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "PPCoreGraphics.h"
#import "UIApplication+AppDimensions.h"
#import "UIApplication+Additions.h"
#import "UITableView+Additions.h"
#import "PPNavigationController.h"

static NSInteger kAddBookmarkViewControllerTagCompletionOffset = 4;

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
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width, [UIApplication currentSize].height)];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.postDescription = @"";
        
        UIFont *font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
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
        
        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.font = font;
        self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Swipe right to prefill", nil);
        self.titleTextField.text = @"";
        
        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = font;
        self.tagTextField.delegate = self;
        self.tagTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
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
        self.tagDescriptions = [NSMutableDictionary dictionary];
        self.tagCounts = [NSMutableDictionary dictionary];
        
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.postDescriptionTextView) {
        UIFont *font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
        BOOL isIPad = [UIApplication isIPad];
        CGFloat offset;
        if (isIPad) {
            offset = 75;
        }
        else {
            offset = 225;
        }

        self.postDescriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - offset)];
        self.postDescriptionTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.postDescriptionTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.postDescriptionTextView.font = font;
        self.postDescriptionTextView.text = self.postDescription;
        self.postDescriptionTextView.delegate = self;
    }
}

- (void)handleGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.tagGestureRecognizer) {
        [self prefillPopularTags];
        [self.tagTextField resignFirstResponder];
    }
    else if (gestureRecognizer == self.titleGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.descriptionGestureRecognizer) {
        [self prefillTitleAndForceUpdate:YES];
    }
    else if (gestureRecognizer == self.leftSwipeTagGestureRecognizer) {
        [self.tagTextField resignFirstResponder];

        if (self.popularTagSuggestions.count > 0) {
            if (self.suggestedTagsVisible) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                    for (NSInteger i=0; i<self.popularTagSuggestions.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
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
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.urlTextField];
    [self.postDescriptionTextView resignFirstResponder];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
    else if (section == 0) {
        if (self.suggestedTagsVisible) {
            return kAddBookmarkViewControllerTagCompletionOffset + self.popularTagSuggestions.count;
        }
        else {
            return kAddBookmarkViewControllerTagCompletionOffset + self.tagCompletions.count;
        }
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.title = NSLocalizedString(@"Description", nil);
        vc.view = [[UIView alloc] initWithFrame:SCREEN.bounds];
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(finishEditingDescription)];
        [vc.view addSubview:self.postDescriptionTextView];
        self.postDescriptionTextView.text = self.postDescription;
        [self.navigationController pushViewController:vc animated:YES];
        [self.postDescriptionTextView becomeFirstResponder];
    }
    else if (indexPath.section == 0 && indexPath.row > 3) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *tagText = self.tagTextField.text;
        NSInteger row = indexPath.row;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{            
            NSString *completion;
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];

            if (self.tagCompletions.count > 0) {
                completion = self.tagCompletions[row - kAddBookmarkViewControllerTagCompletionOffset];

                for (NSInteger i=0; i<self.tagCompletions.count; i++) {
                    [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i + kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
                }

                [self.tagCompletions removeAllObjects];
            }
            else if (self.popularTagSuggestions.count > 0) {
                completion = self.popularTagSuggestions[row - kAddBookmarkViewControllerTagCompletionOffset];
                [self.popularTagSuggestions removeObjectAtIndex:(row - kAddBookmarkViewControllerTagCompletionOffset)];
                
                unichar space = ' ';
                if (tagText.length > 0 && [tagText characterAtIndex:tagText.length - 1] != space) {
                    self.tagTextField.text = [NSString stringWithFormat:@"%@ ", tagText];
                }

                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];

                NSString *stringToReplace = [[tagText componentsSeparatedByString:@" "] lastObject];
                NSRange range = NSMakeRange(tagText.length - stringToReplace.length, stringToReplace.length);
                self.tagTextField.text = [tagText stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", completion]];
            });
        });
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if (!self.footerView) {
            self.footerView = [[UIView alloc] init];
            self.footerView.clipsToBounds = YES;
            UILabel *label = [[UILabel alloc] init];
            label.frame = CGRectMake(20, 5, self.tableView.frame.size.width - 40, [self tableView:tableView heightForFooterInSection:0]);
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:13];
            label.textColor = HEX(0x4C586AFF);
            label.numberOfLines = 0;
            label.backgroundColor = HEX(0xF7F9FDff);
            label.text = NSLocalizedString(@"Separate tags with spaces", nil);
            [self.footerView addSubview:label];
        }
        return self.footerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIFont *font = [UIFont fontWithName:[AppDelegate mediumFontName] size:13];
        return [NSLocalizedString(@"Separate tags with spaces", nil) sizeWithFont:font constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 40, CGFLOAT_MAX)].height + 10;
    }
    return 0;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
            
        NSString *tagTextFieldText = self.tagTextField.text;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *indexPathsToRemove = [NSMutableArray array];
            NSMutableArray *indexPathsToAdd = [NSMutableArray array];
            NSMutableArray *newTagCompletions = [NSMutableArray array];
            NSMutableArray *oldTagCompletions = [self.tagCompletions copy];
            
            NSString *newString = [tagTextFieldText stringByReplacingCharactersInRange:range withString:string];
            if (string && newString.length > 0 && [newString characterAtIndex:newString.length-1] != ' ') {
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

                NSString *tag, *count;
                NSInteger index = kAddBookmarkViewControllerTagCompletionOffset;
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
                                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(j+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
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
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
                }

                if (self.suggestedTagsVisible) {
                    for (NSInteger i=0; i<self.popularTagSuggestions.count; i++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    self.suggestedTagsVisible = NO;
                    self.tagCompletions = newTagCompletions;

                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    self.autocompleteInProgress = NO;
                });
            }
            else if (!self.suggestedTagsVisible) {
                for (NSInteger i=0; i<self.tagCompletions.count; i++) {
                    [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
                }

                for (NSInteger i=0; i<self.popularTagSuggestions.count; i++) {
                    [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tagCompletions removeAllObjects];
                    self.suggestedTagsVisible = YES;

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
        });
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
        if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSArray *subviews = cell.contentView.subviews;
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }

    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    cell.textLabel.enabled = YES;
    cell.textLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:16];

    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
    }

    if (indexPath.row < 5) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
    }

    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];

    CGFloat textFieldWidth = tableView.frame.size.width - 2 * tableView.groupedCellMargin - 40;
    if (indexPath.section < 5) {
        CGRect frame = cell.frame;

        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0:
                        cell.imageView.image = [UIImage imageNamed:@"globe"];
                        self.urlTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
                        [cell.contentView addSubview:self.urlTextField];
                        break;
                        
                    case 1:
                        cell.imageView.image = [UIImage imageNamed:@"pencil"];
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            cell.textLabel.text = @"Loading";
                            cell.textLabel.enabled = NO;
                        }
                        else {
                            self.titleTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
                            [cell.contentView addSubview:self.titleTextField];
                        }
                        break;
                        
                    case 2:
                        cell.imageView.image = [UIImage imageNamed:@"picture"];
                        if (self.loadingTitle) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            cell.textLabel.text = @"Loading";
                            cell.textLabel.enabled = NO;
                        }
                        else {
                            cell.selectionStyle = UITableViewCellSelectionStyleGray;
                            self.descriptionTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
                            self.descriptionTextField.placeholder = @"Click to edit description.";
                            self.descriptionTextField.text = self.postDescription;

                            cell.accessoryView = nil;
                            [cell.contentView addSubview:self.descriptionTextField];
                        }
                        break;
                        
                    case 3:
                        cell.imageView.image = [UIImage imageNamed:@"tag"];
                        if (self.loadingTags) {
                            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                            [activity startAnimating];
                            cell.accessoryView = activity;
                            cell.textLabel.text = NSLocalizedString(@"Retrieving popular tags", nil);
                            cell.textLabel.enabled = NO;
                        }
                        else {
                            self.tagTextField.frame = CGRectMake(40, (frame.size.height - 31) / 2.0, textFieldWidth, 31);
                            cell.accessoryView = nil;
                            [cell.contentView addSubview:self.tagTextField];
                        }
                        break;
                        
                    default: {
                        if (self.tagCompletions.count > 0) {
                            NSString *tag = self.tagCompletions[indexPath.row - kAddBookmarkViewControllerTagCompletionOffset];
                            cell.textLabel.text = tag;
                            cell.accessoryView = [[UIImageView alloc] initWithImage:[PPCoreGraphics pillImage:self.tagCounts[tag]]];
                        }
                        else {
                            cell.textLabel.text = self.popularTagSuggestions[indexPath.row - kAddBookmarkViewControllerTagCompletionOffset];
                            cell.detailTextLabel.textColor = HEX(0x96989DFF);
                            cell.detailTextLabel.text = self.tagDescriptions[cell.textLabel.text];
                        }
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        cell.editing = NO;
                        break;
                    }
                }
                break;

            case 1: {
                if (indexPath.row == 0) {
                    cell.textLabel.text = NSLocalizedString(@"Set as private?", nil);
                    self.privateSwitch = [[UISwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.privateSwitch.frame.size;
                    self.privateSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateSwitch.on = self.setAsPrivate.boolValue;
                    [self.privateSwitch addTarget:self action:@selector(privateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateSwitch;
                }
                else if (indexPath.row == 1) {
                    cell.textLabel.text = NSLocalizedString(@"Mark as read?", nil);
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.tagCompletions.count == 0) {
            NSString *tagText = self.tagTextField.text;
            NSMutableArray *indexPathsToRemove = [[NSMutableArray alloc] init];
            NSMutableArray *indexPathsToAdd = [[NSMutableArray alloc] init];
            NSMutableArray *newPopularTagSuggestions = [[NSMutableArray alloc] init];
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            
            NSInteger previousEndIndex;
            if (self.suggestedTagsVisible) {
                previousEndIndex = self.popularTagSuggestions.count;
            }
            else {
                previousEndIndex = self.tagCompletions.count;
            }

            for (NSInteger i=0; i<previousEndIndex; i++) {
                [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:(i + kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
            }
            
            NSArray *existingTags = [tagText componentsSeparatedByString:@" "];
            
            for (id tag in self.popularTags) {
                if (![existingTags containsObject:tag]) {
                    self.tagDescriptions[tag] = @"popular";
                    [newPopularTagSuggestions addObject:tag];
                }
            }
            for (id tag in self.recommendedTags) {
                if (![existingTags containsObject:tag] && ![self.popularTags containsObject:tag]) {
                    self.tagDescriptions[tag] = @"recommended";
                    [newPopularTagSuggestions addObject:tag];
                }
            }
            [newPopularTagSuggestions filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF MATCHES '^[ ]?$'"]];
            
            if (newPopularTagSuggestions.count > 0) {
                if (self.tagTextField.text.length > 0 && [self.tagTextField.text characterAtIndex:self.tagTextField.text.length-1] != ' ') {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tagTextField.text = [NSString stringWithFormat:@"%@ ", self.tagTextField.text];
                    });
                }
            }
            
            for (NSInteger i=0; i<newPopularTagSuggestions.count; i++) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:(i+kAddBookmarkViewControllerTagCompletionOffset) inSection:0]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                
                self.popularTagSuggestions = newPopularTagSuggestions;
                self.suggestedTagsVisible = YES;
                
                [self.tableView endUpdates];
            });
        }
    });
}

- (void)prefillPopularTags {
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    BOOL shouldPrefillTags = !self.loadingTags
        && self.suggestedTagsPayload == nil
        && [[UIApplication sharedApplication] canOpenURL:url]
        && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]);
    if (shouldPrefillTags) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kAddBookmarkViewControllerTagCompletionOffset - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            self.loadingTags = YES;
            [self.tableView endUpdates];
        });

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard tagSuggestionsForURL:self.urlTextField.text
                                   success:^(NSArray *popular, NSArray *recommended) {
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                           self.popularTags = popular;
                                           self.recommendedTags = recommended;
                                           [self handleTagSuggestions];
                                       });
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self.tableView beginUpdates];
                                           [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kAddBookmarkViewControllerTagCompletionOffset - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                                           self.loadingTags = NO;
                                           [self.tableView endUpdates];
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

        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0]];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.alertBody = NSLocalizedString(@"Unable to add bookmark; no connection available.", nil);
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [self.modalDelegate closeModal:self];
            });
        }
        
        if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"You can't add a bookmark without a URL or title.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
            });
            return;
        }
        
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *url = self.urlTextField.text;
        if (!url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.alertBody = NSLocalizedString(@"Unable to add bookmark without a URL.", nil);
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [self.modalDelegate closeModal:self];
            });
            return;
        }
        NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:characterSet];
        NSString *description = [self.postDescription stringByTrimmingCharactersInSet:characterSet];
        NSString *tags = [self.tagTextField.text stringByTrimmingCharactersInSet:characterSet];
        BOOL private = self.privateSwitch.on;
        BOOL unread = !self.readSwitch.on;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard addBookmarkWithURL:url
                                   title:title
                             description:description
                                    tags:tags
                                  shared:!private
                                  unread:unread
                                 success:^{
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                         Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                         FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                         BOOL bookmarkAdded;

                                         [db open];
                                         [db beginTransaction];
                                         
                                         FMResultSet *results = [db executeQuery:@"SELECT hash, COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.urlTextField.text]];
                                         [results next];
                                         
                                         NSString *hash = [results stringForColumnIndex:0];
                                         NSInteger count = [results intForColumnIndex:1];
                                         
                                         NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                @"url": url,
                                                @"title": title,
                                                @"description": description,
                                                @"tags": tags,
                                                @"unread": @(unread),
                                                @"private": @(private),
                                                @"starred": @(NO)
                                            }];

                                         if (count > 0) {
                                             [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(private), @"Read": @(!unread)}];

                                             if (hash && ![hash isEqual:[NSNull null]]) {
                                                 params[@"hash"] = hash;
                                                 [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE hash=:hash" withParameterDictionary:params];
                                                 [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                                                 for (NSString *tagName in [tags componentsSeparatedByString:@" "]) {
                                                     [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                                                     [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                                                 }
                                             }
                                             else {
                                                #warning The bookmark doesn't yet have a hash
                                                 [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, starred=:starred, meta=random() WHERE url=:url" withParameterDictionary:params];
                                             }
                                             bookmarkAdded = NO;
                                         }
                                         else {
                                             params[@"created_at"] = [NSDate date];
                                             [mixpanel track:@"Added bookmark" properties:@{@"Private": @(private), @"Read": @(!unread)}];
                                             [db executeUpdate:@"INSERT INTO bookmark (meta, title, description, url, private, unread, starred, tags, created_at) VALUES (random(), :title, :description, :url, :private, :unread, :starred, :tags, :created_at);" withParameterDictionary:params];

                                             bookmarkAdded = YES;
                                         }
                                         
                                         [db commit];
                                         [db close];
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             UILocalNotification *notification = [[UILocalNotification alloc] init];
                                             if (bookmarkAdded) {
                                                 notification.alertBody = NSLocalizedString(@"Your bookmark was added.", nil);
                                             }
                                             else {
                                                 notification.alertBody = NSLocalizedString(@"Your bookmark was updated.", nil);
                                             }

                                             notification.alertAction = @"Open Pushpin";
                                             notification.userInfo = @{@"success": @YES, @"updated": @YES};
                                             [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                             [self.modalDelegate closeModal:self];
                                         });
                                     });
                                 }
                                 failure:^(NSError *error) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         self.navigationItem.leftBarButtonItem.enabled = YES;
                                         self.navigationItem.rightBarButtonItem.enabled = YES;
                                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:NSLocalizedString(@"There was an error adding your bookmark.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                         [alert show];
                                     });
                                 }];
        });
    });
}

+ (PPNavigationController *)addBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    PPNavigationController *addBookmarkViewNavigationController = [[PPNavigationController alloc] initWithRootViewController:addBookmarkViewController];
    
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
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.postDescription = textView.text;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end

//
//  PPMultipleEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

@import QuartzCore;
@import ASPinboard;
@import FMDB;
@import LHSCategoryCollection;
@import LHSTableViewCells;

#import "PPAppDelegate.h"
#import "PPMultipleEditViewController.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "PPConstants.h"
#import "PPTagEditViewController.h"
#import "PPUtilities.h"

static NSInteger kMultipleEditViewControllerTagIndexOffset = 1;
static NSString *CellIdentifier = @"Cell";

@interface PPMultipleEditViewController ()

@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem;

@property (nonatomic) kPushpinFilterType read;
@property (nonatomic) kPushpinFilterType isPrivate;

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags;
- (void)leftBarButtonTouchUpInside:(id)sender;
- (void)rightBarButtonTouchUpInside:(id)sender;
- (PPMultipleEditSectionType)sectionTypeForSection:(NSInteger)section;
- (PPMultipleEditSectionType)sectionTypeForIndexPath:(NSIndexPath *)indexPath;

@end

@implementation PPMultipleEditViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLayoutSubviews {
    NSDictionary *views = @{@"view": self.tableView,
                            @"guide": self.topLayoutGuide };
    [self.view lhs_addConstraints:@"V:[guide][view]" views:views];
    [self.view lhs_addConstraints:@"H:|[view]|" views:views];
    [self.view layoutIfNeeded];
}

- (id)initWithBookmarks:(NSArray *)bookmarks {
    self = [super init];
    if (self) {
        self.bookmarks = bookmarks;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Multiple Edit", nil);
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.saveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(rightBarButtonTouchUpInside:)];

    self.navigationItem.rightBarButtonItem = self.saveBarButtonItem;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(leftBarButtonTouchUpInside:)];

    self.tagsToAdd = [NSMutableArray array];
    self.tagsToRemove = [NSMutableOrderedSet orderedSet];
    self.deleteTagButtons = [NSMutableDictionary dictionary];
    self.read = kPushpinFilterNone;
    self.isPrivate = kPushpinFilterNone;
    
    self.existingTags = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *bookmark in self.bookmarks) {
        NSString *tags = [PPUtilities stringByTrimmingWhitespace:bookmark[@"tags"]];
        NSMutableArray *tagList = [[tags componentsSeparatedByString:@" "] mutableCopy];
        for (NSString *tag in tagList) {
            if (![tag isEqualToString:@""]) {
                [self.existingTags addObject:tag];
            }
        }
        NSLog(@"%@", self.existingTags);
        //This is because '&' was shown as '&amp;' int existingTags
        NSMutableArray *newArray = [NSMutableArray array];
        for (NSString *input in self.existingTags)
        {
            NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
            [newArray addObject:replacement];
        }
        self.existingTags = newArray;
        
        NSLog(@"%@", self.existingTags);
    }

    [self.existingTags sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    self.bottomConstraint = [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.bottomAnchor];
    [self.view addConstraint:self.bottomConstraint];
    
    UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
    self.tagsToAddTextField = [[UITextField alloc] init];
    self.tagsToAddTextField.font = font;
    self.tagsToAddTextField.delegate = self;
    self.tagsToAddTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.tagsToAddTextField.placeholder = NSLocalizedString(@"Tap to add tags", nil);
    self.tagsToAddTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tagsToAddTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tagsToAddTextField.text = @"";
    self.tagsToAddTextField.userInteractionEnabled = NO;
    self.tagsToAddTextField.translatesAutoresizingMaskIntoConstraints = NO;

    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    self.badgeWrapperView.userInteractionEnabled = NO;

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.existingTags.count > 0) {
        return PPMultipleEditSectionCount;
    } else {
        return PPMultipleEditSectionCount - 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PPMultipleEditSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPMultipleEditSectionExistingTags:
            return self.existingTags.count;
            
        case PPMultipleEditSectionOtherData:
            return 2;

        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.contentView lhs_removeSubviews];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = @"";
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    
    PPMultipleEditSectionType sectionType = [self sectionTypeForIndexPath:indexPath];
    switch (sectionType) {
        case PPMultipleEditSectionAddedTags: {
            NSDictionary *views = @{@"text": self.tagsToAddTextField,
                                    @"badges": self.badgeWrapperView };
            [cell.contentView addSubview:self.tagsToAddTextField];
            [cell.contentView addSubview:self.badgeWrapperView];

            [cell.contentView lhs_addConstraints:@"H:|-12-[text]-12-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-10-[text]" views:views];
            [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:views];
            
            if (self.tagsToAdd.count == 0) {
                self.tagsToAddTextField.hidden = NO;
            } else {
                self.tagsToAddTextField.hidden = YES;
            }
            break;
        }
            
        case PPMultipleEditSectionExistingTags: {
            NSString *tag = self.existingTags[indexPath.row];
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            attributes[NSFontAttributeName] = [PPTheme textLabelFont];
            
            if ([self.tagsToRemove containsObject:tag]) {
                attributes[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                attributes[NSForegroundColorAttributeName] = [UIColor redColor];
            }

            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:tag attributes:attributes];
            break;
        }
            
        case PPMultipleEditSectionOtherData:
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.hidden = NO;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.text = nil;
            
            kPushpinFilterType filter;

            NSString *imageName;
            switch ((PPMultipleEditSectionOtherRowType)indexPath.row) {
                case PPMultipleEditSectionOtherRowPrivate:
                    filter = self.isPrivate;
                    imageName = @"roundbutton-private";
                    
                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → %@", NSLocalizedString(@"Public", nil), NSLocalizedString(@"Private", nil), NSLocalizedString(@"Private", nil)];
                            cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] lhs_imageWithColor:HEX(0xFFAE44FF)]];
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → %@", NSLocalizedString(@"Public", nil), NSLocalizedString(@"Private", nil), NSLocalizedString(@"Public", nil)];
                            cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → No Change", NSLocalizedString(@"Public", nil), NSLocalizedString(@"Private", nil)];
                            cell.textLabel.textColor = [UIColor lightGrayColor];
                            break;
                    }
                    break;
                    
                case PPMultipleEditSectionOtherRowRead:
                    filter = self.read;
                    imageName = @"roundbutton-checkmark";
                    
                    switch (filter) {
                        case kPushpinFilterTrue: {
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → %@", NSLocalizedString(@"Read", nil), NSLocalizedString(@"Unread", nil), NSLocalizedString(@"Read", nil)];
                            cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] lhs_imageWithColor:HEX(0xEF6034FF)]];
                            break;
                        }
                            
                        case kPushpinFilterFalse:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → %@", NSLocalizedString(@"Read", nil), NSLocalizedString(@"Unread", nil), NSLocalizedString(@"Unread", nil)];
                            cell.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] lhs_imageWithColor:HEX(0xD8DDE4FF)]];
                            break;
                            
                        case kPushpinFilterNone:
                            cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@ → No Change", NSLocalizedString(@"Read", nil), NSLocalizedString(@"Unread", nil)];
                            cell.textLabel.textColor = [UIColor lightGrayColor];
                            break;
                    }
                    break;
            }
            
            BOOL showImages = YES;
            if (!showImages) {
                cell.accessoryView = nil;
            }
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PPMultipleEditSectionType sectionType = [self sectionTypeForIndexPath:indexPath];
    switch (sectionType) {
        case PPMultipleEditSectionAddedTags: {
            CGFloat width = self.view.frame.size.width - 20;
            return MAX(44, [self.badgeWrapperView calculateHeightForWidth:width] + 20);
        }
            
        default:
            return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    PPMultipleEditSectionType sectionType = [self sectionTypeForIndexPath:indexPath];
    switch (sectionType) {
        case PPMultipleEditSectionAddedTags: {
            PPTagEditViewController *tagEditViewController = [[PPTagEditViewController alloc] init];
            tagEditViewController.tagDelegate = self;
            tagEditViewController.bookmarkData = @{};
            tagEditViewController.existingTags = [self.tagsToAdd mutableCopy];
            tagEditViewController.presentedFromShareSheet = NO;
            [self.navigationController pushViewController:tagEditViewController animated:YES];
            break;
        }
            
        case PPMultipleEditSectionExistingTags: {
            NSString *tag = self.existingTags[indexPath.row];

            if ([self.tagsToRemove containsObject:tag]) {
                [self.tagsToRemove removeObject:tag];
            } else {
                [self.tagsToRemove addObject:tag];
            }

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
        }
            
        case PPMultipleEditSectionOtherData: {
            switch ((PPMultipleEditSectionOtherRowType)indexPath.row) {
                case PPMultipleEditSectionOtherRowPrivate:
                    switch (self.isPrivate) {
                        case kPushpinFilterTrue:
                            self.isPrivate = kPushpinFilterFalse;
                            break;
                            
                        case kPushpinFilterFalse:
                            self.isPrivate = kPushpinFilterNone;
                            break;
                            
                        case kPushpinFilterNone:
                            self.isPrivate = kPushpinFilterTrue;
                            break;
                    }
                    
                    break;
                    
                case PPMultipleEditSectionOtherRowRead:
                    switch (self.read) {
                        case kPushpinFilterTrue:
                            self.read = kPushpinFilterFalse;
                            break;
                            
                        case kPushpinFilterFalse:
                            self.read = kPushpinFilterNone;
                            break;
                            
                        case kPushpinFilterNone:
                            self.read = kPushpinFilterTrue;
                            break;
                    }
                    
                    break;
            }
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    PPMultipleEditSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPMultipleEditSectionExistingTags:
            return NSLocalizedString(@"Tap a tag to toggle it for deletion.", nil);
            
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    PPMultipleEditSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPMultipleEditSectionAddedTags:
            return NSLocalizedString(@"Tags to Add", nil);

        case PPMultipleEditSectionExistingTags:
            return NSLocalizedString(@"Existing Tags", nil);
            
        case PPMultipleEditSectionOtherData:
            return NSLocalizedString(@"Additional Attributes", nil);
            
        default:
            return nil;
    }
}

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags {
    NSMutableArray *badges = [NSMutableArray array];
    for (NSString *tag in self.tagsToAdd) {
        if (![tag isEqualToString:@""]) {
            [badges addObject:@{ @"type": @"tag", @"tag": tag }];
        }
    }
    
    PPBadgeWrapperView *wrapper = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme staticBadgeFontSize]) }];
    wrapper.userInteractionEnabled = NO;
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    return wrapper;
}

#pragma mark - PPTagEditing

- (void)tagEditViewControllerDidUpdateTags:(PPTagEditViewController *)tagEditViewController {
    self.tagsToAdd = [tagEditViewController.existingTags mutableCopy];
    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:PPMultipleEditSectionAddedTags]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)deleteTagButtonTouchUpInside:(id)sender {
    NSString *tag = [[self.deleteTagButtons allKeysForObject:sender] firstObject];
    [self.tagsToRemove addObject:tag];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.existingTags indexOfObject:tag] inSection:PPMultipleEditSectionAddedTags]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
#warning XXX
}

- (void)leftBarButtonTouchUpInside:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightBarButtonTouchUpInside:(id)sender {
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    self.navigationItem.rightBarButtonItem = activityBarButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [activity startAnimating];

    NSMutableArray *updatedBookmarks = [NSMutableArray array];
    for (NSDictionary *bookmark in self.bookmarks) {
        NSString *tags = [PPUtilities stringByTrimmingWhitespace:bookmark[@"tags"]];
        NSMutableArray *tagList = [[tags componentsSeparatedByString:@" "] mutableCopy];
        NSMutableArray *newArray = [NSMutableArray array];
        for (NSString *input in tagList)
        {
            NSString *replacement = [input stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
            [newArray addObject:replacement];
        }
        tagList = newArray;
        for (NSString *tag in self.tagsToRemove) {
            [tagList removeObject:tag];
        }

        for (NSString *tag in self.tagsToAdd) {
            [tagList addObject:tag];
        }
        
        NSMutableDictionary *updatedBookmark = [bookmark mutableCopy];
        
        switch (self.isPrivate) {
            case kPushpinFilterFalse:
                updatedBookmark[@"private"] = @(NO);
                break;
                
            case kPushpinFilterTrue:
                updatedBookmark[@"private"] = @(YES);
                break;

            default: break;
        }

        switch (self.read) {
            case kPushpinFilterFalse:
                updatedBookmark[@"unread"] = @(YES);
                break;
                
            case kPushpinFilterTrue:
                updatedBookmark[@"unread"] = @(NO);
                break;

            default: break;
        }
        
        NSString *updatedTags = [PPUtilities stringByTrimmingWhitespace:[tagList componentsJoinedByString:@" "]];
        updatedBookmark[@"tags"] = updatedTags;
        [updatedBookmarks addObject:updatedBookmark];
    }

    ASPinboard *pinboard = [ASPinboard sharedInstance];

    __block NSInteger succeeded = 0;
    dispatch_group_t group = dispatch_group_create();
    for (NSDictionary *bookmark in updatedBookmarks) {
        dispatch_group_enter(group);
        [pinboard addBookmarkWithURL:bookmark[@"url"]
                               title:bookmark[@"title"]
                         description:bookmark[@"description"]
                                tags:bookmark[@"tags"]
                              shared:![bookmark[@"private"] boolValue]
                              unread:[bookmark[@"unread"] boolValue]
                             success:^{
                                 succeeded++;
                                 dispatch_group_leave(group);
                             }
                             failure:^(NSError *error) {
                                 dispatch_group_leave(group);
                             }];
    }

    NSInteger total = updatedBookmarks.count;
    NSInteger failed = total - succeeded;
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (succeeded > 0) {
            [self.parentViewController dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkEventNotificationName
                                                                    object:nil
                                                                  userInfo:nil];
            }];
        } else {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            self.navigationItem.rightBarButtonItem = self.saveBarButtonItem;
        }
    });
}

- (PPMultipleEditSectionType)sectionTypeForSection:(NSInteger)section {
    NSInteger numSectionsSkipped = 0;
    NSInteger numSectionsNotSkipped = 0;

    while (YES) {
        if (numSectionsNotSkipped == section) {
            break;
        }
        
        numSectionsNotSkipped++;

        if (self.existingTags.count == 0) {
            numSectionsSkipped++;
        } else {
            if (numSectionsNotSkipped == section) {
                break;
            }
            
            numSectionsNotSkipped++;
        }

        break;
    }

    return (PPMultipleEditSectionType)(section + numSectionsSkipped);
}

- (PPMultipleEditSectionType)sectionTypeForIndexPath:(NSIndexPath *)indexPath {
    return [self sectionTypeForSection:indexPath.section];
}

@end

//
//  PPMultipleEditViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

@import QuartzCore;

#import "PPAppDelegate.h"
#import "PPMultipleEditViewController.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "PPConstants.h"
#import "PPTagEditViewController.h"
#import "UIAlertController+LHSAdditions.h"

#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <ASPinboard/ASPinboard.h>

static NSInteger kMultipleEditViewControllerTagIndexOffset = 1;
static NSString *CellIdentifier = @"Cell";

@interface PPMultipleEditViewController ()

@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem;

- (PPBadgeWrapperView *)badgeWrapperViewForCurrentTags;
- (void)leftBarButtonTouchUpInside:(id)sender;
- (void)rightBarButtonTouchUpInside:(id)sender;

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
    
    self.existingTags = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *bookmark in self.bookmarks) {
        NSString *tags = [PPUtilities stringByTrimmingWhitespace:bookmark[@"tags"]];
        NSMutableArray *tagList = [[tags componentsSeparatedByString:@" "] mutableCopy];
        for (NSString *tag in tagList) {
            if (![tag isEqualToString:@""]) {
                [self.existingTags addObject:tag];
            }
        }
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
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
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
    }
    else {
        return PPMultipleEditSectionCount - 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPMultipleEditSectionType)section) {
        case PPMultipleEditSectionAddedTags:
            return 1;
            
        case PPMultipleEditSectionExistingTags:
            return self.existingTags.count;
            
        case PPMultipleEditSectionDeletedTags:
            return self.tagsToRemove.count;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.contentView lhs_removeSubviews];
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = @"";
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.font = [PPTheme detailLabelFont];

    switch ((PPMultipleEditSectionType)indexPath.section) {
        case PPMultipleEditSectionAddedTags: {
            NSDictionary *views = @{@"text": self.tagsToAddTextField,
                                    @"badges": self.badgeWrapperView };
            [cell.contentView addSubview:self.tagsToAddTextField];
            [cell.contentView addSubview:self.badgeWrapperView];

            [cell.contentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-10-[text]" views:views];
            [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:views];
            
            if (self.tagsToAdd.count == 0) {
                self.tagsToAddTextField.hidden = NO;
            }
            else {
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
                attributes[NSForegroundColorAttributeName] = [UIColor grayColor];
            }

            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:tag attributes:attributes];
            break;
        }
            
        case PPMultipleEditSectionDeletedTags: {
            NSString *tag = self.tagsToRemove[indexPath.row];
            break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ((PPMultipleEditSectionType)indexPath.section) {
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
    
    switch ((PPMultipleEditSectionType)indexPath.section) {
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
            }
            else {
                [self.tagsToRemove addObject:tag];
            }

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ((PPMultipleEditSectionType)section) {
        case PPMultipleEditSectionExistingTags:
            return NSLocalizedString(@"Tap a tag to toggle it for deletion.", nil);
            
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((PPMultipleEditSectionType)section) {
        case PPMultipleEditSectionAddedTags:
            return NSLocalizedString(@"Tags to Add", nil);

        case PPMultipleEditSectionExistingTags:
            return NSLocalizedString(@"Existing Tags", nil);

        case PPMultipleEditSectionDeletedTags:
            return NSLocalizedString(@"Tags to Remove", nil);
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
#warning xxx
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
        for (NSString *tag in self.tagsToRemove) {
            [tagList removeObject:tag];
        }

        for (NSString *tag in self.tagsToAdd) {
            [tagList addObject:tag];
        }
        
        NSMutableDictionary *updatedBookmark = [bookmark mutableCopy];
        
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
        }
        else {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            self.navigationItem.rightBarButtonItem = self.saveBarButtonItem;
        }
    });
}

@end

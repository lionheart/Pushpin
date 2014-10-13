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

#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>

static NSInteger kMultipleEditViewControllerTagIndexOffset = 1;
static NSString *CellIdentifier = @"Cell";

@interface PPMultipleEditViewController ()

@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(rightBarButtonTouchUpInside:)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(leftBarButtonTouchUpInside:)];

    self.tagsToAdd = [NSMutableArray array];
    self.tagsToRemove = [NSMutableOrderedSet orderedSet];
    self.deleteTagButtons = [NSMutableDictionary dictionary];
    
    self.existingTags = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *bookmark in self.bookmarks) {
        NSString *tags = bookmark[@"tags"];
        NSMutableArray *tagList = [[tags componentsSeparatedByString:@" "] mutableCopy];
        for (NSString *tag in tagList) {
            [self.existingTags addObject:tag];
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
    self.tagsToAddTextField.placeholder = NSLocalizedString(@"Tap here to add tags", nil);
    self.tagsToAddTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tagsToAddTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tagsToAddTextField.text = @"";
    self.tagsToAddTextField.translatesAutoresizingMaskIntoConstraints = NO;

    self.badgeWrapperView = [self badgeWrapperViewForCurrentTags];
    self.badgeWrapperView.userInteractionEnabled = NO;

    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PPMultipleEditSectionCount;
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

            [cell.contentView lhs_addConstraints:@"H:|-14-[text]-10-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-10-[text]" views:views];
            [cell.contentView lhs_addConstraints:@"H:|-14-[badges]-10-|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|-12-[badges]" views:views];
            
            if (self.existingTags.count == 0) {
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
            else {
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
            CGFloat width = self.view.frame.size.width - 24;
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
            [self.tagsToRemove addObject:tag];
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
        }
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
    
}

@end

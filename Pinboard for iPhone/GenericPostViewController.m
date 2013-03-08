//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "GenericPostViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "RDActionSheet.h"
#import <QuartzCore/QuartzCore.h>

@interface GenericPostViewController ()

@end

@implementation GenericPostViewController

@synthesize postDataSource;
@synthesize processingPosts;

- (void)viewDidLoad {
    self.processingPosts = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [self update];
}

- (void)update {
    self.processingPosts = YES;
    [self.postDataSource updatePosts:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.processingPosts = NO;
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            });
        });
    }];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.processingPosts) {
        [self.postDataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
            if (needsUpdate) {
                [self update];
            }
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.postDataSource numberOfPosts];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12.f];
    
    CGFloat height = 20.0f;
    NSString *title = [self.postDataSource titleForPostAtIndex:indexPath.row];
    NSString *description = [self.postDataSource descriptionForPostAtIndex:indexPath.row];
    NSString *tags = [self.postDataSource tagsForPostAtIndex:indexPath.row];

    height += ceilf([title sizeWithFont:titleFont constrainedToSize:CGSizeMake(320.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    
    if (![description isEqualToString:@""]) {
        height += ceilf([description sizeWithFont:descriptionFont constrainedToSize:CGSizeMake(320.f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![tags isEqualToString:@""]) {
        height += ceilf([tags sizeWithFont:tagsFont constrainedToSize:CGSizeMake(320.f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }

    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }

    NSAttributedString *string;

    string = [self attributedStringForPostAtIndexPath:indexPath];

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    [cell.textView setText:string];
    
    for (id subview in [cell.contentView subviews]) {
        if (![subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
    }

    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }
    
    CGFloat height = [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 320.f, height);
    gradient.colors = @[(id)[HEX(0xFAFBFEff) CGColor], (id)[HEX(0xF2F6F9ff) CGColor]];
    gradient.name = @"Gradient";
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
    cell.backgroundView = backgroundView;
    [cell.backgroundView.layer addSublayer:gradient];

    CAGradientLayer *selectedGradient = [CAGradientLayer layer];
    selectedGradient.frame = CGRectMake(0, 0, 320.f, height);
    selectedGradient.colors = @[(id)[HEX(0xE1E4ECff) CGColor], (id)[HEX(0xF3F5F9ff) CGColor]];
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
    cell.selectedBackgroundView = selectedBackgroundView;
    [cell.selectedBackgroundView.layer addSublayer:selectedGradient];

    BOOL isPrivate = [self.postDataSource isPostAtIndexPrivate:indexPath.row];
    if (isPrivate) {
        UIImageView *lockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-right-lock"]];
        lockImageView.frame = CGRectMake(302.f, 0, 18.f, 19.f);
        [cell.contentView addSubview:lockImageView];
    }
    
    BOOL isStarred = YES;
    if (isStarred) {
        UIImageView *starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-left-star"]];
        starImageView.frame = CGRectMake(0, 0, 18.f, 19.f);
        [cell.contentView addSubview:starImageView];
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    RDActionSheet *actionSheet = [[RDActionSheet alloc] initWithTitle:@"Yo" cancelButtonTitle:@"Yo" primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [actionSheet showFrom:self.view];
}

#pragma mark - Table view delegate

- (NSMutableAttributedString *)attributedStringForPostAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12.f];

    NSString *title = [self.postDataSource titleForPostAtIndex:indexPath.row];
    NSString *description = [self.postDataSource descriptionForPostAtIndex:indexPath.row];
    NSString *tags = [self.postDataSource tagsForPostAtIndex:indexPath.row];
    BOOL isRead = [self.postDataSource isPostAtIndexRead:indexPath.row];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = [self.postDataSource rangeForTitleForPostAtIndex:indexPath.row];

    NSRange descriptionRange = [self.postDataSource rangeForDescriptionForPostAtIndex:indexPath.row];
    if (descriptionRange.location != NSNotFound) {
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange = [self.postDataSource rangeForTagsForPostAtIndex:indexPath.row];
    BOOL hasTags = tagRange.location != NSNotFound;
    if (hasTags) {
        [content appendString:[NSString stringWithFormat:@"\n%@", tags]];
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setFont:descriptionFont range:descriptionRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    
    if (isRead) {
        [attributedString setTextColor:HEX(0x96989Dff) range:titleRange];
        [attributedString setTextColor:HEX(0x96989Dff) range:descriptionRange];
    }
    else {
        [attributedString setTextColor:HEX(0x353840ff) range:titleRange];
        [attributedString setTextColor:HEX(0x696F78ff) range:descriptionRange];
    }

    if (hasTags) {
        [attributedString setTextColor:HEX(0xA5A9B2ff) range:tagRange];
        [attributedString setFont:tagsFont range:tagRange];
    }
    
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
}

@end

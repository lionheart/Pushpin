//
//  PPDisplaySettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "PPDisplaySettingsViewController.h"
#import "PPDefaultFeedViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import <TextExpander/SMTEDelegateController.h>

#import "UITableViewCellValue1.h"
#import "UITableViewCellSubtitle.h"

static NSString *CellIdentifier = @"Cell";
static NSString *ChoiceCellIdentifier = @"ChoiceCell";
static NSString *SubtitleCellIdentifier = @"SubtitleCell";

@interface PPDisplaySettingsViewController ()

@property (nonatomic) NSUInteger TESnippetCount;
@property (nonatomic) BOOL TEAvailable;

@end

@implementation PPDisplaySettingsViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Advanced Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:ChoiceCellIdentifier];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUInteger count = self.TESnippetCount;
    self.TEAvailable = [SMTEDelegateController textExpanderTouchHasGetSnippetsCallbackURL];

    [SMTEDelegateController expansionStatusForceLoad:NO
                                        snippetCount:&count
                                            loadDate:nil
                                               error:nil];

    self.TESnippetCount = count;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.TEAvailable) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;

        case 1:
            return 1;

        case 2:
            return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(CGRectGetWidth(self.tableView.frame), CGFLOAT_MAX);

    NSDictionary *titleAttributes = @{NSFontAttributeName: [PPTheme textLabelFont]};
    NSDictionary *descriptionAttributes = @{NSFontAttributeName: [PPTheme detailLabelFont]};
    CGFloat titleHeight = [@"" boundingRectWithSize:size
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:titleAttributes
                                            context:nil].size.height;
    if (![indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:2]]) {
        return titleHeight + 20;
    }
    
    CGFloat detailHeight = [@"" boundingRectWithSize:size
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:descriptionAttributes
                                             context:nil].size.height;

    return titleHeight + detailHeight + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    CGSize size;
    CGSize switchSize;
    
    switch (indexPath.section) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.accessoryView = nil;

            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Dim read bookmarks", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.dimReadPostsSwitch = [[UISwitch alloc] init];
                    switchSize = self.dimReadPostsSwitch.frame.size;
                    self.dimReadPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.dimReadPostsSwitch.on = [AppDelegate sharedDelegate].dimReadPosts;
                    [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.dimReadPostsSwitch;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Double tap to edit", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.doubleTapToEditSwitch = [[UISwitch alloc] init];
                    switchSize = self.doubleTapToEditSwitch.frame.size;
                    self.doubleTapToEditSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.doubleTapToEditSwitch.on = [AppDelegate sharedDelegate].doubleTapToEdit;
                    [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.doubleTapToEditSwitch;
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Auto mark as read", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.markReadSwitch = [[UISwitch alloc] init];
                    switchSize = self.markReadSwitch.frame.size;
                    self.markReadSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.markReadSwitch.on = [AppDelegate sharedDelegate].markReadPosts;
                    [self.markReadSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.markReadSwitch;
                    break;
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect text", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.autoCorrectionSwitch = [[UISwitch alloc] init];
                    switchSize = self.autoCorrectionSwitch.frame.size;
                    self.autoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.autoCorrectionSwitch.on = [AppDelegate sharedDelegate].enableAutoCorrect;
                    [self.autoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.autoCorrectionSwitch;
                    break;
                case 4:
                    cell.textLabel.text = NSLocalizedString(@"Autocapitalize text", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.autoCapitalizationSwitch = [[UISwitch alloc] init];
                    switchSize = self.autoCapitalizationSwitch.frame.size;
                    self.autoCapitalizationSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.autoCapitalizationSwitch.on = [AppDelegate sharedDelegate].enableAutoCapitalize;
                    [self.autoCapitalizationSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.autoCapitalizationSwitch;
                    break;
                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Compress bookmark list", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.compressPostsSwitch = [[UISwitch alloc] init];
                    switchSize = self.compressPostsSwitch.frame.size;
                    self.compressPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.compressPostsSwitch.on = [AppDelegate sharedDelegate].compressPosts;
                    [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.compressPostsSwitch;
                    break;

                default:
                    break;
            }
            break;

        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.accessoryView = nil;

            cell.textLabel.text = NSLocalizedString(@"Default feed", nil);
            cell.detailTextLabel.text = [AppDelegate sharedDelegate].defaultFeedDescription;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;

        case 2: {
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.accessoryView = nil;

            cell.textLabel.text = @"Update TextExpander Snippets";

            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterShortStyle;

            if (self.TESnippetCount == 1) {
                cell.detailTextLabel.text = @"1 snippet";
            }
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld snippets", (long)self.TESnippetCount];
            }

            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    // Show the default feed selection
                    PPDefaultFeedViewController *vc = [[PPDefaultFeedViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                }
            }
            break;

        case 2: {
            SMTEDelegateController *teDelegate = [[SMTEDelegateController alloc] init];
            teDelegate.getSnippetsScheme = @"pushpin";
            teDelegate.clientAppName = @"Pushpin";
            [teDelegate getSnippets];
            break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"You can also toggle this by pinching in or out when viewing bookmarks.", nil);
    }
    else if (section == 1) {
        return NSLocalizedString(@"The selected default feed will be shown immediately after starting the app.", nil);
    }
    
    return @"";
}

- (void)switchChangedValue:(id)sender {
    if (sender == self.compressPostsSwitch) {
        [[AppDelegate sharedDelegate] setCompressPosts:self.compressPostsSwitch.on];
    }
    else if (sender == self.doubleTapToEditSwitch) {
        [[AppDelegate sharedDelegate] setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    }
    else if (sender == self.dimReadPostsSwitch) {
        [[AppDelegate sharedDelegate] setDimReadPosts:self.dimReadPostsSwitch.on];
    }
    else if (sender == self.markReadSwitch) {
        [[AppDelegate sharedDelegate] setMarkReadPosts:self.markReadSwitch.on];
    }
    else if (sender == self.autoCorrectionSwitch) {
        [[AppDelegate sharedDelegate] setEnableAutoCorrect:self.autoCorrectionSwitch.on];
    }
    else if (sender == self.autoCapitalizationSwitch) {
        [[AppDelegate sharedDelegate] setEnableAutoCapitalize:self.autoCapitalizationSwitch.on];
    }
    
    if (sender == self.compressPostsSwitch) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkCompressSettingUpdate object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    }
}

@end

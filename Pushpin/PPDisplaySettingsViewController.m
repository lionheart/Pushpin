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

@property (nonatomic, retain) UISwitch *privateByDefaultSwitch;
@property (nonatomic, retain) UISwitch *readByDefaultSwitch;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;

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
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionDisplaySettings:
            return PPRowCountDisplaySettings;

        case PPSectionBrowseSettings:
            return PPRowCountBrowse;

        case PPSectionTextExpanderSettings:
            return 1;
    }
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
    
    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionDisplaySettings:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
            cell.accessoryView = nil;

            switch ((PPEditSettingsRowType)indexPath.row) {
                case PPEditDefaultToPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.privateByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateByDefaultSwitch.on = [AppDelegate sharedDelegate].privateByDefault;
                    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateByDefaultSwitch;
                    break;
                    
                case PPEditDefaultToRead:
                    cell.textLabel.text = NSLocalizedString(@"Read by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.readByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.readByDefaultSwitch.frame.size;
                    self.readByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.readByDefaultSwitch.on = [AppDelegate sharedDelegate].readByDefault;
                    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.readByDefaultSwitch;
                    break;

                case PPEditDimReadRow:
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

                case PPEditDoubleTapRow:
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

                case PPEditAutoMarkAsReadRow:
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

                case PPEditAutocorrecTextRow:
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

                case PPEditAutocapitalizeRow:
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
            }
            break;

        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseCompressRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];

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
                    
                case PPBrowseDefaultFeedRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.accessoryView = nil;
                    
                    cell.textLabel.text = NSLocalizedString(@"Default feed", nil);
                    cell.detailTextLabel.text = [AppDelegate sharedDelegate].defaultFeedDescription;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;

        case PPSectionTextExpanderSettings: {
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
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseDefaultFeedRow: {
                    // Show the default feed selection
                    PPDefaultFeedViewController *vc = [[PPDefaultFeedViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                }
                    
                default:
                    break;
            }
            break;

        case PPSectionTextExpanderSettings: {
            SMTEDelegateController *teDelegate = [[SMTEDelegateController alloc] init];
            teDelegate.getSnippetsScheme = @"pushpin";
            teDelegate.clientAppName = @"Pushpin";
            [teDelegate getSnippets];
            break;
        }
            
        case PPSectionDisplaySettings:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionBrowseSettings:
            return @"Browsing";
            
        case PPSectionDisplaySettings:
            return @"Editing";
            
        case PPSectionTextExpanderSettings:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionDisplaySettings:
            return nil;
            
        case PPSectionBrowseSettings:
            return NSLocalizedString(@"The selected default feed will be shown immediately after starting the app.", nil);
            
        case PPSectionTextExpanderSettings:
            return nil;
    }
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

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setPrivateByDefault:self.privateByDefaultSwitch.on];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setReadByDefault:self.readByDefaultSwitch.on];
}

@end

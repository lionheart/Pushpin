//
//  PPDisplaySettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

@import QuartzCore;

#import "PPAppDelegate.h"
#import "PPDisplaySettingsViewController.h"
#import "PPDefaultFeedViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"

#import "UITableViewCellValue1.h"
#import "UITableViewCellSubtitle.h"

#import <FMDB/FMDatabase.h>
#import <TextExpander/SMTEDelegateController.h>

static NSString *CellIdentifier = @"Cell";
static NSString *ChoiceCellIdentifier = @"ChoiceCell";
static NSString *SubtitleCellIdentifier = @"SubtitleCell";

@interface PPDisplaySettingsViewController ()

@property (nonatomic) NSUInteger TESnippetCount;
@property (nonatomic) BOOL TEAvailable;

@property (nonatomic, retain) UISwitch *privateByDefaultSwitch;
@property (nonatomic, retain) UISwitch *readByDefaultSwitch;
@property (nonatomic, retain) UISwitch *dimReadPostsSwitch;
@property (nonatomic, retain) UISwitch *compressPostsSwitch;
@property (nonatomic, retain) UISwitch *doubleTapToEditSwitch;
@property (nonatomic, retain) UISwitch *markReadSwitch;
@property (nonatomic, retain) UISwitch *autoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *autoCapitalizationSwitch;
@property (nonatomic, retain) UISwitch *onlyPromptToAddOnceSwitch;
@property (nonatomic, retain) UISwitch *alwaysShowAlertSwitch;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)switchChangedValue:(id)sender;

- (void)updateSnippetData;

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
    
    self.privateByDefaultSwitch = [[UISwitch alloc] init];
    self.privateByDefaultSwitch.on = [PPAppDelegate sharedDelegate].privateByDefault;
    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.readByDefaultSwitch = [[UISwitch alloc] init];
    self.readByDefaultSwitch.on = [PPAppDelegate sharedDelegate].readByDefault;
    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.autoCapitalizationSwitch = [[UISwitch alloc] init];
    self.autoCapitalizationSwitch.on = [PPAppDelegate sharedDelegate].enableAutoCapitalize;
    [self.autoCapitalizationSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.compressPostsSwitch = [[UISwitch alloc] init];
    self.compressPostsSwitch.on = [PPAppDelegate sharedDelegate].compressPosts;
    [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.markReadSwitch = [[UISwitch alloc] init];
    self.markReadSwitch.on = [PPAppDelegate sharedDelegate].markReadPosts;
    [self.markReadSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.doubleTapToEditSwitch = [[UISwitch alloc] init];
    self.doubleTapToEditSwitch.on = [PPAppDelegate sharedDelegate].doubleTapToEdit;
    [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.autoCorrectionSwitch = [[UISwitch alloc] init];
    self.autoCorrectionSwitch.on = [PPAppDelegate sharedDelegate].enableAutoCorrect;
    [self.autoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.onlyPromptToAddOnceSwitch = [[UISwitch alloc] init];
    self.onlyPromptToAddOnceSwitch.on = ![PPAppDelegate sharedDelegate].onlyPromptToAddOnce;
    [self.onlyPromptToAddOnceSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.dimReadPostsSwitch = [[UISwitch alloc] init];
    self.dimReadPostsSwitch.on = [PPAppDelegate sharedDelegate].dimReadPosts;
    [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.alwaysShowAlertSwitch = [[UISwitch alloc] init];
    self.alwaysShowAlertSwitch.on = [PPAppDelegate sharedDelegate].alwaysShowClipboardNotification;
    [self.alwaysShowAlertSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:ChoiceCellIdentifier];
    [self.tableView registerClass:[UITableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateSnippetData];
}

- (void)updateSnippetData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger count = self.TESnippetCount;
        self.TEAvailable = [SMTEDelegateController textExpanderTouchHasGetSnippetsCallbackURL];
        
        [SMTEDelegateController expansionStatusForceLoad:NO
                                            snippetCount:&count
                                                loadDate:nil
                                                   error:nil];
        
        self.TESnippetCount = count;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.TEAvailable) {
        return 4;
    }

    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPDisplaySettingsSectionType)section) {
        case PPSectionDisplaySettings:
            return PPRowCountDisplaySettings;

        case PPSectionBrowseSettings:
            return PPRowCountBrowse;
            
        case PPSectionOtherDisplaySettings:
            if (!self.onlyPromptToAddOnceSwitch.on) {
                return PPRowCountOtherSettings;
            }
            else {
                return PPRowCountOtherSettings - 2;
            }

        case PPSectionTextExpanderSettings:
            return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionDisplaySettings:
            switch ((PPEditSettingsRowType)indexPath.row) {
                case PPEditAutoMarkAsReadRow:
                    return 56;
                    
                default:
                    return 44;
            }
            
        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseCompressRow:
                    return 74;
                    
                default:
                    return 44;
            }
            
        case PPSectionOtherDisplaySettings:
            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherOnlyPromptToAddBookmarksOnce:
                    return 92;
                    
                case PPOtherDisplayClearCache:
                    return 74;
                    
                case PPOtherAlwaysShowAlert:
                    return 92;
            }
            
        case PPSectionTextExpanderSettings:
            return 56;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    CGSize size;
    CGSize switchSize;
    
    switch ((PPDisplaySettingsSectionType)indexPath.section) {
        case PPSectionDisplaySettings:
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.text = nil;
            cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPEditSettingsRowType)indexPath.row) {
                case PPEditDefaultToPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private by default?", nil);
                    size = cell.frame.size;

                    switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.privateByDefaultSwitch;
                    break;
                    
                case PPEditDefaultToRead:
                    cell.textLabel.text = NSLocalizedString(@"Read by default?", nil);
                    size = cell.frame.size;
                    switchSize = self.readByDefaultSwitch.frame.size;

                    self.readByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.readByDefaultSwitch;
                    break;

                case PPEditDoubleTapRow:
                    cell.textLabel.text = NSLocalizedString(@"Double tap to edit", nil);
                    size = cell.frame.size;
                    switchSize = self.doubleTapToEditSwitch.frame.size;
                    self.doubleTapToEditSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.doubleTapToEditSwitch;
                    break;

                case PPEditAutoMarkAsReadRow:
                    cell.textLabel.text = @"Auto mark as read";
                    cell.detailTextLabel.text = @"When opening unread bookmarks.";

                    size = cell.frame.size;
                    switchSize = self.markReadSwitch.frame.size;
                    self.markReadSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.markReadSwitch;
                    break;

                case PPEditAutocorrecTextRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect text", nil);
                    size = cell.frame.size;
                    switchSize = self.autoCorrectionSwitch.frame.size;
                    self.autoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.autoCorrectionSwitch;
                    break;

                case PPEditAutocapitalizeRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocapitalize text", nil);
                    size = cell.frame.size;
                    switchSize = self.autoCapitalizationSwitch.frame.size;
                    self.autoCapitalizationSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.autoCapitalizationSwitch;
                    break;
            }
            break;

        case PPSectionBrowseSettings:
            switch ((PPBrowseSettingsRowType)indexPath.row) {
                case PPBrowseCompressRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Compress bookmark list", nil);
                    cell.detailTextLabel.text = @"Limit descriptions to two lines and tags to one line.";
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.compressPostsSwitch.frame.size;
                    self.compressPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.compressPostsSwitch;
                    break;

                case PPBrowseDimReadRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Dim read bookmarks", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.dimReadPostsSwitch.frame.size;
                    self.dimReadPostsSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.dimReadPostsSwitch;
                    break;
                    
                case PPBrowseDefaultFeedRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Default feed", nil);
                    cell.detailTextLabel.text = [PPAppDelegate sharedDelegate].defaultFeedDescription;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
            
        case PPSectionOtherDisplaySettings:
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.text = nil;
            cell.accessoryView = nil;
            cell.detailTextLabel.numberOfLines = 0;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherOnlyPromptToAddBookmarksOnce:
                    cell.textLabel.text = @"Always show add prompt";
                    cell.detailTextLabel.text = @"Always show the add bookmark prompt, even for URLs that Pushpin has seen before.";

                    size = cell.frame.size;
                    switchSize = self.onlyPromptToAddOnceSwitch.frame.size;
                    self.onlyPromptToAddOnceSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.onlyPromptToAddOnceSwitch;
                    break;

                case PPOtherDisplayClearCache:
                    cell.textLabel.text = @"Reset the list of stored URLs";
                    cell.detailTextLabel.text = @"Resets the list of URLs that you've decided not to add from the clipboard.";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case PPOtherAlwaysShowAlert:
                    cell.textLabel.text = @"Notify when a URL isn't added";
                    cell.detailTextLabel.text = @"Display a notification when the URL currently on the clipboard is one that you've previously decided not to add.";

                    size = cell.frame.size;
                    switchSize = self.alwaysShowAlertSwitch.frame.size;
                    self.alwaysShowAlertSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.alwaysShowAlertSwitch;
                    break;
            }
            break;

        case PPSectionTextExpanderSettings: {
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                   forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
            cell.detailTextLabel.textColor = [UIColor grayColor];
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
            SMTEDelegateController *teDelegate = [PPAppDelegate sharedDelegate].textExpander;
            teDelegate.getSnippetsScheme = @"pushpin";
            teDelegate.clientAppName = @"Pushpin";
            [teDelegate getSnippets];
            
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self updateSnippetData];
            });
            break;
        }
            
        case PPSectionOtherDisplaySettings: {
            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherDisplayClearCache: {
                    UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:@"Resetting stored URL list"
                                                                               message:nil
                                                                              delegate:nil
                                                                     cancelButtonTitle:nil
                                                                     otherButtonTitles:nil];
                    [loadingAlertView show];
                    
                    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    activity.center = CGPointMake(CGRectGetWidth(loadingAlertView.bounds)/2, CGRectGetHeight(loadingAlertView.bounds)-45);
                    [activity startAnimating];
                    [loadingAlertView addSubview:activity];
                    
                    FMDatabase *db = [FMDatabase databaseWithPath:[PPAppDelegate databasePath]];
                    [db open];
                    [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                    [db close];
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                        
                        UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"The URL list was cleared." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                        [successAlertView show];
                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [successAlertView dismissWithClickedButtonIndex:0 animated:YES];
                        });
                    });
                    break;
                }
            }
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
            
        case PPSectionOtherDisplaySettings:
            return @"Clipboard URL Detection";
            
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
            
        case PPSectionOtherDisplaySettings:
            return nil;
            
        case PPSectionTextExpanderSettings:
            return nil;
    }
}

- (void)switchChangedValue:(id)sender {
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    if (sender == self.compressPostsSwitch) {
        [delegate setCompressPosts:self.compressPostsSwitch.on];
    }
    else if (sender == self.doubleTapToEditSwitch) {
        [delegate setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    }
    else if (sender == self.dimReadPostsSwitch) {
        [delegate setDimReadPosts:self.dimReadPostsSwitch.on];
    }
    else if (sender == self.markReadSwitch) {
        [delegate setMarkReadPosts:self.markReadSwitch.on];
    }
    else if (sender == self.autoCorrectionSwitch) {
        [delegate setEnableAutoCorrect:self.autoCorrectionSwitch.on];
    }
    else if (sender == self.autoCapitalizationSwitch) {
        [delegate setEnableAutoCapitalize:self.autoCapitalizationSwitch.on];
    }
    else if (sender == self.alwaysShowAlertSwitch) {
        [delegate setAlwaysShowClipboardNotification:self.alwaysShowAlertSwitch.on];
    }
    else if (sender == self.onlyPromptToAddOnceSwitch) {
        [delegate setOnlyPromptToAddOnce:!self.onlyPromptToAddOnceSwitch.on];

        [self.tableView beginUpdates];
        
        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:PPOtherDisplayClearCache inSection:PPSectionOtherDisplaySettings],
                                [NSIndexPath indexPathForRow:PPOtherAlwaysShowAlert inSection:PPSectionOtherDisplaySettings]];
        if (!self.onlyPromptToAddOnceSwitch.on) {
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [self.tableView endUpdates];
        
        if (!self.onlyPromptToAddOnceSwitch.on) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:PPOtherDisplayClearCache inSection:PPSectionOtherDisplaySettings] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
    
    if (sender == self.compressPostsSwitch) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkCompressSettingUpdate object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    }
}

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[PPAppDelegate sharedDelegate] setPrivateByDefault:self.privateByDefaultSwitch.on];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[PPAppDelegate sharedDelegate] setReadByDefault:self.readByDefaultSwitch.on];
}

@end

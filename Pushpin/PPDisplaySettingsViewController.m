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
#import "PPSettings.h"
#import "PPPinboardMetadataCache.h"
#import "LHSFontSelectionViewController.h"
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>

#import <FMDB/FMDatabase.h>
#import <TextExpander/SMTEDelegateController.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>
#import <LHSCategoryCollection/UIFont+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";
static NSString *ChoiceCellIdentifier = @"ChoiceCell";
static NSString *SubtitleCellIdentifier = @"SubtitleCell";

@interface PPDisplaySettingsViewController ()

@property (nonatomic) NSUInteger TESnippetCount;
@property (nonatomic) BOOL TEAvailable;

@property (nonatomic, strong) UIAlertController *textExpanderAlert;

@property (nonatomic, retain) UISwitch *privateByDefaultSwitch;
@property (nonatomic, retain) UISwitch *readByDefaultSwitch;
@property (nonatomic, retain) UISwitch *dimReadPostsSwitch;
@property (nonatomic, retain) UISwitch *compressPostsSwitch;
@property (nonatomic, retain) UISwitch *hidePrivateLockSwitch;
@property (nonatomic, retain) UISwitch *doubleTapToEditSwitch;
@property (nonatomic, retain) UISwitch *markReadSwitch;
@property (nonatomic, retain) UISwitch *autoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *tagAutoCorrectionSwitch;
@property (nonatomic, retain) UISwitch *autoCapitalizationSwitch;
@property (nonatomic, retain) UISwitch *onlyPromptToAddOnceSwitch;
@property (nonatomic, retain) UISwitch *alwaysShowAlertSwitch;
@property (nonatomic, retain) UISwitch *textExpanderSwitch;
@property (nonatomic, retain) UISwitch *turnOffBookmarkPromptSwitch;

@property (nonatomic, strong) UIAlertController *fontSizeAdjustmentActionSheet;

- (void)privateByDefaultSwitchChangedValue:(id)sender;
- (void)readByDefaultSwitchChangedValue:(id)sender;
- (void)switchChangedValue:(id)sender;

- (void)updateSnippetCounts;
- (void)turnOnTextExpander;
- (BOOL)textExpanderEnabled;

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
    
    self.TEAvailable = [SMTEDelegateController textExpanderTouchHasGetSnippetsCallbackURL];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Advanced Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
    
    self.fontSizeAdjustmentActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Font Adjustment", nil)];
    
    for (NSString *title in PPFontAdjustmentTypes()) {
        [self.fontSizeAdjustmentActionSheet lhs_addActionWithTitle:NSLocalizedString(title, nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               NSInteger index = [PPFontAdjustmentTypes() indexOfObject:action.title];
                                                               if (index < [PPFontAdjustmentTypes() count]) {
                                                                   PPFontAdjustmentType fontAdjustment = (PPFontAdjustmentType)index;
                                                                   PPSettings *settings = [PPSettings sharedSettings];
                                                                   settings.fontAdjustment = fontAdjustment;
                                                                   
                                                                   [self.tableView beginUpdates];
                                                                   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPBrowseFontSizeRow inSection:PPSectionBrowseSettings]]
                                                                                         withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                   [self.tableView endUpdates];
                                                                   
                                                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                       [[PPPinboardMetadataCache sharedCache] reset];
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
                                                                   });
                                                               }
                                                           }];
    }
    
    [self.fontSizeAdjustmentActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
    
    PPSettings *settings = [PPSettings sharedSettings];
    self.turnOffBookmarkPromptSwitch = [[UISwitch alloc] init];
    self.turnOffBookmarkPromptSwitch.on = settings.turnOffBookmarkPrompt;
    [self.turnOffBookmarkPromptSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.privateByDefaultSwitch = [[UISwitch alloc] init];
    self.privateByDefaultSwitch.on = settings.privateByDefault;
    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.readByDefaultSwitch = [[UISwitch alloc] init];
    self.readByDefaultSwitch.on = settings.readByDefault;
    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.autoCapitalizationSwitch = [[UISwitch alloc] init];
    self.autoCapitalizationSwitch.on = settings.enableAutoCapitalize;
    [self.autoCapitalizationSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.compressPostsSwitch = [[UISwitch alloc] init];
    self.compressPostsSwitch.on = settings.compressPosts;
    [self.compressPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.hidePrivateLockSwitch = [[UISwitch alloc] init];
    self.hidePrivateLockSwitch.on = settings.hidePrivateLock;
    [self.hidePrivateLockSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.markReadSwitch = [[UISwitch alloc] init];
    self.markReadSwitch.on = settings.markReadPosts;
    [self.markReadSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.doubleTapToEditSwitch = [[UISwitch alloc] init];
    self.doubleTapToEditSwitch.on = settings.doubleTapToEdit;
    [self.doubleTapToEditSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.autoCorrectionSwitch = [[UISwitch alloc] init];
    self.autoCorrectionSwitch.on = settings.enableAutoCorrect;
    [self.autoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.tagAutoCorrectionSwitch = [[UISwitch alloc] init];
    self.tagAutoCorrectionSwitch.on = settings.enableTagAutoCorrect;
    [self.tagAutoCorrectionSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.onlyPromptToAddOnceSwitch = [[UISwitch alloc] init];
    self.onlyPromptToAddOnceSwitch.on = !settings.onlyPromptToAddOnce;
    [self.onlyPromptToAddOnceSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.dimReadPostsSwitch = [[UISwitch alloc] init];
    self.dimReadPostsSwitch.on = settings.dimReadPosts;
    [self.dimReadPostsSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.alwaysShowAlertSwitch = [[UISwitch alloc] init];
    self.alwaysShowAlertSwitch.on = settings.alwaysShowClipboardNotification;
    [self.alwaysShowAlertSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.textExpanderSwitch = [[UISwitch alloc] init];
    self.textExpanderSwitch.on = [self textExpanderEnabled];
    [self.textExpanderSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:ChoiceCellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
    [self updateSnippetCounts];
}

- (void)updateSnippetCounts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger count = self.TESnippetCount;
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
            if (self.turnOffBookmarkPromptSwitch.on) {
                return 1;
            }
            else {
                if (!self.onlyPromptToAddOnceSwitch.on) {
                    return PPRowCountOtherSettings;
                }
                else {
                    return PPRowCountOtherSettings - 2;
                }
            }

        case PPSectionTextExpanderSettings: {
            // TextExpander SDK
            BOOL snippetsLoaded = [SMTEDelegateController expansionStatusForceLoad:NO
                                                                      snippetCount:0
                                                                          loadDate:nil
                                                                             error:nil];
            if (snippetsLoaded) {
                return 2;
            }
            else {
                return 1;
            }
        }
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
                case PPOtherTurnOffPrompt:
                    return 92;

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
                    cell.textLabel.text = NSLocalizedString(@"Auto mark as read", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"When opening unread bookmarks.", nil);

                    size = cell.frame.size;
                    switchSize = self.markReadSwitch.frame.size;
                    self.markReadSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.markReadSwitch;
                    break;

                case PPEditAutocorrectTextRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect text", nil);
                    size = cell.frame.size;
                    switchSize = self.autoCorrectionSwitch.frame.size;
                    self.autoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.autoCorrectionSwitch;
                    break;

                case PPEditAutocorrectTagsRow:
                    cell.textLabel.text = NSLocalizedString(@"Autocorrect tags", nil);
                    size = cell.frame.size;
                    switchSize = self.tagAutoCorrectionSwitch.frame.size;
                    self.tagAutoCorrectionSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.tagAutoCorrectionSwitch;
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
                    cell.detailTextLabel.text = NSLocalizedString(@"Limit descriptions to two lines and tags to one line.", nil);
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
                    
                case PPBrowseFontRow: {
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;
                    
                    cell.textLabel.text = NSLocalizedString(@"Font", nil);

                    UIFont *font = [PPTheme titleFont];
                    cell.detailTextLabel.text = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                    
                case PPBrowseFontSizeRow: {
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Font size", nil);
                    cell.detailTextLabel.text = NSLocalizedString(PPFontAdjustmentTypes()[[[PPSettings sharedSettings] fontAdjustment]], nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                    
                case PPBrowseHidePrivateLock: {
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [UIFont fontWithName:[PPTheme fontName] size:13];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.numberOfLines = 0;
                    cell.accessoryView = nil;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;

                    cell.textLabel.text = NSLocalizedString(@"Hide Private Lock", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    switchSize = self.hidePrivateLockSwitch.frame.size;
                    self.hidePrivateLockSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.hidePrivateLockSwitch;
                    break;
                }
                    
                case PPBrowseDefaultFeedRow:
                    cell = [tableView dequeueReusableCellWithIdentifier:ChoiceCellIdentifier
                                                           forIndexPath:indexPath];
                    cell.textLabel.font = [PPTheme textLabelFont];
                    cell.detailTextLabel.font = [PPTheme detailLabelFont];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.accessoryView = nil;

                    cell.textLabel.text = NSLocalizedString(@"Default feed", nil);
                    cell.detailTextLabel.text = [PPSettings sharedSettings].defaultFeedDescription;
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
            cell.detailTextLabel.numberOfLines = 0;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherTurnOffPrompt:
                    cell.textLabel.text = NSLocalizedString(@"Turn it off!", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"The future is here. Be one with the extensions. Never see a bookmark prompt again. Ever.", nil);
                    
                    size = cell.frame.size;
                    switchSize = self.turnOffBookmarkPromptSwitch.frame.size;
                    self.turnOffBookmarkPromptSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.turnOffBookmarkPromptSwitch;
                    break;

                case PPOtherOnlyPromptToAddBookmarksOnce:
                    cell.textLabel.text = NSLocalizedString(@"Always show add prompt", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Always show the add bookmark prompt, even for URLs that Pushpin has seen before.", nil);

                    size = cell.frame.size;
                    switchSize = self.onlyPromptToAddOnceSwitch.frame.size;
                    self.onlyPromptToAddOnceSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.onlyPromptToAddOnceSwitch;
                    break;

                case PPOtherDisplayClearCache:
                    cell.textLabel.text = NSLocalizedString(@"Reset the list of stored URLs", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Resets the list of URLs that you've decided not to add from the clipboard.", nil);
                    cell.isAccessibilityElement = YES;
                    cell.accessibilityLabel = NSLocalizedString(@"Reset URL", nil);
                    break;
                    
                case PPOtherAlwaysShowAlert:
                    cell.textLabel.text = NSLocalizedString(@"Notify when a URL isn't added", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Display a notification when the URL currently on the clipboard is one that you've previously decided not to add.", nil);

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

            switch ((PPTextExpanderRowType)indexPath.row) {
                case PPTextExpanderRowSwitch:
                    cell.textLabel.text = NSLocalizedString(@"Enable TextExpander", nil);
                    cell.detailTextLabel.text = nil;
                    
                    size = cell.frame.size;
                    switchSize = self.textExpanderSwitch.frame.size;
                    self.textExpanderSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.textExpanderSwitch;
                    break;

                case PPTextExpanderRowUpdate:
                    cell.textLabel.text = NSLocalizedString(@"Update TextExpander Snippets", nil);
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateStyle = NSDateFormatterShortStyle;
                    
                    if (self.TESnippetCount == 1) {
                        cell.detailTextLabel.text = NSLocalizedString(@"1 snippet", nil);
                    }
                    else {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld snippets", (long)self.TESnippetCount];
                    }
                    
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.accessoryView = nil;
                    break;
            }
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
                    
                case PPBrowseFontRow: {
                    NSArray *preferredFontNames = @[@"Flex-Regular", @"Brando-Regular", @"LyonTextApp-Regular"];
                    LHSFontSelectionViewController *fontSelectionViewController = [[LHSFontSelectionViewController alloc] initWithPreferredFontNames:preferredFontNames
                                                                                                                              onlyShowPreferredFonts:NO];
                    fontSelectionViewController.delegate = self;
                    fontSelectionViewController.preferredStatusBarStyle = UIStatusBarStyleLightContent;
                    [self.navigationController pushViewController:fontSelectionViewController animated:YES];
                    break;
                }

                case PPBrowseFontSizeRow: {
                    if (!self.fontSizeAdjustmentActionSheet.presentingViewController) {
                        UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
                        self.fontSizeAdjustmentActionSheet.popoverPresentationController.sourceView = cell;
                        self.fontSizeAdjustmentActionSheet.popoverPresentationController.sourceRect = [cell lhs_centerRect];

                        [self presentViewController:self.fontSizeAdjustmentActionSheet animated:YES completion:nil];
                    }
                    break;
                }
            }
            break;

        case PPSectionTextExpanderSettings: {
            switch ((PPTextExpanderRowType)indexPath.row) {
                case PPTextExpanderRowSwitch:
                    break;

                case PPTextExpanderRowUpdate: {
                    [self turnOnTextExpander];

                    double delayInSeconds = 2.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self updateSnippetCounts];
                    });
                    break;
                }
            }

            break;
        }
            
        case PPSectionOtherDisplaySettings: {
            switch ((PPOtherDisplaySettingsRowType)indexPath.row) {
                case PPOtherDisplayClearCache: {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Please Wait", nil)
                                                                                   message:NSLocalizedString(@"Resetting stored URL list", nil)];

                    [self presentViewController:alert animated:YES completion:^{
                        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                            [db executeUpdate:@"DELETE FROM rejected_bookmark;"];
                        }];
                        
                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [self dismissViewControllerAnimated:YES completion:^{
                                UIAlertController *successAlert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                                                     message:NSLocalizedString(@"The URL list was cleared.", nil)];

                                [self presentViewController:successAlert animated:YES completion:^{
                                    double delayInSeconds = 1.0;
                                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    });
                                }];
                            }];
                        });
                    }];
                    
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
            return NSLocalizedString(@"Browsing", nil);
            
        case PPSectionDisplaySettings:
            return NSLocalizedString(@"Editing", nil);
            
        case PPSectionOtherDisplaySettings:
            return NSLocalizedString(@"Clipboard URL detection", nil);
            
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
    PPSettings *settings = [PPSettings sharedSettings];
    if (sender == self.compressPostsSwitch) {
        [settings setCompressPosts:self.compressPostsSwitch.on];
    }
    else if (sender == self.doubleTapToEditSwitch) {
        [settings setDoubleTapToEdit:self.doubleTapToEditSwitch.on];
    }
    else if (sender == self.dimReadPostsSwitch) {
        [settings setDimReadPosts:self.dimReadPostsSwitch.on];

        // We clear the cache since posts now look differently.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PPPinboardMetadataCache sharedCache] removeAllObjects];
        });
    }
    else if (sender == self.markReadSwitch) {
        [settings setMarkReadPosts:self.markReadSwitch.on];
    }
    else if (sender == self.hidePrivateLockSwitch) {
        settings.hidePrivateLock = self.hidePrivateLockSwitch.on;

        // We clear the cache since posts now look differently.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PPPinboardMetadataCache sharedCache] removeAllObjects];
        });
    }
    else if (sender == self.autoCorrectionSwitch) {
        settings.enableAutoCorrect = self.autoCorrectionSwitch.on;
    }
    else if (sender == self.tagAutoCorrectionSwitch) {
        settings.enableTagAutoCorrect = self.tagAutoCorrectionSwitch.on;
    }
    else if (sender == self.autoCapitalizationSwitch) {
        settings.enableAutoCapitalize = self.autoCapitalizationSwitch.on;
    }
    else if (sender == self.alwaysShowAlertSwitch) {
        [settings setAlwaysShowClipboardNotification:self.alwaysShowAlertSwitch.on];
    }
    else if (sender == self.turnOffBookmarkPromptSwitch) {
        [settings setTurnOffBookmarkPrompt:self.turnOffBookmarkPromptSwitch.on];

        [self.tableView beginUpdates];
        
        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
        NSMutableArray *indexPathsToInsert = [NSMutableArray array];
        if (self.turnOffBookmarkPromptSwitch.on) {
            if (self.onlyPromptToAddOnceSwitch.on) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:PPOtherOnlyPromptToAddBookmarksOnce inSection:PPSectionOtherDisplaySettings]];
            }
            else {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:PPOtherOnlyPromptToAddBookmarksOnce inSection:PPSectionOtherDisplaySettings]];
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:PPOtherAlwaysShowAlert inSection:PPSectionOtherDisplaySettings]];
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:PPOtherDisplayClearCache inSection:PPSectionOtherDisplaySettings]];
            }
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            if (self.onlyPromptToAddOnceSwitch.on) {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:PPOtherOnlyPromptToAddBookmarksOnce inSection:PPSectionOtherDisplaySettings]];
            }
            else {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:PPOtherOnlyPromptToAddBookmarksOnce inSection:PPSectionOtherDisplaySettings]];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:PPOtherAlwaysShowAlert inSection:PPSectionOtherDisplaySettings]];
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:PPOtherDisplayClearCache inSection:PPSectionOtherDisplaySettings]];
            }
            [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [self.tableView endUpdates];
    }
    else if (sender == self.onlyPromptToAddOnceSwitch) {
        [settings setOnlyPromptToAddOnce:!self.onlyPromptToAddOnceSwitch.on];

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
    else if (sender == self.textExpanderSwitch) {
        if (self.textExpanderSwitch.on) {
            // Sync snippets.
            self.textExpanderAlert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Enable TextExpander", nil)
                                                                       message:NSLocalizedString(@"To enable TextExpander in Pushpin, you'll be redirected to the TextExpander app.", nil)];
            
            [self.textExpanderAlert lhs_addActionWithTitle:NSLocalizedString(@"Continue", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self turnOnTextExpander];
                                                       double delayInSeconds = 2.0;
                                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                           [self updateSnippetCounts];
                                                           
                                                           [self.tableView beginUpdates];
                                                           [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPTextExpanderRowUpdate inSection:PPSectionTextExpanderSettings]]
                                                                                 withRowAnimation:UITableViewRowAnimationFade];
                                                           [self.tableView endUpdates];
                                                       });
                                                   }];
            
            [self.textExpanderAlert lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
                                                       // Switch the switch back to the off position.
                                                       [self.textExpanderSwitch setOn:NO animated:YES];
                                                   }];

            [self presentViewController:self.textExpanderAlert animated:YES completion:nil];
        }
        else {
            // Turn off TextExpander and clear all snippets
            [SMTEDelegateController setExpansionEnabled:NO];
            [SMTEDelegateController clearSharedSnippets];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPTextExpanderRowUpdate inSection:PPSectionTextExpanderSettings]]
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        }
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    }
}

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[PPSettings sharedSettings] setPrivateByDefault:self.privateByDefaultSwitch.on];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[PPSettings sharedSettings] setReadByDefault:self.readByDefaultSwitch.on];
}

- (BOOL)textExpanderEnabled {
    return [SMTEDelegateController expansionStatusForceLoad:NO
                                               snippetCount:0
                                                   loadDate:nil
                                                      error:nil];
}

- (void)turnOnTextExpander {
    SMTEDelegateController *teDelegate = [PPAppDelegate sharedDelegate].textExpander;
#ifdef DELICIOUS
    teDelegate.getSnippetsScheme = @"pushpindelicious";
#endif
    
#ifdef PINBOARD
    teDelegate.getSnippetsScheme = @"pushpin";
#endif
    teDelegate.clientAppName = @"Pushpin";
    [teDelegate getSnippets];
}

#pragma mark - LHSFontSelecting

- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    [PPSettings sharedSettings].fontName = fontName;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PPPinboardMetadataCache sharedCache] reset];
        [[NSNotificationCenter defaultCenter] postNotificationName:PPBookmarkDisplaySettingUpdated object:nil];
    });
}

- (NSString *)fontNameForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPSettings sharedSettings].fontName;
}

- (CGFloat)fontSizeForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPTheme fontSize];
}

@end

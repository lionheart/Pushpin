//
//  PPMobilizerSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPReaderSettingsViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"
#import "PPWebViewController.h"

#import "LHSFontSelectionViewController.h"

@import LHSCategoryCollection;
@import LHSTableViewCells;

static NSString *CellIdentifier = @"Cell";

@interface PPReaderSettingsViewController ()

@property (nonatomic, strong) UISwitch *displayImagesSwitch;
@property (nonatomic, strong) UILabel *fontFamilyLabel;
@property (nonatomic, strong) UILabel *fontSizeLabel;
@property (nonatomic, strong) UILabel *lineSpacingLabel;
@property (nonatomic, strong) UILabel *marginLabel;

@property (nonatomic, strong) NSMutableSet *toggledIndexPaths;

#if TARGET_OS_MACCATALYST
@property (nonatomic, strong) WKWebView *exampleWebView;
#else
@property (nonatomic, strong) UIWebView *exampleWebView;
#endif

@property (nonatomic, strong) UIView *webViewContainer;
@property (nonatomic, strong) UIAlertController *textAlignmentActionSheet;

@property (nonatomic, strong) UIButton *whiteThemeButton;
@property (nonatomic, strong) UIButton *yellowThemeButton;
@property (nonatomic, strong) UIButton *greyThemeButton;
@property (nonatomic, strong) UIButton *darkGreyThemeButton;
@property (nonatomic, strong) UIButton *blackThemeButton;
@property (nonatomic, strong) NSLayoutConstraint *webViewContainerPinnedToTopConstraint;

#if PPREADER_USE_SLIDERS
@property (nonatomic, strong) UISlider *fontSizeSlider;
@property (nonatomic, strong) UISlider *lineSpacingSlider;
@property (nonatomic, strong) UISlider *marginSlider;

- (void)sliderChangedValue:(id)sender;
#else
@property (nonatomic, strong) UIStepper *fontSizeStepper;

- (void)stepperChangedValue:(id)sender;
#endif

- (void)switchChangedValue:(id)sender;
- (void)themeButtonTouchUpInside:(id)sender;
- (void)updateExampleWebView;
- (void)toggleFullScreenExampleWebView;

@end

@implementation PPReaderSettingsViewController

- (void)viewDidLayoutSubviews {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.webViewContainer.frame), 0);
    [self.view layoutIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Reader Settings", nil);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Preview", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(toggleFullScreenExampleWebView)];

    self.tableView.showsVerticalScrollIndicator = NO;

    self.toggledIndexPaths = [NSMutableSet set];

    self.textAlignmentActionSheet = [UIAlertController lhs_actionSheetWithTitle:nil];

    for (NSString *alignment in @[@"Left", @"Center", @"Right", @"Justified", @"Natural"]) {
        [self.textAlignmentActionSheet lhs_addActionWithTitle:alignment
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
            NSDictionary *map = @{@"Left": @(NSTextAlignmentLeft),
                                  @"Center": @(NSTextAlignmentCenter),
                                  @"Right": @(NSTextAlignmentRight),
                                  @"Justified": @(NSTextAlignmentJustified),
                                  @"Natural": @(NSTextAlignmentNatural) };
            NSNumber *result = map[action.title];
            if (result) {
                PPSettings *settings = [PPSettings sharedSettings];
                PPReaderSettings *readerSettings = settings.readerSettings;
                readerSettings.textAlignment = [result integerValue];
                settings.readerSettings = readerSettings;
                [settings.readerSettings updateCustomReaderCSSFile];

                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPReaderSettingsMainRowTextAlignment inSection:PPReaderSettingsSectionMain]]
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                [self updateExampleWebView];

                self.textAlignmentActionSheet = nil;
            }
        }];
    }

    [self.textAlignmentActionSheet lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:nil];

#if PPREADER_USE_SLIDERS
    self.fontSizeSlider = [[UISlider alloc] init];
    self.fontSizeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.fontSizeSlider.minimumValue = 8;
    self.fontSizeSlider.maximumValue = 30;
    self.fontSizeSlider.value = [PPSettings sharedSettings].readerSettings.fontSize;
    [self.fontSizeSlider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.lineSpacingSlider = [[UISlider alloc] init];
    self.lineSpacingSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.lineSpacingSlider.minimumValue = 0.8;
    self.lineSpacingSlider.maximumValue = 2;
    self.lineSpacingSlider.value = [PPSettings sharedSettings].readerSettings.lineSpacing;
    [self.lineSpacingSlider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];

    self.marginSlider = [[UISlider alloc] init];
    self.marginSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.marginSlider.minimumValue = 50;
    self.marginSlider.maximumValue = 100;
    self.marginSlider.value = [PPSettings sharedSettings].readerSettings.margin;
    [self.marginSlider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
#else
    self.fontSizeStepper = [[UIStepper alloc] init];
    self.fontSizeStepper.minimumValue = 8;
    self.fontSizeStepper.maximumValue = 30;
    self.fontSizeStepper.value = [PPSettings sharedSettings].readerSettings.fontSize;
    [self.fontSizeStepper addTarget:self action:@selector(stepperChangedValue:) forControlEvents:UIControlEventValueChanged];
#endif

    self.whiteThemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.whiteThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.whiteThemeButton.backgroundColor = HEX(0xfbfbfbff);
    [self.whiteThemeButton addTarget:self action:@selector(themeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    self.yellowThemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.yellowThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.yellowThemeButton.backgroundColor = HEX(0xfffff7ff);
    [self.yellowThemeButton addTarget:self action:@selector(themeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    self.greyThemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.greyThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.greyThemeButton.backgroundColor = HEX(0xf5f5f5ff);
    [self.greyThemeButton addTarget:self action:@selector(themeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    self.darkGreyThemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.darkGreyThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.darkGreyThemeButton.backgroundColor = HEX(0x343a3aff);
    [self.darkGreyThemeButton addTarget:self action:@selector(themeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    self.blackThemeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.blackThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.blackThemeButton.backgroundColor = HEX(0x000000ff);
    [self.blackThemeButton addTarget:self action:@selector(themeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    self.fontSizeLabel = [[UILabel alloc] init];
    self.fontSizeLabel.textColor = [UIColor lightGrayColor];
    self.fontSizeLabel.font = [PPTheme detailLabelFont];
    self.fontSizeLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.fontFamilyLabel = [[UILabel alloc] init];
    self.fontFamilyLabel.textColor = [UIColor lightGrayColor];
    self.fontFamilyLabel.font = [PPTheme detailLabelFont];
    self.fontFamilyLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.lineSpacingLabel = [[UILabel alloc] init];
    self.lineSpacingLabel.textColor = [UIColor lightGrayColor];
    self.lineSpacingLabel.font = [PPTheme detailLabelFont];
    self.lineSpacingLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.marginLabel = [[UILabel alloc] init];
    self.marginLabel.textColor = [UIColor lightGrayColor];
    self.marginLabel.font = [PPTheme detailLabelFont];
    self.marginLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.displayImagesSwitch = [[UISwitch alloc] init];
    self.displayImagesSwitch.on = [PPSettings sharedSettings].readerSettings.displayImages;
    [self.displayImagesSwitch addTarget:self action:@selector(switchChangedValue:) forControlEvents:UIControlEventValueChanged];

#if TARGET_OS_MACCATALYST
    self.exampleWebView = [[WKWebView alloc] init];
#else
    self.exampleWebView = [[UIWebView alloc] init];
#endif
    self.exampleWebView.backgroundColor = [PPSettings sharedSettings].readerSettings.backgroundColor;
    self.exampleWebView.translatesAutoresizingMaskIntoConstraints = NO;

    self.webViewContainer = [[UIView alloc] init];
    self.webViewContainer.translatesAutoresizingMaskIntoConstraints = NO;

    [self updateExampleWebView];

    [self.webViewContainer addSubview:self.whiteThemeButton];
    [self.webViewContainer addSubview:self.yellowThemeButton];
    [self.webViewContainer addSubview:self.darkGreyThemeButton];
    [self.webViewContainer addSubview:self.blackThemeButton];
    [self.webViewContainer addSubview:self.exampleWebView];
    [self.exampleWebView lhs_fillWidthOfSuperview];

    NSDictionary *views = @{@"white": self.whiteThemeButton,
                            @"yellow": self.yellowThemeButton,
                            @"grey": self.greyThemeButton,
                            @"dark": self.darkGreyThemeButton,
                            @"black": self.blackThemeButton,
                            @"webview": self.exampleWebView,
                            @"container": self.webViewContainer };

    [self.webViewContainer lhs_addConstraints:@"V:|[white(44)][webview]" views:views];
    [self.webViewContainer lhs_addConstraints:@"V:|[yellow(==white)]" views:views];
    [self.webViewContainer lhs_addConstraints:@"V:|[dark(==white)]" views:views];
    [self.webViewContainer lhs_addConstraints:@"V:|[black(==white)]" views:views];
    [self.webViewContainer lhs_addConstraints:@"|[white][yellow(==white)][dark(==white)][black(==white)]|" views:views];

    [self.view addSubview:self.webViewContainer];
    [self.webViewContainer lhs_fillWidthOfSuperview];
    [self.view lhs_addConstraints:@"V:[container(>=200)]" views:views];

    NSLayoutYAxisAnchor *bottomAnchor;
    if (@available(iOS 11, *)) {
        bottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
    } else {
        bottomAnchor = self.view.bottomAnchor;
    }

    [self.exampleWebView.bottomAnchor constraintEqualToAnchor:bottomAnchor].active = YES;
    [self.webViewContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    self.webViewContainerPinnedToTopConstraint = [self.webViewContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSSet *equivalentObjects = [self.toggledIndexPaths objectsWithOptions:0 passingTest:^BOOL(NSIndexPath *obj, BOOL *stop) {
        return obj.row == indexPath.row && obj.section == indexPath.section;
    }];
    if ([equivalentObjects count] > 0) {
        return 90;
    } else if (indexPath.section == PPReaderSettingsSectionPreview && indexPath.row == PPReaderSettingsPreviewRowTheme) {
        return 160;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [PPTheme textLabelFont];

    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    [cell.contentView lhs_removeSubviews];

    PPSettings *settings = [PPSettings sharedSettings];
    switch ((PPReaderSettingsSectionType)indexPath.section) {
        case PPReaderSettingsSectionMain:
            switch ((PPReaderSettingsMainRowType)indexPath.row) {
                case PPReaderSettingsMainRowFontFamily: {
                    cell.textLabel.text = NSLocalizedString(@"Font", nil);

                    UIFont *font = [PPSettings sharedSettings].readerSettings.font;
                    self.fontFamilyLabel.font = [PPTheme textLabelFont];
                    self.fontFamilyLabel.text = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];

                    [cell.contentView addSubview:self.fontFamilyLabel];
                    NSDictionary *views = @{@"detail": self.fontFamilyLabel};
                    [cell.contentView lhs_addConstraints:@"[detail]-14-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[detail]" views:views];

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }

                case PPReaderSettingsMainRowFontSize: {
#if PPREADER_USE_SLIDERS
                    title.text = NSLocalizedString(@"Font size", nil);
                    self.fontSizeLabel.text = [NSString stringWithFormat:@"%0.0fpx", settings.readerSettings.fontSize];

                    NSMutableDictionary *views = [@{@"detail": self.fontSizeLabel, @"title": title} mutableCopy];

                    [cell.contentView addSubview:title];
                    [cell.contentView addSubview:self.fontSizeLabel];
                    [cell.contentView lhs_addConstraints:@"|-14-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"[detail]-14-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[detail]" views:views];

                    if ([self.toggledIndexPaths containsObject:indexPath]) {
                        views[@"slider"] = self.fontSizeSlider;

                        [cell.contentView addSubview:self.fontSizeSlider];
                        [cell.contentView lhs_addConstraints:@"H:|-24-[slider]-24-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:[slider]-12-|" views:views];
                    }
#else
                    cell.textLabel.text = NSLocalizedString(@"Font size", nil);
                    cell.accessoryView = self.fontSizeStepper;
#endif
                    break;
                }

                case PPReaderSettingsMainRowDisplayImages: {
                    cell.textLabel.text = NSLocalizedString(@"Display images?", nil);

                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.displayImagesSwitch.frame.size;
                    self.displayImagesSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    cell.accessoryView = self.displayImagesSwitch;
                    break;
                }

                case PPReaderSettingsMainRowFontLineSpacing: {
                    title.text = NSLocalizedString(@"Line Spacing", nil);
                    self.lineSpacingLabel.text = [NSString stringWithFormat:@"%0.1fem", settings.readerSettings.lineSpacing];

                    NSMutableDictionary *views = [@{@"detail": self.lineSpacingLabel, @"title": title} mutableCopy];

                    [cell.contentView addSubview:title];
                    [cell.contentView addSubview:self.lineSpacingLabel];
                    [cell.contentView lhs_addConstraints:@"|-14-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"[detail]-14-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[detail]" views:views];

#if PPREADER_USE_SLIDERS
                    if ([self.toggledIndexPaths containsObject:indexPath]) {
                        views[@"slider"] = self.lineSpacingSlider;
                        [cell.contentView addSubview:self.lineSpacingSlider];
                        [cell.contentView lhs_addConstraints:@"H:|-24-[slider]-24-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:[slider]-12-|" views:views];
                    }
#endif
                    break;
                }

                case PPReaderSettingsMainRowHeaderFontFamily:
                    cell.textLabel.text = NSLocalizedString(@"Header Font", nil);
                    cell.detailTextLabel.text = settings.readerSettings.headerFontName;
                    break;

                case PPReaderSettingsMainRowMargin: {
                    title.text = NSLocalizedString(@"Margins", nil);
                    self.marginLabel.text = [NSString stringWithFormat:@"%lu%%", (long)settings.readerSettings.margin];

                    NSMutableDictionary *views = [@{@"detail": self.marginLabel, @"title": title} mutableCopy];

                    [cell.contentView addSubview:title];
                    [cell.contentView addSubview:self.marginLabel];
                    [cell.contentView lhs_addConstraints:@"|-14-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[title]" views:views];
                    [cell.contentView lhs_addConstraints:@"[detail]-14-|" views:views];
                    [cell.contentView lhs_addConstraints:@"V:|-12-[detail]" views:views];

#if PPREADER_USE_SLIDERS
                    if ([self.toggledIndexPaths containsObject:indexPath]) {
                        views[@"slider"] = self.marginSlider;
                        [cell.contentView addSubview:self.marginSlider];
                        [cell.contentView lhs_addConstraints:@"H:|-24-[slider]-24-|" views:views];
                        [cell.contentView lhs_addConstraints:@"V:[slider]-12-|" views:views];
                    }
#endif
                    break;
                }

                case PPReaderSettingsMainRowTextAlignment:
                    cell.textLabel.text = NSLocalizedString(@"Text Alignment", nil);

                    switch (settings.readerSettings.textAlignment) {
                        case NSTextAlignmentLeft:
                            cell.detailTextLabel.text = NSLocalizedString(@"Left", nil);
                            break;

                        case NSTextAlignmentCenter:
                            cell.detailTextLabel.text = NSLocalizedString(@"Center", nil);
                            break;

                        case NSTextAlignmentRight:
                            cell.detailTextLabel.text = NSLocalizedString(@"Right", nil);
                            break;

                        case NSTextAlignmentJustified:
                            cell.detailTextLabel.text = NSLocalizedString(@"Justified", nil);
                            break;

                        default:
                            break;
                    }
                    break;

                case PPReaderSettingsMainRowTheme: {
                    [cell.contentView addSubview:self.whiteThemeButton];
                    [cell.contentView addSubview:self.yellowThemeButton];
                    [cell.contentView addSubview:self.greyThemeButton];
                    [cell.contentView addSubview:self.darkGreyThemeButton];
                    [cell.contentView addSubview:self.blackThemeButton];

                    NSDictionary *views = @{@"white": self.whiteThemeButton,
                                            @"yellow": self.yellowThemeButton,
                                            @"gray": self.greyThemeButton,
                                            @"dark": self.darkGreyThemeButton,
                                            @"black": self.blackThemeButton };

                    [self.whiteThemeButton lhs_fillHeightOfSuperview];
                    [self.yellowThemeButton lhs_fillHeightOfSuperview];
                    [self.greyThemeButton lhs_fillHeightOfSuperview];
                    [self.darkGreyThemeButton lhs_fillHeightOfSuperview];
                    [self.blackThemeButton lhs_fillHeightOfSuperview];
                    [cell.contentView lhs_addConstraints:@"|[white][yellow(==white)][gray(==white)][dark(==white)][black(==white)]|" views:views];
                    break;
                }

                case PPReaderSettingsMainRowPreview: {
                    [cell.contentView addSubview:self.exampleWebView];
                    [self.exampleWebView lhs_expandToFillSuperview];
                    break;
                }
            }
            break;

        case PPReaderSettingsSectionPreview: {
            [cell.contentView addSubview:self.whiteThemeButton];
            [cell.contentView addSubview:self.yellowThemeButton];
            [cell.contentView addSubview:self.greyThemeButton];
            [cell.contentView addSubview:self.darkGreyThemeButton];
            [cell.contentView addSubview:self.blackThemeButton];
            [cell.contentView addSubview:self.exampleWebView];

            NSDictionary *views = @{@"white": self.whiteThemeButton,
                                    @"yellow": self.yellowThemeButton,
                                    @"grey": self.greyThemeButton,
                                    @"dark": self.darkGreyThemeButton,
                                    @"black": self.blackThemeButton,
                                    @"webview": self.exampleWebView };

            [cell.contentView lhs_addConstraints:@"V:|[white(44)][webview]|" views:views];
            [cell.contentView lhs_addConstraints:@"V:|[yellow(==white)]" views:views];
            [cell.contentView lhs_addConstraints:@"V:|[grey(==white)]" views:views];
            [cell.contentView lhs_addConstraints:@"V:|[dark(==white)]" views:views];
            [cell.contentView lhs_addConstraints:@"V:|[black(==white)]" views:views];
            [cell.contentView lhs_addConstraints:@"|[webview]|" views:views];
            [cell.contentView lhs_addConstraints:@"|[white][yellow(==white)][grey(==white)][dark(==white)][black(==white)]|" views:views];
            break;
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((PPReaderSettingsSectionType)section) {
        case PPReaderSettingsSectionMain:
            return PPReaderSettingsMainRowCount;

        case PPReaderSettingsSectionPreview:
            return PPReaderSettingsPreviewRowCount;
    }

    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch ((PPReaderSettingsMainRowType)indexPath.row) {
        case PPReaderSettingsMainRowFontFamily: {
            NSArray *preferredFontNames = @[@"Flex-Regular", @"Brando-Regular", @"AvenirNext-Regular", @"LyonTextApp-Regular", [UIFont systemFontOfSize:10].fontName, [UIFont boldSystemFontOfSize:10].fontName];
            LHSFontSelectionViewController *fontSelectionViewController = [[LHSFontSelectionViewController alloc] initWithPreferredFontNames:preferredFontNames
                                                                                                                      onlyShowPreferredFonts:NO];
            fontSelectionViewController.delegate = self;
            [self.navigationController pushViewController:fontSelectionViewController animated:YES];
            break;
        }

        case PPReaderSettingsMainRowFontSize:
        case PPReaderSettingsMainRowMargin:
        case PPReaderSettingsMainRowFontLineSpacing: {
            if ([self.toggledIndexPaths containsObject:indexPath]) {
                [self.toggledIndexPaths removeObject:indexPath];
            } else {
                [self.toggledIndexPaths addObject:indexPath];
            }

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            break;
        }

        case PPReaderSettingsMainRowTextAlignment: {
            BOOL show = NO;
            if (show) {
                UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
                self.textAlignmentActionSheet.popoverPresentationController.sourceView = cell;
                self.textAlignmentActionSheet.popoverPresentationController.sourceRect = [cell lhs_centerRect];
                if ([UIApplication isIPad]) {
                    [self presentViewController:self.textAlignmentActionSheet animated:YES completion:nil];
                } else {
                    [self.navigationController presentViewController:self.textAlignmentActionSheet animated:YES completion:nil];
                }
            } else {
                PPSettings *settings = [PPSettings sharedSettings];
                PPReaderSettings *readerSettings = settings.readerSettings;
                switch (readerSettings.textAlignment) {
                    case NSTextAlignmentLeft:
                        readerSettings.textAlignment = NSTextAlignmentCenter;
                        break;

                    case NSTextAlignmentCenter:
                        readerSettings.textAlignment = NSTextAlignmentRight;
                        break;

                    case NSTextAlignmentRight:
                        readerSettings.textAlignment = NSTextAlignmentJustified;
                        break;

                    case NSTextAlignmentJustified:
                        readerSettings.textAlignment = NSTextAlignmentLeft;
                        break;

                    default: break;
                }

                settings.readerSettings = readerSettings;
                [settings.readerSettings updateCustomReaderCSSFile];

                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PPReaderSettingsMainRowTextAlignment inSection:PPReaderSettingsSectionMain]]
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];

                [self updateExampleWebView];
            }
            break;
        }

        case PPReaderSettingsMainRowDisplayImages:
            break;

        default: break;
    }
}

#pragma mark - LHSFontSelecting

- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    PPSettings *settings = [PPSettings sharedSettings];
    PPReaderSettings *readerSettings = settings.readerSettings;
    readerSettings.headerFontName = fontName;
    readerSettings.fontName = fontName;
    settings.readerSettings = readerSettings;
    [settings.readerSettings updateCustomReaderCSSFile];
    [self updateExampleWebView];
}

- (NSString *)fontNameForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPSettings sharedSettings].readerSettings.fontName;
}

- (CGFloat)fontSizeForFontSelectionViewController:(LHSFontSelectionViewController *)viewController {
    return [PPTheme fontSize];
}

- (void)switchChangedValue:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];
    PPReaderSettings *readerSettings = settings.readerSettings;

    if (sender == self.displayImagesSwitch) {
        readerSettings.displayImages = self.displayImagesSwitch.on;

    }
    settings.readerSettings = readerSettings;
    [settings.readerSettings updateCustomReaderCSSFile];
    [self updateExampleWebView];
}

- (void)themeButtonTouchUpInside:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];
    PPReaderSettings *readerSettings = settings.readerSettings;


    if (sender == self.whiteThemeButton) {
        readerSettings.backgroundColor = HEX(0xfbfbfbff);
        readerSettings.textColor = HEX(0x000000ff);

    } else if (sender == self.yellowThemeButton) {
        readerSettings.backgroundColor = HEX(0xfffff7ff);
        readerSettings.textColor = HEX(0x000000ff);

    } else if (sender == self.greyThemeButton) {
        readerSettings.backgroundColor = HEX(0xf5f5f5ff);
        readerSettings.textColor = HEX(0x282828ff);

    } else if (sender == self.darkGreyThemeButton) {
        readerSettings.backgroundColor = HEX(0x343a3aff);
        readerSettings.textColor = HEX(0xfdfdfdff);

    } else if (sender == self.blackThemeButton) {
        readerSettings.backgroundColor = HEX(0x000000ff);
        readerSettings.textColor = HEX(0xfdfdfdff);

    }

    self.exampleWebView.backgroundColor = readerSettings.backgroundColor;
    settings.readerSettings = readerSettings;
    [settings.readerSettings updateCustomReaderCSSFile];
    [self updateExampleWebView];
}

#if PPREADER_USE_SLIDERS

- (void)sliderChangedValue:(id)sender {
    PPSettings *settings = [PPSettings sharedSettings];

    PPReaderSettings *readerSettings = settings.readerSettings;
    if (sender == self.fontSizeSlider) {
        int calculatedValue = (int)self.fontSizeSlider.value;
        if (readerSettings.fontSize != calculatedValue) {
            readerSettings.fontSize = calculatedValue;
            settings.readerSettings = readerSettings;
            [settings.readerSettings updateCustomReaderCSSFile];

            self.fontSizeLabel.text = [NSString stringWithFormat:@"%0.0fpx", settings.readerSettings.fontSize];
            [self updateExampleWebView];
        }
    } else if (sender == self.lineSpacingSlider) {
        float calculatedValue = (int)(10 * self.lineSpacingSlider.value) / 10.;
        if (readerSettings.lineSpacing != calculatedValue) {
            readerSettings.lineSpacing = calculatedValue;
            settings.readerSettings = readerSettings;
            [settings.readerSettings updateCustomReaderCSSFile];

            self.lineSpacingLabel.text = [NSString stringWithFormat:@"%0.1fem", settings.readerSettings.lineSpacing];
            [self updateExampleWebView];
        }
    } else if (sender == self.marginSlider) {
        float calculatedValue = (int)self.marginSlider.value;
        if (readerSettings.margin != calculatedValue) {
            readerSettings.margin = calculatedValue;
            settings.readerSettings = readerSettings;
            [settings.readerSettings updateCustomReaderCSSFile];

            self.marginLabel.text = [NSString stringWithFormat:@"%lu%%", (long)settings.readerSettings.margin];
            [self updateExampleWebView];
        }
    }
}

#else

- (void)stepperChangedValue:(id)sender {
    if (sender == self.fontSizeStepper) {
        PPSettings *settings = [PPSettings sharedSettings];
        PPReaderSettings *readerSettings = settings.readerSettings;
        readerSettings.fontSize = self.fontSizeStepper.value;
        settings.readerSettings = readerSettings;
        [settings.readerSettings updateCustomReaderCSSFile];
        [self updateExampleWebView];
    }
}

#endif

- (void)updateExampleWebView {
    NSDictionary *article = @{@"content": @"<p>Versailles, June 28, (Associated Press.)--Germany and the allied and associated powers signed the peace terms here today in the same imperial hall where the Germans humbled the French so ignominiously forty-eight years ago.</p>"
                              "<p>This formally ended the world war, which lasted just thirty-seven days less than five years. Today, the day of peace, was the fifth anniversary of the murder of Archduke Francis Ferdinand by a Serbian student at Sarajevo.</p>"
                              "<p>The peace was signed under circumstances which somewhat dimmed the expectations of those who had worked and fought during long years of war and months of negotiations for its achievement.</p>"
    };

    PPSettings *settings = [PPSettings sharedSettings];
    PPReaderSettings *readerSettings = settings.readerSettings;

    self.webViewContainer.backgroundColor = readerSettings.backgroundColor;
    [self.exampleWebView loadHTMLString:[[PPSettings sharedSettings].readerSettings readerHTMLForArticle:article] baseURL:nil];
}

- (void)toggleFullScreenExampleWebView {
    if ([self.view.constraints containsObject:self.webViewContainerPinnedToTopConstraint]) {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Preview", nil);
    } else {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Minimize", nil);
    }

    [UIView animateWithDuration:0.4
                     animations:^{
        if ([self.view.constraints containsObject:self.webViewContainerPinnedToTopConstraint]) {
            self.webViewContainerPinnedToTopConstraint.active = NO;
            self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Preview", nil);
        } else {
            self.webViewContainerPinnedToTopConstraint.active = YES;
            self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Minimize", nil);
        }

        [self.view layoutIfNeeded];
    }];
}

@end



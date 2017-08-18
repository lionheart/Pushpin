//
//  LHFontSelectionViewController.m
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

@import LHSTableViewCells;
@import LHSCategoryCollection;
@import YHRoundBorderedButton;

#import "PPAppDelegate.h"
#import "PPSettings.h"
#import "LHSFontSelectionViewController.h"

#import "UIAlertController+LHSAdditions.h"

static NSString *CellIdentifier = @"Cell";

@interface LHSFontSelectionViewController ()

@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) NSDictionary *heights;
@property (nonatomic) BOOL purchaseInProgress;

- (NSAttributedString *)attributedFontNameString;
- (void)purchasePremiumFonts:(id)sender;
- (BOOL)purchased;

@end

@implementation LHSFontSelectionViewController

- (instancetype)initWithPreferredFontNames:(NSArray *)fontNames onlyShowPreferredFonts:(BOOL)onlyShowPreferredFonts {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.preferredFontNames = [fontNames mutableCopy];
        [self.preferredFontNames sortUsingSelector:@selector(compare:)];
        self.onlyShowPreferredFonts = onlyShowPreferredFonts;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Font";
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.currentFontName = [self.delegate fontNameForFontSelectionViewController:self];
    self.purchaseInProgress = NO;
    self.heights = @{
                     @"AcademyEngravedLetPlain": @(24.85546875),
                     @"AlNile": @(28.665),
                     @"AlNile-Bold": @(28.665),
                     @"AmericanTypewriter": @(24.234),
                     @"AmericanTypewriter-Bold": @(25.746),
                     @"AmericanTypewriter-Condensed": @(23.751),
                     @"AmericanTypewriter-CondensedBold": @(25.053),
                     @"AmericanTypewriter-CondensedLight": @(22.554),
                     @"AmericanTypewriter-Light": @(23.919),
                     @"AppleColorEmoji": @(29.53125),
                     @"AppleSDGothicNeo-Bold": @(25.2),
                     @"AppleSDGothicNeo-Light": @(25.2),
                     @"AppleSDGothicNeo-Medium": @(25.2),
                     @"AppleSDGothicNeo-Regular": @(25.2),
                     @"AppleSDGothicNeo-SemiBold": @(25.2),
                     @"AppleSDGothicNeo-Thin": @(25.2),
                     @"Arial-BoldItalicMT": @(23.4609375),
                     @"Arial-BoldMT": @(23.4609375),
                     @"Arial-ItalicMT": @(23.4609375),
                     @"ArialHebrew": @(22.365),
                     @"ArialHebrew-Bold": @(22.365),
                     @"ArialHebrew-Light": @(22.365),
                     @"ArialMT": @(23.4609375),
                     @"ArialRoundedMTBold": @(24.3017578125),
                     @"Avenir-Black": @(28.686),
                     @"Avenir-BlackOblique": @(28.686),
                     @"Avenir-Book": @(28.686),
                     @"Avenir-BookOblique": @(28.686),
                     @"Avenir-Heavy": @(28.686),
                     @"Avenir-HeavyOblique": @(28.686),
                     @"Avenir-Light": @(28.686),
                     @"Avenir-LightOblique": @(28.686),
                     @"Avenir-Medium": @(28.686),
                     @"Avenir-MediumOblique": @(28.686),
                     @"Avenir-Oblique": @(28.686),
                     @"Avenir-Roman": @(28.686),
                     @"AvenirNext-Bold": @(28.686),
                     @"AvenirNext-BoldItalic": @(28.686),
                     @"AvenirNext-DemiBold": @(28.686),
                     @"AvenirNext-DemiBoldItalic": @(28.686),
                     @"AvenirNext-Heavy": @(28.686),
                     @"AvenirNext-HeavyItalic": @(28.686),
                     @"AvenirNext-Italic": @(28.686),
                     @"AvenirNext-Medium": @(28.686),
                     @"AvenirNext-MediumItalic": @(28.686),
                     @"AvenirNext-Regular": @(28.686),
                     @"AvenirNext-UltraLight": @(28.686),
                     @"AvenirNext-UltraLightItalic": @(28.686),
                     @"AvenirNextCondensed-Bold": @(28.686),
                     @"AvenirNextCondensed-BoldItalic": @(28.686),
                     @"AvenirNextCondensed-DemiBold": @(28.686),
                     @"AvenirNextCondensed-DemiBoldItalic": @(28.686),
                     @"AvenirNextCondensed-Heavy": @(28.686),
                     @"AvenirNextCondensed-HeavyItalic": @(28.686),
                     @"AvenirNextCondensed-Italic": @(28.686),
                     @"AvenirNextCondensed-Medium": @(28.686),
                     @"AvenirNextCondensed-MediumItalic": @(28.686),
                     @"AvenirNextCondensed-Regular": @(28.686),
                     @"AvenirNextCondensed-UltraLight": @(28.686),
                     @"AvenirNextCondensed-UltraLightItalic": @(28.686),
                     @"BanglaSangamMN": @(24.9375),
                     @"BanglaSangamMN-Bold": @(24.9375),
                     @"Baskerville": @(24.02490234375),
                     @"Baskerville-Bold": @(24.1787109375),
                     @"Baskerville-BoldItalic": @(23.71728515625),
                     @"Baskerville-Italic": @(23.666015625),
                     @"Baskerville-SemiBold": @(24.00439453125),
                     @"Baskerville-SemiBoldItalic": @(24.12744140625),
                     @"BodoniOrnamentsITCTT": @(21.021),
                     @"BodoniSvtyTwoITCTT-Bold": @(25.095),
                     @"BodoniSvtyTwoITCTT-Book": @(25.242),
                     @"BodoniSvtyTwoITCTT-BookIta": @(26.019),
                     @"BodoniSvtyTwoOSITCTT-Bold": @(25.095),
                     @"BodoniSvtyTwoOSITCTT-Book": @(25.242),
                     @"BodoniSvtyTwoOSITCTT-BookIt": @(26.019),
                     @"BodoniSvtyTwoSCITCTT-Book": @(25.158),
                     @"BradleyHandITCTT-Bold": @(26.229),
                     @"Brando-Regular": @(21),
                     @"ChalkboardSE-Bold": @(29.70165745856354),
                     @"ChalkboardSE-Light": @(29.70165745856354),
                     @"ChalkboardSE-Regular": @(29.70165745856354),
                     @"Chalkduster": @(26.52265193370166),
                     @"Charter": @(25.578),
                     @"Cochin": @(24.087),
                     @"Cochin-Bold": @(24.444),
                     @"Cochin-BoldItalic": @(24.129),
                     @"Cochin-Italic": @(23.52),
                     @"Copperplate": @(21.231),
                     @"Copperplate-Bold": @(21.315),
                     @"Copperplate-Light": @(21.189),
                     @"Courier": @(21),
                     @"Courier-Bold": @(21),
                     @"Courier-BoldOblique": @(21),
                     @"Courier-Oblique": @(21),
                     @"CourierNewPS-BoldItalicMT": @(23.7890625),
                     @"CourierNewPS-BoldMT": @(23.7890625),
                     @"CourierNewPS-ItalicMT": @(23.7890625),
                     @"CourierNewPSMT": @(23.7890625),
                     @"CourierPrime": @(21.1640625),
                     @"Crashlytics": @(21),
                     @"DINAlternate-Bold": @(24.4453125),
                     @"DINCondensed-Bold": @(21),
                     @"Damascus": @(21),
                     @"DamascusBold": @(21),
                     @"DamascusMedium": @(21),
                     @"DamascusSemiBold": @(21),
                     @"DevanagariSangamMN": @(28.37333333333333),
                     @"DevanagariSangamMN-Bold": @(28.37333333333333),
                     @"Didot": @(26.04),
                     @"Didot-Bold": @(26.523),
                     @"Didot-Italic": @(25.872),
                     @"DiwanMishafi": @(30.38232421875),
                     @"EuphemiaUCAS": @(27.71630859375),
                     @"EuphemiaUCAS-Bold": @(27.71630859375),
                     @"EuphemiaUCAS-Italic": @(27.71630859375),
                     @"Farah": @(21),
                     @"Flex-Regular": @(21),
                     @"Futura-CondensedExtraBold": @(26.7421875),
                     @"Futura-CondensedMedium": @(25.2451171875),
                     @"Futura-Medium": @(27.26513671875),
                     @"Futura-MediumItalic": @(27.32666015625),
                     @"GeezaPro": @(25.74683544303797),
                     @"GeezaPro-Bold": @(25.74683544303797),
                     @"GeezaPro-Light": @(25.74683544303797),
                     @"Georgia": @(23.86083984375),
                     @"Georgia-Bold": @(23.86083984375),
                     @"Georgia-BoldItalic": @(23.86083984375),
                     @"Georgia-Italic": @(23.86083984375),
                     @"GillSans": @(24.1171875),
                     @"GillSans-Bold": @(24.31201171875),
                     @"GillSans-BoldItalic": @(24.27099609375),
                     @"GillSans-Italic": @(23.92236328125),
                     @"GillSans-Light": @(23.86083984375),
                     @"GillSans-LightItalic": @(23.7890625),
                     @"GujaratiSangamMN": @(24.9375),
                     @"GujaratiSangamMN-Bold": @(24.9375),
                     @"GurmukhiMN": @(24.609375),
                     @"GurmukhiMN-Bold": @(24.609375),
                     @"Helvetica": @(24.15),
                     @"Helvetica-Bold": @(24.15),
                     @"Helvetica-BoldOblique": @(24.15),
                     @"Helvetica-Light": @(24.15),
                     @"Helvetica-LightOblique": @(24.15),
                     @"Helvetica-Oblique": @(24.15),
                     @"HelveticaNeue": @(24.465),
                     @"HelveticaNeue-Bold": @(25.032),
                     @"HelveticaNeue-BoldItalic": @(25.032),
                     @"HelveticaNeue-CondensedBlack": @(25.179),
                     @"HelveticaNeue-CondensedBold": @(24.822),
                     @"HelveticaNeue-Italic": @(24.57),
                     @"HelveticaNeue-Light": @(24.78),
                     @"HelveticaNeue-LightItalic": @(24.444),
                     @"HelveticaNeue-Medium": @(25.032),
                     @"HelveticaNeue-MediumItalic": @(25.032),
                     @"HelveticaNeue-Thin": @(24.78),
                     @"HelveticaNeue-ThinItalic": @(24.78),
                     @"HelveticaNeue-UltraLight": @(24.024),
                     @"HelveticaNeue-UltraLightItalic": @(24.024),
                     @"HiraKakuProN-W3": @(21),
                     @"HiraKakuProN-W6": @(21),
                     @"HiraMinProN-W3": @(21),
                     @"HiraMinProN-W6": @(21),
                     @"HoeflerText-Black": @(21),
                     @"HoeflerText-BlackItalic": @(21),
                     @"HoeflerText-Italic": @(21),
                     @"HoeflerText-Regular": @(21),
                     @"IowanOldStyle-Bold": @(28.669921875),
                     @"IowanOldStyle-BoldItalic": @(28.669921875),
                     @"IowanOldStyle-Italic": @(28.669921875),
                     @"IowanOldStyle-Roman": @(28.669921875),
                     @"Kailasa": @(34.494140625),
                     @"Kailasa-Bold": @(34.494140625),
                     @"KannadaSangamMN": @(31.30517578125),
                     @"KannadaSangamMN-Bold": @(31.30517578125),
                     @"LyonTextApp-Regular": @(21),
                     @"MalayalamSangamMN": @(24.9375),
                     @"MalayalamSangamMN-Bold": @(24.9375),
                     @"Marion-Bold": @(21),
                     @"Marion-Italic": @(21),
                     @"Marion-Regular": @(21),
                     @"MarkerFelt-Thin": @(22.806),
                     @"MarkerFelt-Wide": @(27.3),
                     @"Menlo-Bold": @(24.4453125),
                     @"Menlo-BoldItalic": @(24.4453125),
                     @"Menlo-Italic": @(24.4453125),
                     @"Menlo-Regular": @(24.4453125),
                     @"Noteworthy-Bold": @(33.6),
                     @"Noteworthy-Light": @(33.6),
                     @"Optima-Bold": @(24.969),
                     @"Optima-BoldItalic": @(25.032),
                     @"Optima-ExtraBlack": @(25.683),
                     @"Optima-Italic": @(24.88500000000001),
                     @"Optima-Regular": @(24.927),
                     @"OriyaSangamMN": @(24.9375),
                     @"OriyaSangamMN-Bold": @(24.9375),
                     @"Palatino-Bold": @(23.10205078125),
                     @"Palatino-BoldItalic": @(23.10205078125),
                     @"Palatino-Italic": @(23.10205078125),
                     @"Palatino-Roman": @(23.10205078125),
                     @"Papyrus": @(32.40234375),
                     @"Papyrus-Condensed": @(32.40234375),
                     @"PartyLetPlain": @(32.197265625),
                     @"STHeitiSC-Light": @(21),
                     @"STHeitiSC-Medium": @(21),
                     @"STHeitiTC-Light": @(21),
                     @"STHeitiTC-Medium": @(21),
                     @"SavoyeLetPlain": @(24.9580078125),
                     @"SinhalaSangamMN": @(22.67138671875),
                     @"SinhalaSangamMN-Bold": @(22.67138671875),
                     @"SnellRoundhand": @(26.481),
                     @"SnellRoundhand-Black": @(26.481),
                     @"SnellRoundhand-Bold": @(26.481),
                     @"Superclarendon-Black": @(25.305),
                     @"Superclarendon-BlackItalic": @(25.305),
                     @"Superclarendon-Bold": @(25.305),
                     @"Superclarendon-BoldItalic": @(25.305),
                     @"Superclarendon-Italic": @(25.305),
                     @"Superclarendon-Light": @(25.305),
                     @"Superclarendon-LightItalic": @(25.305),
                     @"Superclarendon-Regular": @(25.305),
                     @"Symbol": @(21),
                     @"TamilSangamMN": @(21),
                     @"TamilSangamMN-Bold": @(21),
                     @"TeluguSangamMN": @(31.30517578125),
                     @"TeluguSangamMN-Bold": @(31.30517578125),
                     @"Thonburi": @(23.70808080808081),
                     @"Thonburi-Bold": @(23.70808080808081),
                     @"Thonburi-Light": @(23.70808080808081),
                     @"TimesNewRomanPS-BoldItalicMT": @(23.255859375),
                     @"TimesNewRomanPS-BoldMT": @(23.255859375),
                     @"TimesNewRomanPS-ItalicMT": @(23.255859375),
                     @"TimesNewRomanPSMT": @(23.255859375),
                     @"Trebuchet-BoldItalic": @(24.3837890625),
                     @"TrebuchetMS": @(24.3837890625),
                     @"TrebuchetMS-Bold": @(24.3837890625),
                     @"TrebuchetMS-Italic": @(24.3837890625),
                     @"Verdana": @(25.52197265625),
                     @"Verdana-Bold": @(25.52197265625),
                     @"Verdana-BoldItalic": @(25.52197265625),
                     @"Verdana-Italic": @(25.52197265625),
                     @"ZapfDingbatsITC": @(20.80517578125),
                     @"Zapfino": @(70.92749999999999),
                 };

    self.fonts = [NSMutableArray array];
    self.fontsForSectionIndex = [NSMutableDictionary dictionary];
    self.sectionIndexTitles = [NSMutableArray array];

    if (!self.onlyShowPreferredFonts) {
        NSSet *preferredFontSet = [NSSet setWithArray:self.preferredFontNames];

        for (NSString *familyName in [UIFont familyNames]) {
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                if (![preferredFontSet containsObject:fontName]) {
                    [self.fonts addObject:fontName];

                    NSString *firstCharacter = [fontName substringToIndex:1];
                    if (![self.sectionIndexTitles containsObject:firstCharacter]) {
                        [self.sectionIndexTitles addObject:firstCharacter];
                        self.fontsForSectionIndex[firstCharacter] = [NSMutableArray arrayWithObject:fontName];
                    } else {
                        [self.fontsForSectionIndex[firstCharacter] addObject:fontName];
                    }
                }
            }
        }
        
        [self.sectionIndexTitles sortUsingSelector:@selector(compare:)];
        for (NSString *sectionIndexTitle in self.sectionIndexTitles) {
            [self.fontsForSectionIndex[sectionIndexTitle] sortUsingSelector:@selector(compare:)];
        }
        [self.fonts sortUsingSelector:@selector(compare:)];
        
        if (self.preferredFontNames.count > 0) {
            [self.sectionIndexTitles insertObject:@"-" atIndex:0];
            self.fontsForSectionIndex[@"-"] = self.preferredFontNames;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView
                                             selector:@selector(reloadData)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    delegate.hideURLPrompt = YES;
    
    [self setNeedsStatusBarAppearanceUpdate];
    NSArray *indexPathForCurrentlySelectedFont = [self indexPathsForFontName:self.currentFontName];
    
    if (self.preferredFontNames.count == 0) {
        [self.tableView scrollToRowAtIndexPath:[indexPathForCurrentlySelectedFont firstObject]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }

    if (!self.purchased) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[@"com.lionheartsw.Pushpin.PremiumFonts"]]];
            request.delegate = self;
            [request start];
        });

        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    delegate.hideURLPrompt = NO;

    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return 1;
    } else {
        return self.sectionIndexTitles.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.onlyShowPreferredFonts) {
        if (self.purchased) {
            return self.preferredFontNames.count;
        } else {
            return 1;
        }
    } else {
        NSString *sectionName = self.sectionIndexTitles[section];
        if (section == 0 && !self.purchased) {
            return 2;
        } else {
            return [self.fontsForSectionIndex[sectionName] count];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.preferredFontNames.count > 0 && section == 0) {
        return NSLocalizedString(@"Premium Fonts", nil);
    }
    return self.sectionIndexTitles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    if (indexPath.section == 0 && indexPath.row == 0 && !self.purchased) {
        CGRect rect = [[self attributedFontNameString] boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.tableView.frame) - 40, CGFLOAT_MAX)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                    context:nil];
        height = CGRectGetHeight(rect);
    } else {
        NSString *fontName;
        if (self.onlyShowPreferredFonts) {
            fontName = self.preferredFontNames[indexPath.row];
        } else {
            NSString *sectionName = self.sectionIndexTitles[indexPath.section];
            fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
        }
        
        NSNumber *fontHeight = self.heights[fontName];
        if (fontHeight) {
            height = [fontHeight floatValue];
        } else {
            height = 24;
        }
    }
    return MAX(10, height) + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.font = nil;
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = nil;
    [cell.contentView lhs_removeSubviews];
    
    NSString *fontName;
    if (self.onlyShowPreferredFonts) {
        fontName = self.preferredFontNames[indexPath.row];
    } else {
        NSString *sectionName = self.sectionIndexTitles[indexPath.section];
        fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
    }

    UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self]];
    
    NSString *fontDisplayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
    
    if (!self.purchased && indexPath.section == 0) {
        if (indexPath.row == 0) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedFontNameString]];
            cell.textLabel.numberOfLines = 0;
            
            NSRange range = NSMakeRange(0, attributedText.length);

            if (self.products.count > 0) {
                [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];

                BOOL displayPriceButton = YES;
                if (self.purchaseInProgress) {
                    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];
                    cell.accessoryView = self.activity;
                    [self.activity startAnimating];
                }
                else if (displayPriceButton) {
                    YHRoundBorderedButton *priceButton = [[YHRoundBorderedButton alloc] init];
                    priceButton.tag = indexPath.row;
                    
                    SKProduct *product = self.products[0];

                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:product.priceLocale];
                    NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];

                    [priceButton setTitle:formattedPrice forState:UIControlStateNormal];
                    [priceButton addTarget:self action:@selector(purchasePremiumFonts:) forControlEvents:UIControlEventTouchUpInside];
                    [priceButton sizeToFit];
                    priceButton.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    [cell.contentView addSubview:priceButton];
                    [cell.contentView lhs_addConstraints:@"[view(width)]-8-|"
                                                 metrics:@{@"width": @(CGRectGetWidth(priceButton.frame)) }
                                                   views:@{@"view": priceButton}];
                    [cell.contentView lhs_centerVerticallyForView:priceButton];
                }
            } else {
                [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];

                if (self.purchaseInProgress) {
                    cell.accessoryView = self.activity;
                    [self.activity startAnimating];
                }
            }
            
            cell.textLabel.attributedText = attributedText;
        } else {
            cell.textLabel.text = NSLocalizedString(@"Restore Purchases", nil);
            cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        }
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = fontDisplayName;
        cell.textLabel.font = font;

        if ([fontName isEqualToString:self.currentFontName]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return nil;
    } else {
        return self.sectionIndexTitles;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.preferredFontNames.count > 0 && !self.purchased && indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self purchasePremiumFonts:nil];
        } else {
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
            self.purchaseInProgress = YES;
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    } else {
        NSArray *indexPathsForPreviouslySelectedFont = [self indexPathsForFontName:self.currentFontName];
        
        NSString *fontName;
        if (self.onlyShowPreferredFonts) {
            fontName = self.preferredFontNames[indexPath.row];
        } else {
            NSString *sectionName = self.sectionIndexTitles[indexPath.section];
            fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
        }
        
        if (![fontName isEqualToString:self.currentFontName]) {
            self.currentFontName = fontName;
            [self.delegate setFontName:fontName forFontSelectionViewController:self];
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:[indexPathsForPreviouslySelectedFont arrayByAddingObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    }
}

#pragma mark - Utils

- (NSArray *)indexPathsForFontName:(NSString *)fontName {
    NSInteger row;
    NSInteger section;
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    if (self.onlyShowPreferredFonts) {
        if ([self.preferredFontNames containsObject:fontName]) {
            row = [self.preferredFontNames indexOfObject:fontName];
            section = 0;
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    } else {
        if (self.preferredFontNames.count > 0) {
            if ([self.preferredFontNames containsObject:fontName]) {
                row = [self.preferredFontNames indexOfObject:fontName];
                section = 0;
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
        
        if (![self.preferredFontNames containsObject:fontName]) {
            NSString *firstCharacter = [fontName substringToIndex:1];
            section = [self.sectionIndexTitles indexOfObject:firstCharacter];
            row = [self.fontsForSectionIndex[firstCharacter] indexOfObject:fontName];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    return [indexPaths copy];
}

- (NSAttributedString *)attributedFontNameString {
    static NSMutableAttributedString *string;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRange range = NSMakeRange(0, 0);
        NSMutableArray *fontNames = [NSMutableArray array];
        for (NSString *fontName in self.preferredFontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
            NSString *displayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
            [fontNames addObject:displayName];
        }

        string = [[NSMutableAttributedString alloc] initWithString:[fontNames componentsJoinedByString:@", "]];
        
        for (NSString *fontName in self.preferredFontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
            NSString *displayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
            range.length = displayName.length;
            [string addAttribute:NSFontAttributeName value:font range:range];
            range.location += displayName.length + 2;
        }
    });
    
    return string;
}

+ (NSString *)fontNameToDisplayName:(NSString *)fontName {
    if ([fontName isEqualToString:@"Lyon Text App Regular"]) {
        fontName = @"Lyon";
    }
    else if ([fontName isEqualToString:@"Avenir Next Regular"]) {
        fontName = @"Avenir Next";
    }
    else if ([fontName isEqualToString:@"Arial MT"]) {
        fontName = @"Arial";
    }
    else if ([fontName isEqualToString:@"Futura Medium"]) {
        fontName = @"Futura";
    }
    else if ([fontName isEqualToString:@"Flex Regular"]) {
        fontName = @"Flex";
    }
    else if ([fontName isEqualToString:@"Brando Regular"]) {
        fontName = @"Brando";
    }
    return fontName;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.products = response.products;
    self.purchaseInProgress = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)requestDidFinish:(SKRequest *)request {
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.purchaseInProgress = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
    });

    for (SKPaymentTransaction *transaction in transactions) {
        switch ((NSInteger)transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                             message:NSLocalizedString(@"Thank you for your purchase.", nil)];
                [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
                [self presentViewController:alert animated:YES completion:nil];
                
                [PPSettings sharedSettings].purchasedPremiumFonts = YES;

                [queue finishTransaction:transaction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
                break;
            }
                
            case SKPaymentTransactionStateRestored: {
                [PPSettings sharedSettings].purchasedPremiumFonts = YES;

                [queue finishTransaction:transaction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
                break;
            }
                
            case SKPaymentTransactionStateFailed: {
                // iOS already displays an error prompt when IAPs are restricted.
                if (transaction.error.code != SKErrorPaymentNotAllowed && transaction.error.code != SKErrorPaymentCancelled) {
                    NSString *title = [NSString stringWithFormat:@"Store Error %ld", (long)transaction.error.code];
                    NSString *message;
                    
                    switch (transaction.error.code) {
                        case SKErrorUnknown:
                            message = NSLocalizedString(@"An unknown error occured.", nil);
                            break;
                            
                        case SKErrorClientInvalid:
                            message = NSLocalizedString(@"This client is not authorized to make in-app purchases.", nil);
                            break;

                        default:
                            message = transaction.error.localizedDescription;
                            break;
                    }

                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:title message:message];
                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil];

                    [self presentViewController:alert animated:YES completion:nil];
                }
                
                self.purchaseInProgress = NO;
                [queue finishTransaction:transaction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
                break;
            }
                
            case SKPaymentTransactionStatePurchasing: SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    self.purchaseInProgress = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    self.purchaseInProgress = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        NSString *title = [NSString stringWithFormat:@"Store Error %ld", (long)error.code];
        UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:title
                                                                       message:error.localizedDescription];
        
        [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil];
        
        [self presentViewController:alert animated:YES completion:nil];

        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

#pragma mark - Utils

- (void)purchasePremiumFonts:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.products.count > 0) {
            SKPayment *payment = [SKPayment paymentWithProduct:self.products[0]];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            self.purchaseInProgress = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        }
    });
} 

- (BOOL)purchased {
#if TESTING
    return NO;
#else
    return [PPSettings sharedSettings].purchasedPremiumFonts;
#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

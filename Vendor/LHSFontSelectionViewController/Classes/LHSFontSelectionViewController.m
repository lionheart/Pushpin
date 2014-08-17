//
//  LHFontSelectionViewController.m
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import "LHSFontSelectionViewController.h"
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <LHSCategoryCollection/UIFont+LHSAdditions.h>
#import <YHRoundBorderedButton/YHRoundBorderedButton.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";

@interface LHSFontSelectionViewController ()

@property (nonatomic) BOOL purchased;

- (NSAttributedString *)attributedFontNameString;
- (void)purchasePremiumFonts:(id)sender;
+ (NSString *)fontNameToDisplayName:(NSString *)fontName;

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
    self.currentFontName = [self.delegate fontNameForFontSelectionViewController:self];
    self.purchased = NO;
    
    self.fonts = [NSMutableArray array];
    self.fontsForSectionIndex = [NSMutableDictionary dictionary];
    self.sectionIndexTitles = [NSMutableArray array];
    self.preferredStatusBarStyle = UIStatusBarStyleLightContent;
    
    if (self.onlyShowPreferredFonts) {
        
    }
    else {
        for (NSString *familyName in [UIFont familyNames]) {
            for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
                [self.fonts addObject:fontName];
                
                NSString *firstCharacter = [fontName substringToIndex:1];
                if (![self.sectionIndexTitles containsObject:firstCharacter]) {
                    [self.sectionIndexTitles addObject:firstCharacter];
                    self.fontsForSectionIndex[firstCharacter] = [NSMutableArray arrayWithObject:fontName];
                }
                else {
                    [self.fontsForSectionIndex[firstCharacter] addObject:fontName];
                }
            }
        }
        
        [self.sectionIndexTitles sortUsingSelector:@selector(compare:)];
        [self.fonts sortUsingSelector:@selector(compare:)];
        
        if (self.preferredFontNames.count > 0) {
            [self.sectionIndexTitles insertObject:@"-" atIndex:0];
            self.fontsForSectionIndex[@"-"] = self.preferredFontNames;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    NSArray *indexPathForCurrentlySelectedFont = [self indexPathsForFontName:self.currentFontName];
    
    if (self.preferredFontNames.count == 0) {
        [self.tableView scrollToRowAtIndexPath:[indexPathForCurrentlySelectedFont firstObject]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }

    if (!self.purchased) {
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[@"com.lionheartsw.Pushpin.PremiumFonts"]]];
        request.delegate = self;
        [request start];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.onlyShowPreferredFonts) {
        return 1;
    }
    else {
        return self.sectionIndexTitles.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.onlyShowPreferredFonts) {
        if (self.purchased) {
            return self.preferredFontNames.count;
        }
        else {
            return 1;
        }
    }
    else {
        NSString *sectionName = self.sectionIndexTitles[section];
        if (section == 0 && !self.purchased) {
            return 1;
        }
        else {
            return [self.fontsForSectionIndex[sectionName] count];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.preferredFontNames.count > 0 && section == 0) {
        return @"Premium Fonts";
    }
    return self.sectionIndexTitles[section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.preferredFontNames.count > 0 && section == 0) {
        return @"Tap to restore previous purchase.";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    if (!self.purchased && indexPath.section == 0 && indexPath.row == 0) {
        CGRect rect = [[self attributedFontNameString] boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.tableView.frame) - 40, CGFLOAT_MAX)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                    context:nil];
        height = CGRectGetHeight(rect);
    }
    else {
        NSString *fontName;
        if (self.onlyShowPreferredFonts) {
            fontName = self.preferredFontNames[indexPath.row];
        }
        else {
            NSString *sectionName = self.sectionIndexTitles[indexPath.section];
            fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
        }
        UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
        height = [fontName sizeWithAttributes:@{NSFontAttributeName: font}].height;
    }
    return MAX(10, height) + 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.textLabel.font = nil;
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = nil;
    [cell.contentView lhs_removeSubviews];
    
    NSString *fontName;
    if (self.onlyShowPreferredFonts) {
        fontName = self.preferredFontNames[indexPath.row];
    }
    else {
        NSString *sectionName = self.sectionIndexTitles[indexPath.section];
        fontName = self.fontsForSectionIndex[sectionName][indexPath.row];
    }

    UIFont *font = [UIFont fontWithName:fontName size:[self.delegate fontSizeForFontSelectionViewController:self] + 4];
    
    NSString *fontDisplayName = [LHSFontSelectionViewController fontNameToDisplayName:[font lhs_displayName]];
    
    if (!self.purchased && indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.attributedText = [self attributedFontNameString];
        cell.textLabel.numberOfLines = 0;

        BOOL displayPriceButton = YES;
        if (displayPriceButton) {
            YHRoundBorderedButton *priceButton = [[YHRoundBorderedButton alloc] init];
            priceButton.tag = indexPath.row;
            [priceButton setTitle:@"$1.99" forState:UIControlStateNormal];
            [priceButton addTarget:self action:@selector(priceButtonDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            [priceButton sizeToFit];
            priceButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            [cell.contentView addSubview:priceButton];
            [cell.contentView lhs_addConstraints:@"[view(width)]-8-|"
                                         metrics:@{@"width": @(CGRectGetWidth(priceButton.frame)) }
                                           views:@{@"view": priceButton}];
            [cell.contentView lhs_centerVerticallyForView:priceButton];
        }
    }
    else {
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
    }
    else {
        return self.sectionIndexTitles;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.preferredFontNames.count > 0 && !self.purchased && indexPath.section == 0) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
    else {
        NSArray *indexPathsForPreviouslySelectedFont = [self indexPathsForFontName:self.currentFontName];
        
        NSString *fontName;
        if (self.onlyShowPreferredFonts) {
            fontName = self.preferredFontNames[indexPath.row];
        }
        else {
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
    }
    else {
        if (self.preferredFontNames.count > 0) {
            if ([self.preferredFontNames containsObject:fontName]) {
                row = [self.preferredFontNames indexOfObject:fontName];
                section = 0;
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
        
        NSString *firstCharacter = [fontName substringToIndex:1];
        section = [self.sectionIndexTitles indexOfObject:firstCharacter];
        row = [self.fontsForSectionIndex[firstCharacter] indexOfObject:fontName];
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
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
    
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                [queue finishTransaction:transaction];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                message:@"Thank you for your purchase."
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
                break;
            }
                
            case SKPaymentTransactionStateRestored:
                [queue finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed: {
                // iOS already displays an error prompt when IAPs are restricted.
                if (transaction.error.code != SKErrorPaymentNotAllowed && transaction.error.code != SKErrorPaymentCancelled) {
                    NSString *title = [NSString stringWithFormat:@"Store Error %ld", (long)transaction.error.code];
                    NSString *message;
                    
                    switch (transaction.error.code) {
                        case SKErrorUnknown:
                            message = @"An unknown error occured.";
                            break;
                            
                        case SKErrorClientInvalid:
                            message = @"This client is not authorized to make in-app purchases.";
                            break;
                            
                        default:
                            message = transaction.error.localizedDescription;
                            break;
                    }
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                    [alert show];
                }
                [queue finishTransaction:transaction];
                break;
            }
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = [NSString stringWithFormat:@"Store Error %ld", (long)error.code];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];

        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

#pragma mark - Utils

- (void)purchasePremiumFonts:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    });
}

@end

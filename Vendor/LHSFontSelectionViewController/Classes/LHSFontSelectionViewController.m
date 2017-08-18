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

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
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

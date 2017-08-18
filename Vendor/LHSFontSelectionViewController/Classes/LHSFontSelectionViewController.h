//
//  LHFontSelectionViewController.h
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

@import StoreKit;
@import UIKit;

#import "LHSFontSelecting.h"

@interface LHSFontSelectionViewController : UITableViewController

@property (nonatomic) BOOL onlyShowPreferredFonts;
@property (nonatomic, strong) NSMutableArray *preferredFontNames;
@property (nonatomic, strong) NSMutableArray *fonts;
@property (nonatomic, strong) NSString *currentFontName;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) NSMutableArray *sectionIndexTitles;
@property (nonatomic, strong) NSMutableDictionary *fontsForSectionIndex;
@property (nonatomic, strong) UIAlertController *sizeAdjustmentActionSheet;
@property (nonatomic, strong) id<LHSFontSelecting> delegate;

- (NSArray *)indexPathsForFontName:(NSString *)fontName;
- (instancetype)initWithPreferredFontNames:(NSArray *)fontNames
                    onlyShowPreferredFonts:(BOOL)onlyShowPreferredFonts;

+ (NSString *)fontNameToDisplayName:(NSString *)fontName;

@end

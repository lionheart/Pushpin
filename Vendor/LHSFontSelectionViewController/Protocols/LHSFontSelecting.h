//
//  LHFontSelecting.h
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

@import Foundation;

@class LHSFontSelectionViewController;

@protocol LHSFontSelecting <NSObject>

- (NSString *)fontNameForFontSelectionViewController:(LHSFontSelectionViewController *)viewController;
- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHSFontSelectionViewController *)viewController;
- (CGFloat)fontSizeForFontSelectionViewController:(LHSFontSelectionViewController *)viewController;

@end

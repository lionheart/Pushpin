//
//  LHFontSelecting.h
//  LHFontSelectionViewController
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import <Foundation/Foundation.h>

@class LHFontSelectionViewController;

@protocol LHSFontSelecting <NSObject>

- (NSString *)fontNameForFontSelectionViewController:(LHFontSelectionViewController *)viewController;
- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHFontSelectionViewController *)viewController;
- (CGFloat)fontSizeForFontSelectionViewController:(LHFontSelectionViewController *)viewController;

@end

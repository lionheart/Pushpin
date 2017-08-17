//
//  PPEditDescriptionViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import UIKit;
@import LHSKeyboardAdjusting;

@class PPEditDescriptionViewController;

@protocol PPDescriptionEditing <NSObject>

@required

- (void)editDescriptionViewControllerDidUpdateDescription:(PPEditDescriptionViewController *)editDescriptionViewController;

@end

@interface PPEditDescriptionViewController : UIViewController <UITextViewDelegate, LHSKeyboardAdjusting>

@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) id<PPDescriptionEditing> delegate;

- (id)initWithDescription:(NSString *)description;

@end

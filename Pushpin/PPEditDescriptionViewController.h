//
//  PPEditDescriptionViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import UIKit;
#import <TextExpander/SMTEDelegateController.h>

@class PPEditDescriptionViewController;

@protocol PPDescriptionEditing <NSObject>

@required

- (void)editDescriptionViewControllerDidUpdateDescription:(PPEditDescriptionViewController *)editDescriptionViewController;

@end

@interface PPEditDescriptionViewController : UIViewController <UITextViewDelegate, SMTEFillDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) id<PPDescriptionEditing> delegate;
@property (nonatomic) BOOL textExpanderSnippetExpanded;
@property (nonatomic, strong) SMTEDelegateController *textExpander;

- (id)initWithDescription:(NSString *)description;

@end

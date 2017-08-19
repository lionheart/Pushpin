//
//  PPEditDescriptionViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import LHSCategoryCollection;
@import LHSKeyboardAdjusting;

#import "PPEditDescriptionViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"

@interface PPEditDescriptionViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

- (void)fixTextView:(UITextView *)textView;

@end

@implementation PPEditDescriptionViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithDescription:(NSString *)description {
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.title = NSLocalizedString(@"Description", nil);
        
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
        
        PPSettings *settings = [PPSettings sharedSettings];

        self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
        self.textView.translatesAutoresizingMaskIntoConstraints = NO;
        self.textView.autocorrectionType = [settings autoCorrectionType];
        self.textView.autocapitalizationType =  [settings autoCapitalizationType];
        self.textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        self.textView.font = font;
        self.textView.text = description;
        self.textView.delegate = self;

        [self.view addSubview:self.textView];

        self.bottomConstraint = [self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
        self.bottomConstraint.active = YES;
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    NSDictionary *views = @{@"guide": self.topLayoutGuide,
                            @"text": self.textView};

    [self.view lhs_addConstraints:@"V:[guide][text]" views:views];
    [self.view lhs_addConstraints:@"H:|[text]|" views:views];
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.textView becomeFirstResponder];

    [self lhs_activateKeyboardAdjustment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self lhs_deactivateKeyboardAdjustment];
    [self.delegate editDescriptionViewControllerDidUpdateDescription:self];
}

#pragma mark - LHSKeyboardAdjusting

- (UIView *)keyboardAdjustingView {
    return self.textView;
}

- (BOOL)keyboardAdjustingAnimated {
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)fixTextView:(UITextView *)textView {
    [textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

#pragma mark - SMTEFillDelegate

- (NSString *)identifierForTextArea:(id)uiTextObject {
    return @"textarea";
}

- (id)makeIdentifiedTextObjectFirstResponder:(NSString *)textIdentifier
                             fillWasCanceled:(BOOL)userCanceledFill
                              cursorPosition:(NSInteger *)ioInsertionPointLocation {
    return nil;
}

@end

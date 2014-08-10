//
//  PPEditDescriptionViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

#import "PPEditDescriptionViewController.h"
#import "PPAppDelegate.h"
#import "PPTheme.h"
#import "PPSettings.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSKeyboardAdjusting/UIViewController+LHSKeyboardAdjustment.h>

@interface PPEditDescriptionViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic) BOOL textExpanderEnabled;

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

        // TextExpander SDK
        self.textExpanderEnabled = [SMTEDelegateController expansionStatusForceLoad:NO
                                                                       snippetCount:0
                                                                           loadDate:nil
                                                                              error:nil];
        if (self.textExpanderEnabled) {
            self.textExpander = [[SMTEDelegateController alloc] init];
            self.textExpander.nextDelegate = self;
            self.textView.delegate = self.textExpander;
        }
        else {
            self.textView.delegate = self;
        }
        
        [self.view addSubview:self.textView];
        
        self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0];
        [self.view addConstraint:self.bottomConstraint];
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

- (NSLayoutConstraint *)keyboardAdjustingBottomConstraint {
    return self.bottomConstraint;
}

#pragma mark - UITextViewDelegate

- (void)fixTextView:(UITextView *)textView {
    [textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.textExpanderEnabled && self.textExpanderSnippetExpanded) {
        [self performSelector:@selector(fixTextView:) withObject:textView afterDelay:0.01];
        self.textExpanderSnippetExpanded = NO;
    }
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.textExpanderEnabled && self.textExpander.isAttemptingToExpandText) {
        self.textExpanderSnippetExpanded = YES;
    }

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

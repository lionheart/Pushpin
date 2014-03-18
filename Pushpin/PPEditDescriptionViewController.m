//
//  PPEditDescriptionViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

#import "PPEditDescriptionViewController.h"
#import "AppDelegate.h"
#import "PPTheme.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIViewController+LHSKeyboardAdjustment.h>

@interface PPEditDescriptionViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) UIKeyCommand *goBackKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

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
        
        // TextExpander SDK
        self.textExpander = [[SMTEDelegateController alloc] init];
        self.textExpander.nextDelegate = self;

        self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
        self.textView.translatesAutoresizingMaskIntoConstraints = NO;
        self.textView.autocorrectionType = [AppDelegate sharedDelegate].enableAutoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType =  [AppDelegate sharedDelegate].enableAutoCapitalize ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone;
        self.textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        self.textView.font = font;
        self.textView.delegate = self.textExpander;
        self.textView.text = description;
        
        [self.view addSubview:self.textView];
        
        self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
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

- (void)viewDidLoad {
    [super viewDidLoad];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.textView becomeFirstResponder];

    [self lhs_activateKeyboardAdjustment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self lhs_deactivateKeyboardAdjustment];
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
    if (self.textExpanderSnippetExpanded) {
        [self performSelector:@selector(fixTextView:) withObject:textView afterDelay:0.01];
        self.textExpanderSnippetExpanded = NO;
    }

    [self.delegate editDescriptionViewControllerDidUpdateDescription:self];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.textExpander.isAttemptingToExpandText) {
        self.textExpanderSnippetExpanded = YES;
    }

    return YES;
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.goBackKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.goBackKeyCommand) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

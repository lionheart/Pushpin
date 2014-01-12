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

@interface PPEditDescriptionViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

- (void)fixTextView:(UITextView *)textView;
- (void)keyboardWillHide:(NSNotification *)sender;
- (void)keyboardDidShow:(NSNotification *)sender;

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
        BOOL isIPad = [UIApplication isIPad];
        CGFloat offset;
        if (isIPad) {
            offset = 75;
        }
        else {
            offset = 225;
        }
        
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.textView becomeFirstResponder];
}

- (void)keyboardDidShow:(NSNotification *)sender {
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[AppDelegate sharedDelegate].window];
    
    self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    [self.view layoutIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)sender {
    self.bottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
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

@end

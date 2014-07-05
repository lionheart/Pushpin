//
//  PPLicenseViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/11/14.
//
//

#import "PPPlainTextViewController.h"
#import "PPTheme.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface PPPlainTextViewController ()

@property (nonatomic, strong) UITextView *textView;

- (instancetype)initWithString:(NSString *)license;

@end

@implementation PPPlainTextViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithString:(NSString *)text {
    self = [super init];
    if (self) {
        self.text = text;
    }
    return self;
}

+ (instancetype)plainTextViewControllerWithString:(NSString *)license {
    return [[self alloc] initWithString:license];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.textView = [[UITextView alloc] init];
    self.textView.textContainerInset = UIEdgeInsetsMake(5, 3, 5, 3);
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.text = self.text;
    self.textView.font = [PPTheme descriptionFont];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.textView];
    
    NSDictionary *views = @{@"text": self.textView,
                            @"top": self.topLayoutGuide,
                            @"bottom": self.bottomLayoutGuide };
    [self.view lhs_addConstraints:@"H:|[text]|" views:views];
    [self.view lhs_addConstraints:@"V:[top][text][bottom]" views:views];
}

- (void)setText:(NSString *)text {
    self.textView.text = text;
}

@end

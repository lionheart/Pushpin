//
//  PPLicenseViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/11/14.
//
//

@import LHSCategoryCollection;

#import "PPPlainTextViewController.h"
#import "PPTheme.h"

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
    
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.textView = [[UITextView alloc] init];
    self.textView.textContainerInset = UIEdgeInsetsMake(5, 3, 5, 3);
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.text = self.text;
    self.textView.font = [PPTheme descriptionFont];
//    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.frame = self.view.frame;
    
    [self.view addSubview:self.textView];
//    [self.textView lhs_expandToFillSuperview];
}

- (void)setText:(NSString *)text {
    self.textView.text = text;
}

@end

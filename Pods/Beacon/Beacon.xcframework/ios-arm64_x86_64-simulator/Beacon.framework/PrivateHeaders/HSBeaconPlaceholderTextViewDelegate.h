#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconPlaceholderTextViewDelegate: NSObject <UITextViewDelegate>

@property(nonatomic, nonnull) NSString *placeholder;
@property(nonatomic, weak, nullable) id<UITextViewDelegate> wrappedDelegate;

- (instancetype _Nullable)initWithPlaceholder: (NSString * _Nonnull)placeholder;

- (instancetype _Nullable)initWithPlaceholder:(NSString *_Nonnull)placeholder textView:(UITextView *_Nonnull)textView;

- (void)checkForPlaceholder:(UITextView *)textView;
- (BOOL)isDisplayingPlaceholderInTextView:(UITextView *)textView;

@end

NS_ASSUME_NONNULL_END

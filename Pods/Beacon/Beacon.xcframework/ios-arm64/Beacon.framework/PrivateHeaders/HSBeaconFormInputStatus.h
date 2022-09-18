#import <UIKit/UIKit.h>

@interface HSBeaconFormInputStatus : NSObject

- (instancetype)initWithInputs:(NSArray<id<UITextInput>> *)inputs;

- (id<UITextInput>)first;

- (id<UITextInput>)last;

- (NSUInteger)indexOf:(id<UITextInput>)input;

- (void)next:(NSUInteger)index;

- (void)prev:(NSUInteger)index;

- (NSUInteger)count;

@end

#import <UIKit/UIKit.h>

@interface HSBeaconFormInputStatus : NSObject

- (instancetype)initWithInputs:(NSArray<id<UITextInput>> *)inputs;

- (id<UITextInput>)first;

- (id<UITextInput>)last;

- (long)indexOf:(id<UITextInput>)input;

- (void)next:(long)index;

- (void)prev:(long)index;

- (long)count;

@end

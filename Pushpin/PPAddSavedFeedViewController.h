//
//  PPAddSavedFeedViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/30/13.
//
//

#import "PPTableViewController.h"
#import "AppDelegate.h"

@interface PPAddSavedFeedViewController : PPTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *userTextField;
@property (nonatomic, strong) UITextField *tagsTextField;
@property (nonatomic, copy) void (^SuccessCallback)();

- (void)addButtonTouchUpInside:(id)sender;
- (void)closeButtonTouchUpInside:(id)sender;

@end

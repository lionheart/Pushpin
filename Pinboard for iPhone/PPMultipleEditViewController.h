//
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTableViewController.h"

@interface PPMultipleEditViewController : PPTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *tagsToAddTextField;

@property (nonatomic, strong) NSMutableArray *tagsToAddCompletions;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableArray *tagsToRemove;
@property (nonatomic, strong) NSMutableArray *tagsToAdd;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic) BOOL autocompleteInProgress;

- (id)initWithTags:(NSArray *)tags;
- (void)tagsToAddTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string;

@end

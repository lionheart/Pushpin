//
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTagEditViewController.h"

typedef NS_ENUM(NSInteger, PPMultipleEditSectionType) {
    PPMultipleEditSectionAddedTags,
    PPMultipleEditSectionExistingTags,
    PPMultipleEditSectionDeletedTags
};

enum : NSInteger {
    PPMultipleEditSectionCount = PPMultipleEditSectionExistingTags + 1,
};

@interface PPMultipleEditViewController : UIViewController <UITextFieldDelegate, PPTagEditing, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITextField *tagsToAddTextField;

@property (nonatomic, strong) NSArray *bookmarks;
@property (nonatomic, strong) NSMutableOrderedSet *existingTags;
@property (nonatomic, strong) NSMutableOrderedSet *tagsToRemove;
@property (nonatomic, strong) NSMutableArray *tagsToAdd;

- (id)initWithBookmarks:(NSArray *)bookmarks;

@end

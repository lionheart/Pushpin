#import <UIKit/UIKit.h>

#import "HSBeaconCustomFieldDefinition.h"
#import "HSBeaconCustomFieldValue.h"
#import "HSBeaconContext.h"

@protocol HSBeaconCustomFieldsEntryControllerDelegate

- (void)customFieldsFormEnableSubmit:(BOOL)enabled;

- (void)showErrorMessage:(NSString *)errorMessage;

@end

@interface HSBeaconCustomFieldsEntryController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *topSeparator;
@property (weak, nonatomic) IBOutlet UIView *bottomSeparator;

@property (nonatomic, strong) HSBeaconContext *beaconContext;
@property (nonatomic, strong) HSBeaconContactForm *prefilledForm;

@property (readwrite, nonatomic) NSArray<HSBeaconCustomFieldDefinition *> *fieldDefinitions;
@property (readonly, nonatomic) NSArray<HSBeaconCustomFieldValue *> *fieldValues;
@property (nonatomic) id<HSBeaconCustomFieldsEntryControllerDelegate> delegate;

- (BOOL)validateFieldsWithErrorsDisplayed:(BOOL)showErrors;

- (void)clearFields;

- (NSArray<UITextView *> *)textViews;

@end

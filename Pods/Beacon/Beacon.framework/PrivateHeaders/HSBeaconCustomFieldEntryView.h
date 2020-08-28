#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconCustomFieldDefinition.h"
#import "HSBeaconCustomFieldValue.h"
#import "HSBeaconPlaceholderTextViewDelegate.h"
#import "HSBeaconContext.h"

@class HSBeaconCustomFieldEntryView;

@protocol HSBeaconCustomFieldEntryViewDelegate

- (void)customFieldValueChanged:(HSBeaconCustomFieldEntryView *)view;

@end

@interface HSBeaconCustomFieldEntryView : HSView

@property (nonatomic, strong) HSBeaconContext *beaconContext;

@property (readonly, nonatomic) HSBeaconCustomFieldDefinition *fieldDefinition;
@property (readonly, nonatomic) HSBeaconCustomFieldValue *fieldValue;
@property (readonly, nonatomic) HSBeaconPlaceholderTextViewDelegate *placeholderDelegate;
@property (nonatomic) UITextView *field;
@property (nonatomic) id<HSBeaconCustomFieldEntryViewDelegate> delegate;

-(void)setFieldDefinition:(HSBeaconCustomFieldDefinition *)fieldDefinition value:(HSBeaconCustomFieldValue *)value;

- (BOOL)isFieldValid;

- (void)valueChanged;

- (void)clearField;

- (void)showError;

- (void)clearError;

@end

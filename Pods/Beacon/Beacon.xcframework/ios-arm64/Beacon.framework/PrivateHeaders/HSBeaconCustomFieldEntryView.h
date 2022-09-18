#import <UIKit/UIKit.h>
#import <Beacon/HSView.h>
#import <Beacon/HSBeaconCustomFieldDefinition.h>
#import <Beacon/HSBeaconCustomFieldValue.h>
#import <Beacon/HSBeaconPlaceholderTextViewDelegate.h>
#import <Beacon/HSBeaconContext.h>

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
@property (nonatomic, weak) id<HSBeaconCustomFieldEntryViewDelegate> delegate;

- (void)setFieldDefinition:(HSBeaconCustomFieldDefinition *)fieldDefinition value:(HSBeaconCustomFieldValue *)value;

- (BOOL)isFieldValid;

- (void)valueChanged;

- (void)clearField;

- (void)showError;

- (void)clearError;

@end

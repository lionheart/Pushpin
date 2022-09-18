#import <Foundation/Foundation.h>

@class HSBeaconSettings;

NS_ASSUME_NONNULL_BEGIN
/**
 A file attached to the new conversation contact form.
 */
@protocol HSBeaconContactFormAttachment

/**
 The attachment filename
 */
- (NSString *) filename;

/**
 The raw content of the attached file.
 */
- (nullable NSData *) data;

@end

/**
 A model object representing a new conversation. Values set on this are prepopulated in the
 new conversation contact form.
 */
@interface HSBeaconContactForm : NSObject

/**
 The `HSBeaconContactForm` initializer is not publicly available. Beacon SDK will create the form and pass it
 via delegate methods when required.
 */
- (instancetype) init __attribute__((unavailable("init not available")));

/**
 The ID of the Beacon that's being prefilled. Useful if you have multiple Beacons in your app
 and need different prefill logic for each one.
 */
@property(strong, nonatomic, readonly) NSString *beaconID;

/**
 The customer email. This will be ignored if secure mode is used or if the customer has previously
 sent a message through the Beacon SDK. Unlike the email set in the `login` method, this value
 will be editable for the customer.
 */
@property(strong, nonatomic) NSString *email;

/**
 The customer name. This will be ignored if the user has previously sent a message through the Beacon SDK.
 Unlike the name set in the `login` method, this value will be editable for the customer.
 */
@property(strong, nonatomic, nullable) NSString *name;

/**
 The message subject
 */
@property(strong, nonatomic, nullable) NSString *subject;

/**
 The body text for the email.
 */
@property(strong, nonatomic, nullable) NSString *text;

/**
 Read only dictionary of the custom fields ids and values set on this object
 */
@property(strong, readonly, nonatomic) NSDictionary<NSNumber*, NSString*> *customFields;

/**
 Read only array of the files attached to this object.
 */
@property(readonly) NSArray<id<HSBeaconContactFormAttachment>> *attachments;

/**
 Adds a new attachment to this object. There is a maximum of 3 attachments allowed. Any calls
 after the first 3 will be ignored and the method will return `NO`.
 */
- (BOOL)addAttachment:(NSString *)filename data:(NSData *)data;

/**
 Adds a prefilled custom field value to the form.
 
 For dropdown fields, set this to the id of the value you want to select.
 
 For date fields, use yyyy-MM-dd style.
 */
- (void)addCustomFieldValue:(NSString *)value forId:(int)fieldId;

NS_ASSUME_NONNULL_END

@end

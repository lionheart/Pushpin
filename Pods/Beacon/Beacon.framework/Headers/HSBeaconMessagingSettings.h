#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `HSBeaconMessagingSettings` contains settings specific to the messaging portions
 of Beacon. After creating and configuring a messaging settings object, you can
 set `messagingSettings` on `HSBeaconSettings` with it.
 */
@interface HSBeaconMessagingSettings : NSObject

/**
 Disable contact form custom fields if enabled in the Beacon config.

 This will not enable custom fields if disabled in the config.
 */
@property (nonatomic) BOOL contactFormCustomFieldsEnabled;

/**
 Display an editable Name field.
 */
@property (nonatomic) BOOL contactFormShowNameField;

/**
 Was contactFormShowNameField set with a local override.
 */
@property (nonatomic, readonly) BOOL contactFormShowNameFieldSet;

/**
 Display an editable Subject field.
 */
@property (nonatomic) BOOL contactFormShowSubjectField;

/**
 Was contactFormShowSubjectFieldSet set with a local override.
 */
@property (nonatomic, readonly) BOOL contactFormShowSubjectFieldSet;

/**
 Enable or disable file attachments.
 */
@property (nonatomic) BOOL contactFormAllowAttachments;

/**
 Was contactFormAllowAttachmentsSet set with a local override.
 */
@property (readonly, nonatomic) BOOL contactFormAllowAttachmentsSet;

/**
 Show a contact link on the Beacon home screen.
 */
@property (nonatomic) BOOL showGetInTouch;

/**
 Was showGetInTouchSet set with a local override.
 */
@property (readonly, nonatomic) BOOL showGetInTouchSet;

/**
 When custom field values are pre-filled, set to true to make them visible.
 */
@property (nonatomic) BOOL showPrefilledCustomFields;


@end

NS_ASSUME_NONNULL_END

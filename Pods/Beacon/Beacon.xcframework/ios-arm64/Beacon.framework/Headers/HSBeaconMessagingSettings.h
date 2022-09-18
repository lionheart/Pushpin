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
 Was contactFormShowSubjectField set with a local override.
 */
@property (nonatomic, readonly) BOOL contactFormShowSubjectFieldSet;

/**
 Enable or disable file attachments.
 */
@property (nonatomic) BOOL contactFormAllowAttachments;

/**
 Returns whether `contactFormAllowAttachments` was set with a local override.
 */
@property (readonly, nonatomic) BOOL contactFormAllowAttachmentsSet;

/**
 Show a contact link on the Beacon home screen.
 */
@property (nonatomic) BOOL showGetInTouch DEPRECATED_MSG_ATTRIBUTE("Beacon 2.1 no longer shows contact links on the home screen.  To customize the home screen experience take a look at `HSBeaconSettings.focusModeOverride`");

/**
 Returns whether `showGetInTouch` was set with a local override.
 */
@property (readonly, nonatomic) BOOL showGetInTouchSet DEPRECATED_MSG_ATTRIBUTE("Beacon 2.1 no longer shows contact links on the home screen.  To customize the home screen experience take a look at `HSBeaconSettings.focusModeOverride`");

/**
 By default, prefilled custom fields will be hidden so that the prefilled values cannot be edited. Set this to true to display them and make them editable.

 @note If a draft has been entered into the contact form, the prefill process will be skipped in favor of using the draft values. Draft messages can be cleared by calling the `reset` function on `HSBeacon`.
 */
@property (nonatomic) BOOL showPrefilledCustomFields;


@end

NS_ASSUME_NONNULL_END

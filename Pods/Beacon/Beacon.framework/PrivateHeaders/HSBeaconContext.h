#import <Foundation/Foundation.h>

#import "HSBeaconActivityLog.h"
#import "HSBeaconCloudFrontAPIClient.h"
#import "HSBeaconConfig.h"
#import "HSBeaconDocsAPIClient.h"
#import "HSBeaconEmailMessage.h"
#import "HSBeaconKeychainWrapper.h"
#import "HSBeaconLocalizedStrings.h"
#import "HSBeaconMessagingAPIClient.h"
#import "HSBeaconReplyNotificationPayload.h"
#import "HSBeaconSecurityInfo.h"
#import "HSBeaconSuggestionItem.h"
#import "HSBeaconTintColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconContext : NSObject

@property (strong, nonatomic) HSBeaconConfig *config;
@property (readonly, nonatomic) HSBeaconSettings *beaconSettings;
@property (readonly, nonatomic) HSBeaconTintColor *tintColorSettings;

/* these are readwrite for testing purposes */
@property (nonatomic) HSBeaconDocsAPIClient *docsApiClient;
@property (nonatomic) HSBeaconMessagingAPIClient *messagingApiClient;
@property (nonatomic) HSBeaconCloudFrontAPIClient *cloudFrontApiClient;
@property (nonatomic) id<HSBeaconStringLocalizer> localizedStrings;

@property (readonly, nonatomic) HSBeaconActivityLog *activityLog;
@property (readonly, nonatomic) HSBeaconSecurityInfo *securityInfo;
@property (readonly, nonatomic) HSBeaconKeychainWrapper *keychainWrapper;

@property (readonly, nonatomic) NSMutableDictionary<NSNumber *, HSBeaconReplyMessage *> *draftReplies;
@property (readonly, nonatomic) BOOL messagingEnabled;
@property (readonly, nonatomic) BOOL docsOnly;
@property (readonly, nonatomic) BOOL docsEnabled;
@property (readonly, nonatomic) BOOL messagingOnly;
@property (readonly, nonatomic) BOOL validConfig;

@property (readonly, nonatomic) BOOL showNameEnabled;
@property (readonly, nonatomic) BOOL showSubjectEnabled;
@property (readonly, nonatomic) BOOL attachmentsEnabled;
@property (readonly, nonatomic) BOOL customFieldsEnabled;
@property (readonly, nonatomic) BOOL showGetInTouchEnabled;
@property (readonly, nonatomic) UIColor *tintColor;

@property (strong, nonatomic) NSArray<id<HSBeaconSuggestionItem>> *customSuggestions;

@property (atomic) BOOL loadFailed;

@property (nonatomic) BOOL hasPreviousMessages;

@property (nullable) HSBeaconEmailMessage *draftMessage;

- (instancetype _Nonnull)initWithBeaconSettings:(HSBeaconSettings *_Nullable)beaconSettings user:(HSBeaconUser *_Nullable)user signature:(NSString *_Nullable)signature;

@end

NS_ASSUME_NONNULL_END

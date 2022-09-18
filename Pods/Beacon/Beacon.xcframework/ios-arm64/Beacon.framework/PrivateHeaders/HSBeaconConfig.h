#import <Foundation/Foundation.h>
#import <Beacon/HSBeaconFocusMode.h>

NS_ASSUME_NONNULL_BEGIN

/*
 This object corresponds to the server sent Beacon config
 https://paper.dropbox.com/doc/Spec-Beacon-2.0-API-Overview-0gznyGQC5bQON2MgBJcmU#:uid=123368913575149170552582&h2=GET-Beacon
 */
@interface HSBeaconConfig: NSObject

@property (readonly, nonatomic) NSString *beaconId;

@property (readonly, nonatomic) NSString *companyName;

@property (readonly, nonatomic) NSString *name;

@property (readonly, nonatomic) NSString *beaconColorHexValue;

@property (readonly, nonatomic) BOOL secureModeEnabled;

@property (readonly, nonatomic) BOOL docsEnabled;

@property (readonly, nonatomic) BOOL messagingEnabled;

@property (readonly, nonatomic) BOOL chatEnabled;

@property (readonly, nonatomic) HSBeaconFocusMode focusMode;

@property (readonly, nonatomic) BOOL showNameEnabled;

@property (readonly, nonatomic) BOOL showSubjectEnabled;

@property (readonly, nonatomic) BOOL attachmentsEnabled;

@property (readonly, nonatomic) BOOL customFieldsEnabled;

@property (readonly, nonatomic) BOOL chatRequiresEmail;

@property (readonly, nonatomic) BOOL chatRatingsEnabled;

@property (readonly, nonatomic) BOOL emailTranscriptEnabled;

@property (readonly, nonatomic) NSString *expectedResponseTime;

@property (readonly, nonatomic) NSDictionary <NSString *, NSString *> *translations;

- (instancetype _Nonnull)initWithDictionary:(NSDictionary *_Nonnull)dictionary;

@end

NS_ASSUME_NONNULL_END

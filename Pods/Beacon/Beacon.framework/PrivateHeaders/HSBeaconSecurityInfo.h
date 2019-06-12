#import <Foundation/Foundation.h>

@class HSBeaconUser;
@class HSBeaconUserDeviceInfo;

@interface HSBeaconSecurityInfo : NSObject

@property (nonatomic) HSBeaconUser *user;
@property (nonatomic) NSString *signature;
@property (nonatomic) NSString *deviceId;
@property (nonatomic) BOOL signatureVerified;
@property (nonatomic, readonly) BOOL hasProvidedEmail;
@property (nonatomic, readonly) BOOL hasProvidedName;
@property (nonatomic, readonly) BOOL hasVisitorEmail;
@property (nonatomic, readonly) BOOL hasVisitorName;
@property (nonatomic) NSString *visitorName;
@property (nonatomic) NSString *visitorEmail;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *email;

-(BOOL)requiresSynchronization;

-(void)markSynchronized;

-(HSBeaconUserDeviceInfo *)userDeviceInfo;

-(BOOL)hasSignature;

-(BOOL)hasBeaconAuthorization;

-(BOOL)signatureMatches:(NSString *)signature;

@end

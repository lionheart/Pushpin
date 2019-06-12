#import <Foundation/Foundation.h>

@class HSBeaconSecurityInfo;

typedef void (^CompletionHandler)(void);
typedef void (^ErrorCompletionHandler)(NSError * _Nullable error);
typedef void (^BooleanCompletionHandler)(BOOL result, NSError * _Nullable error);
typedef void (^StringCompletionHandler)(NSString * _Nullable result, NSError * _Nullable error);
typedef void (^NetworkResponseCompletionHandler)(NSURLResponse *response, NSError * _Nullable error);
typedef void (^NetworkCompletionHandler)(NSDictionary * _Nullable result, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN
@interface HSBeaconBaseAPIClient: NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *beaconId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSURLSession *beaconSession;

- (instancetype)initWithBeaconId:(NSString *)beaconId deviceId: (NSString *)deviceId;

/* this constructor is only used for testing */
- (instancetype)initWithBeaconId:(NSString *)beaconId session:(NSURLSession *)session;

- (NSURLSessionDataTask *)performGETRequestForURL:(NSURL *)url completion:(NetworkCompletionHandler)completion;

- (NSURLSessionDataTask *)performGETRequest:(NSURLRequest *)request completion:(NetworkCompletionHandler)completion;

- (NSURLSessionDataTask *)performPUTRequestForURL:(NSURL *)url body:(NSDictionary *)body securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (void)addBeaconAuthHeader:(HSBeaconSecurityInfo *)securityInfo request:(NSMutableURLRequest *)request;

- (NSError * _Nullable)errorFor:(NSData *)data response:(NSHTTPURLResponse *)response error:(NSError *)connectionError;

- (NSString *)apiRootOverride;

@end
NS_ASSUME_NONNULL_END

#import <Beacon/HSBeaconBaseAPIClient.h>

@class HSBeaconAgent;

@interface HSBeaconChatAPIClient : HSBeaconBaseAPIClient

- (nullable NSURLSessionDataTask *)fetchAvailableAgentsWithCompletionHandler:(void (^_Nonnull)(NSArray<HSBeaconAgent *> * _Nullable agents))completion;

@end

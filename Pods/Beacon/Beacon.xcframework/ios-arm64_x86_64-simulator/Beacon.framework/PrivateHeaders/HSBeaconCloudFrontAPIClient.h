#import <Beacon/HSBeaconBaseAPIClient.h>

@class HSBeaconConfig;
@class HSBeaconSuggestion;
@class HSBeaconAgent;

@interface HSBeaconCloudFrontAPIClient : HSBeaconBaseAPIClient

- (NSURLSessionDataTask *)fetchBeaconConfigWithCompletionHandler:(void (^)(HSBeaconConfig *config, NSError *error))completion;

- (NSURLSessionDataTask *)fetchSuggestionsWithCompletionHandler:(void (^)(NSArray<HSBeaconSuggestion *> *suggestions, NSError *error))completion;

- (NSURLSessionDataTask *)fetchAgentsWithCompletionHandler:(void (^)(NSArray<HSBeaconAgent *> *agents, NSError *error))completion;

@end

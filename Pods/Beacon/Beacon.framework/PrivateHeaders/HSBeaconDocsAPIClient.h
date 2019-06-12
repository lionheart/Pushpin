#import <Foundation/Foundation.h>
#import "HSBeaconConfig.h"
#import "HSBeaconArticleDetails.h"
#import "HSBeaconPaginatedResponse.h"
#import "HSBeaconArticleSearchResult.h"
#import "HSBeaconPaging.h"
#import "HSBeaconBaseAPIClient.h"
#import "HSBeaconSuggestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconDocsAPIClient : HSBeaconBaseAPIClient

- (NSURLSessionDataTask *)fetchArticle:(NSString *)articleId completionHandler: (void (^)(HSBeaconArticleDetails *_Nullable article, NSError *error))completion;

- (NSURLSessionDataTask *)fetchCustomSuggestions:(NSArray<NSString *> *)articleIds completionHandler:(void (^)(NSArray<HSBeaconSuggestion *> *articles, NSError *error))completion;

- (NSURLSessionDataTask *)fetchSearchResults:query page:(int)page completionHandler:(void (^)(HSBeaconPaginatedResponse *_Nullable results, NSError *error)) completion;

@end

NS_ASSUME_NONNULL_END

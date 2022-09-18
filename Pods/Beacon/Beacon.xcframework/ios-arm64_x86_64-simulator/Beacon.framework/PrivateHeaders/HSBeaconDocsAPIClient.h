#import <Foundation/Foundation.h>
#import <Beacon/HSBeaconConfig.h>
#import <Beacon/HSBeaconArticleDetails.h>
#import <Beacon/HSBeaconPaginatedResponse.h>
#import <Beacon/HSBeaconArticleSearchResult.h>
#import <Beacon/HSBeaconPaging.h>
#import <Beacon/HSBeaconBaseAPIClient.h>
#import <Beacon/HSBeaconSuggestion.h>

typedef NS_ENUM(NSUInteger, HSBeaconArticleRating);

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconDocsAPIClient : HSBeaconBaseAPIClient

- (NSURLSessionDataTask *)fetchArticle:(NSString *)articleId securityInfo:(HSBeaconSecurityInfo *)securityInfo completionHandler: (void (^)(HSBeaconArticleDetails *_Nullable article, NSError *error))completion;

- (NSURLSessionDataTask *)fetchCustomSuggestions:(NSArray<NSString *> *)articleIds completionHandler:(void (^)(NSArray<HSBeaconSuggestion *> *articles, NSError *error))completion;

- (NSURLSessionDataTask *)fetchSearchResults:query page:(int)page completionHandler:(void (^)(HSBeaconPaginatedResponse *_Nullable results, NSError *error)) completion;

- (NSURLSessionDataTask *)rateArticle:(NSString *)articleId withRating:(HSBeaconArticleRating)rating securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (NSString *)stringForArticleRating:(HSBeaconArticleRating)rating;

@end

NS_ASSUME_NONNULL_END

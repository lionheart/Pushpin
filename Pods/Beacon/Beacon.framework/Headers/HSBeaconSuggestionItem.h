#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This protocol indicates an object can be passed into suggesiton overides via the
 `HSBeacon` `suggestWithItems:` method.
 */
@protocol HSBeaconSuggestionItem 

@end

/**
 Provide an article id for suggestion overrides. The article title and url is looked
 up from Help Scout before rendering the suggestion.
 */
@interface HSBeaconArticleSuggestion : NSObject  <HSBeaconSuggestionItem>

/**
 Initialize with the specified article id.

 Article IDs can be found in Help Scout by navigating to the article and copying the
 article ID from the URL. The URL is structured like this:
 https://secure.helpscout.net/docs/[COLLECTION ID]/article/[ARTICLE ID]/
 */
- (instancetype)initWithId:(NSString *)articleId;

/**
 The article id to look up and show in the suggestions table.
 */
@property (nonatomic, readonly) NSString *articleId;

#pragma mark - Unavailable Methods

/**
 HSBeaconArticleSuggestion objects are immutable, so always initialze with the articleId constructor.
 */
- (instancetype) __unavailable init;

@end

/**
 Provide an title and url for suggestion overrides. The url is opened in a modal using
 `SFSafariViewController`.
 */
@interface HSBeaconLinkSuggestion : NSObject  <HSBeaconSuggestionItem>

/**
 Initialize a link suggestion with the specified url and text.
 */
- (instancetype)initWithUrl:(NSURL *)url text:(NSString *)text;

/**
 The url the suggestion will open.
 */
@property (nonatomic, readonly) NSURL *url;

/**
 The text rendered in the suggestions table.
 */
@property (nonatomic, readonly) NSString *text;

#pragma mark - Unavailable Methods

/**
 HSBeaconLinkSuggestion objects are immutable, so always initialze with the url and text constructor.
 */
- (instancetype) __unavailable init;

@end

NS_ASSUME_NONNULL_END

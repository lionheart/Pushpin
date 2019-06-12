#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconArticleDetails: NSObject

@property (readonly, nonatomic, nonnull) NSString *identifier;
@property (readonly, nonatomic, nonnull) NSString *title;
@property (readonly, nonatomic, nullable) NSString *html;
@property (readonly, nonatomic, nullable) NSString *preview;
@property (readonly, nonatomic, nullable) NSURL *url;
@property (readonly, nonatomic, nonnull) NSDictionary *linkedArticleIdentifiers;
@property (readonly, nonatomic, nonnull) NSArray<HSBeaconArticleDetails *> *relatedArticles;

- (instancetype _Nonnull)initWithDictionary: (NSDictionary *_Nonnull)dictionary;

- (NSString * _Nullable)linkedArticleIdForUrl:(NSString *_Nonnull)url;

@end

NS_ASSUME_NONNULL_END

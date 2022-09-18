#import <Foundation/Foundation.h>

#import <Beacon/HSBeaconArticle.h>

@interface HSBeaconArticleSearchResult: HSBeaconArticle

- (instancetype)initWithDictionary: (NSDictionary *)dictionary;
- (NSString *)cleanPreview;

@end

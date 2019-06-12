#import <Foundation/Foundation.h>

#import "HSBeaconArticle.h"

@interface HSBeaconArticleSearchResult: HSBeaconArticle

@property (readonly, nonatomic) NSString *preview;

- (instancetype)initWithDictionary: (NSDictionary *)dictionary;

@end

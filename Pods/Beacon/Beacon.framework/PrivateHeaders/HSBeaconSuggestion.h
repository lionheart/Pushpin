#import <Foundation/Foundation.h>

#import "HSBeaconArticle.h"

@interface HSBeaconSuggestion: HSBeaconArticle

@property (readonly, nonatomic) NSURL *URL;
@property (readonly, nonatomic) NSString *type;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

-(instancetype)initWithCustomArticleSuggestion: (NSDictionary *)dictionary;

- (instancetype)initWithUrl:(NSURL *)url text:(NSString *)text;

-(BOOL)isArticle;

-(BOOL)isLink;

@end

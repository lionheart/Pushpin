#import <Foundation/Foundation.h>

#import <Beacon/HSBeaconArticle.h>

@interface HSBeaconSuggestion: HSBeaconArticle

@property (readonly, nonatomic) NSString *_Nonnull type;
@property (readonly, nonatomic) NSURL *_Nullable URL;

-(instancetype _Nonnull )initWithDictionary: (NSDictionary *_Nonnull)dictionary;

-(instancetype _Nonnull )initWithCustomArticleSuggestion: (NSDictionary *_Nonnull)dictionary;

-(instancetype _Nonnull )initWithUrl:(NSURL *_Nonnull)url text:(NSString *_Nonnull)text;

-(NSString *_Nonnull)cleanPreview;

-(BOOL)isArticle;

-(BOOL)isLink;

@end

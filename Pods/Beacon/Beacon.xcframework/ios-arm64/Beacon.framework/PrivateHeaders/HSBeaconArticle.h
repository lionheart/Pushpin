#import <Foundation/Foundation.h>

@interface HSBeaconArticle : NSObject

@property (readonly, nonatomic) NSString *articleId;
@property (readonly, nonatomic) NSString *title;

- (instancetype)initWithId:(NSString *)articleId title:(NSString *)title;

- (NSString *)cleanPreview:(NSString *)rawPreview trimmed:(BOOL)isTrimmed;

@end

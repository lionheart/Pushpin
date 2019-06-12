#import <Foundation/Foundation.h>

@interface HSBeaconHtmlUtilities : NSObject

+ (NSString *)sanitizeJavascript:(NSString *)unsanitized;
    
+ (NSString *)escapeHtml:(NSString *)unescaped;
    
@end

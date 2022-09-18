#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// WKWebView has an issue where `WKDataDetectorTypes` set on it's `WKWebViewConfiguration
/// will not be applied when passing HTML via `evaluateJavascript(:).
/// We've filed an issue with Apple as FB7527128 but in the meantime this class scans the body of a `ConversationThread`
/// and adds formatting for urls, emails and phone numbers.
@interface HSBeaconDataDetector : NSObject

- (NSString *)htmlForBody:(NSString *)body;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

@interface HSBeaconMaxLengthTruncator : NSObject

@property int maxLength;

- (instancetype _Nullable)initWithMaxLength:(int)maxLength;

/*!
 @brief checks if replacement string will need to be truncated
 
 @param originalText original string
 @param range range to insert over
 @param text full replacment text
 
 @return YES if text will need to be truncated, NO otherwise
 */
- (BOOL)requiresTruncation:(NSString * _Nonnull)originalText range:(NSRange)range replacementText:(NSString * _Nonnull)text;

/*!
 @brief Returns a shortened version of the replacement text that will fit in the allowed length
 
 @param originalText original string
 @param range range to insert over
 @param text full replacment text
 
 @return shortened version of the replacement text
 */

- (NSString * _Nonnull)truncateText:(NSString * _Nonnull)originalText range:(NSRange)range replacementText:(NSString * _Nonnull)text;

@end

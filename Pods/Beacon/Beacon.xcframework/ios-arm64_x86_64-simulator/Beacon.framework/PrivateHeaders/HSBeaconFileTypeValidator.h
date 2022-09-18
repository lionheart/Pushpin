#import <Foundation/Foundation.h>

@interface HSBeaconFileTypeValidator : NSObject

+ (BOOL)isInvalidFileExtension:(NSString *)filename;

@end

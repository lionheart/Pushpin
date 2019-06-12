#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconActivityLog: NSObject

- (void)addActivityOfType: (NSString *)type attributes: (NSDictionary *)dictionary;

- (NSArray<NSDictionary *> *)asArray;

- (void)clearLog;

@end

NS_ASSUME_NONNULL_END

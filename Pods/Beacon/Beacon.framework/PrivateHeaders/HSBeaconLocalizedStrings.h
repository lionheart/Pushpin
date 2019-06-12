#import <Foundation/Foundation.h>

@protocol HSBeaconStringLocalizer
- (void)updateLocalizationStringDictionary:(NSDictionary<NSString *, NSString *> *)strings;
@required
- (NSString *)localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconLocalizedStrings : NSObject <HSBeaconStringLocalizer>

@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *configStrings;
@property BOOL useLocalOverrides;

+ (NSString *)localizableStringFromApp:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

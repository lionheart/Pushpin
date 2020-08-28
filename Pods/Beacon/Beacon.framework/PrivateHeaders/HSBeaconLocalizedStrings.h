#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HSBeaconStringLocalizer
- (void)updateLocalizationStringDictionary:(NSDictionary<NSString *, NSString *> * )strings;
@required
- (NSString *)localizedStringForKey:(NSString *)key;

/// Returns a localized string by applying the given format to the localized string for the given key
/// @param key The ley for the localized string value where the resulting string has a format specifier of {{ name }} or %@
/// @param format The string to substitute in the localized string
- (NSString *)localizedStringForKey:(nonnull NSString *)key withFormat:(nonnull NSString *)format;
@end

@interface HSBeaconLocalizedStrings : NSObject <HSBeaconStringLocalizer>

@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *configStrings;
@property BOOL useLocalOverrides;

+ (NSString *)localizableStringFromApp:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

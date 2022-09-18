#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HSContactFieldType) {
    HSContactFieldTypeUnknown,
    HSContactFieldTypeName,
    HSContactFieldTypeEmail,
    HSContactFieldTypeSubject,
    HSContactFieldTypeBody
};

typedef NS_ENUM(NSUInteger, HSContactFieldValidationResult) {
    HSContactFieldValidationResultValid,
    HSContactFieldValidationResultInvalidLength,
    HSContactFieldValidationResultInvalidFormat
};

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconContactFormValidator : NSObject

+ (NSUInteger)maximumLengthForFieldType:(HSContactFieldType)fieldType;

+ (HSContactFieldValidationResult)validate:(HSContactFieldType)fieldType text:(NSString *)fieldText;

@end

NS_ASSUME_NONNULL_END

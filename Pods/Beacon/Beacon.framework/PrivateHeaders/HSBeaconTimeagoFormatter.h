#import <Foundation/Foundation.h>

#import "HSBeaconLocalizedStrings.h"

@interface HSBeaconTimeagoFormatter : NSObject

+ (NSString *)timeagoText:(NSDate *)date localizedStrings:(id<HSBeaconStringLocalizer>)localizedStrings;

@end

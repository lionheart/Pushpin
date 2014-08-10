//
//  AppSettings.m
//  AppSettings
//
//  Created by Kamil Burczyk on 08.12.2013.
//  Copyright (c) 2013 Sigmapoint. All rights reserved.
//

#import "AppSettings.h"
#import <objc/runtime.h>

@implementation AppSettings

#pragma mark - initializer
- (id)initWithDictionary:(NSDictionary*)dictionaryOfPropertiesAndValues
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dictionaryOfPropertiesAndValues];
    }
    return self;
}

#pragma mark - extracting data
- (NSArray*)propertiesNames
{
    NSMutableArray *keys = [@[] mutableCopy];
    
    unsigned int propertiesCount;
    objc_property_t* allProperties = class_copyPropertyList([self class], &propertiesCount);
    
    for (int i=0; i < propertiesCount; ++i) {
        const char *name = property_getName(allProperties[i]);
        NSString *key = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
        if (key && key.length > 0) {
            [keys addObject:key];
        }
    }
    
    return keys;
}

- (NSDictionary*)dictionaryOfPropertiesAndValues
{
    return [self dictionaryWithValuesForKeys:[self propertiesNames]];
}

#pragma mark - NSUserDefaults save & load
- (BOOL)save
{
    NSString *mainKey = NSStringFromClass([self class]);
    return [self saveUnderKey:mainKey];
}

- (BOOL)saveUnderKey:(NSString*)mainKey
{
    NSDictionary *serializedSelf = [self dictionaryOfPropertiesAndValues];
    [[NSUserDefaults standardUserDefaults] setObject:serializedSelf forKey:mainKey];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)load
{
    NSString *mainKey = NSStringFromClass([self class]);
    return [[self class] loadFromKey:mainKey];
}

+ (id)loadFromKey:(NSString*)mainKey
{
    NSDictionary *serializedSelf = [[NSUserDefaults standardUserDefaults] objectForKey:mainKey];
    return [[[self class] alloc] initWithDictionary:serializedSelf];
}

#pragma mark - KVO for nestes settings objects
- (id)valueForKey:(NSString *)key
{
    id value = [super valueForKey:key];
    if ([value isKindOfClass:[AppSettings class]]) {
        AppSettings *nestedAppSettings = value;
        return [nestedAppSettings dictionaryOfPropertiesAndValues];
    }
    
    return value;
}

@end





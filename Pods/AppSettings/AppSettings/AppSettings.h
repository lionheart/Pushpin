//
//  AppSettings.h
//  AppSettings
//
//  Created by Kamil Burczyk on 08.12.2013.
//  Copyright (c) 2013 Sigmapoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionaryOfPropertiesAndValues;

- (NSArray*)propertiesNames;
- (NSDictionary*)dictionaryOfPropertiesAndValues;

- (BOOL)save;
- (BOOL)saveUnderKey:(NSString*)mainKey;

+ (id)load;
+ (id)loadFromKey:(NSString*)mainKey;

@end

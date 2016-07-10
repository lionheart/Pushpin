//
//  NSData+AES256.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/2/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import Foundation;

@interface NSData (AES256)

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end

//
//  FMDatabase+LHSAdditions.m
//  LHSCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import "FMDatabase+LHSAdditions.h"

@implementation FMDatabase (LHSAdditions)

- (void)executeUpdateFromFileWithPath:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [handle readDataToEndOfFile];
    [handle closeFile];
    NSString *sql = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *statements = [sql componentsSeparatedByString:@";"];
    [self beginTransaction];
    for (NSString *statement in statements) {
        NSString *trimmedStatement = [statement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedStatement && ![trimmedStatement isEqualToString:@""]) {
            [self executeUpdate:trimmedStatement];
        }
    }
    [self commit];
}

@end


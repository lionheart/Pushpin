//
//  FMDatabase+LHSAdditions.h
//  LHSCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import "FMDatabase.h"

@interface FMDatabase (LHSAdditions)

- (void)lhs_executeUpdateFromFileWithPath:(NSString *)path;

@end


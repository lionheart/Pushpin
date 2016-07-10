//
//  NSURLSession+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 1/9/15.
//
//

#import <Foundation/Foundation.h>

@interface NSURLSession (LHSAdditions)

- (void)lhs_cancelAllTasksWithCompletion:(void (^)())completion;

@end

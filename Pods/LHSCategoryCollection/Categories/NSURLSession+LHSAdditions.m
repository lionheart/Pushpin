//
//  NSURLSession+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 1/9/15.
//
//

#import "NSURLSession+LHSAdditions.h"

@implementation NSURLSession (LHSAdditions)

- (void)lhs_cancelAllTasksWithCompletion:(void (^)())completion {
    [self getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [task cancel];
        }
        
        for (NSURLSessionUploadTask *task in uploadTasks) {
            [task cancel];
        }
        
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            [task cancel];
        }
        
        completion();
    }];
}

@end

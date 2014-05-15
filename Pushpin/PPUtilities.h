//
//  PPUtilities.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface PPUtilities : NSObject

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                           meta:(NSString *(^)(id))extractMeta
                     completion:(void (^)(NSSet *inserted, NSSet *updated, NSSet *deleted))completion;

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                     completion:(void (^)(NSSet *inserted, NSSet *deleted))completion;

#ifdef PINBOARD
+ (NSDictionary *)dictionaryFromResultSet:(FMResultSet *)resultSet;
#endif

@end
